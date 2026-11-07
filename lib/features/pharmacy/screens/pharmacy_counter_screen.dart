import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/hospital_settings.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/features/pharmacy/services/pharmacy_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_forms.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/pharmacy/models/counter_models.dart';
import 'package:hms_mobile/features/pharmacy/models/drug.dart';
import 'package:hms_mobile/features/pharmacy/models/pharmacy_patient.dart';

class PharmacyCounterViewModel extends ChangeNotifier {
  final PharmacyApiService api;
  final AuthStorage authStorage;

  PharmacyCounterViewModel({PharmacyApiService? api, AuthStorage? authStorage})
      : api = api ?? PharmacyApiService(),
        authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  CounterDay? day;

  /// null = both, 'otc' = sales, 'return' = returns.
  String? type;

  Future<String> _token() async => (await authStorage.readToken())!;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      await guardNetworkErrors(() async {
        day = await api.counterDay(await _token(), type: type);
      });
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void showType(String? value) {
    if (type == value) return;
    type = value;
    load();
  }

  Future<List<Drug>> drugs() async => guardNetworkErrors(() async => api.drugs(await _token()));

  Future<List<PharmacyPatient>> patients(String query) async =>
      guardNetworkErrors(() async => api.patients(await _token(), q: query));

  Future<List<CounterEntry>> returnable() async =>
      guardNetworkErrors(() async => api.returnable(await _token()));

  Future<(String?, String?)> sell({
    required int patientId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      final message = await guardNetworkErrors(
        () async => api.counterSell(await _token(), patientId: patientId, items: items, notes: notes),
      );
      await load();
      return (message, null);
    } on ApiException catch (e) {
      return (null, e.message);
    }
  }

  Future<(String?, String?)> giveBack(int dispensingId, List<Map<String, dynamic>> items, String? reason) async {
    try {
      final message = await guardNetworkErrors(
        () async => api.counterReturn(await _token(), dispensingId, items: items, reason: reason),
      );
      await load();
      return (message, null);
    } on ApiException catch (e) {
      return (null, e.message);
    }
  }
}

/// The pharmacy counter: a walk-in sale, and medicine brought back.
///
/// Dispensing has always meant "against a prescription". These two
/// things happen at the same counter and moved no stock in the system
/// at all.
class PharmacyCounterScreen extends StatelessWidget {
  const PharmacyCounterScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => PharmacyCounterViewModel(),
        child: const CareTheme(child: _CounterView()),
      );
}

class _CounterView extends StatelessWidget {
  const _CounterView();

  Future<void> _sell(BuildContext context, PharmacyCounterViewModel viewModel) async {
    // Who it is for: the table needs a patient, and an over-the-counter
    // antibiotic with nobody's name on it is not something a hospital
    // should be able to record.
    final patient = await showModalBottomSheet<PharmacyPatient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PatientSheet(search: viewModel.patients),
    );
    if (patient == null || !context.mounted) return;

    late final List<Drug> drugs;
    try {
      drugs = await viewModel.drugs();
    } on ApiException catch (e) {
      if (context.mounted) careSnack(context, e.message, isError: true);
      return;
    }
    if (!context.mounted) return;

    final basket = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BasketSheet(drugs: drugs, patientName: patient.name),
    );
    if (basket == null || basket.isEmpty || !context.mounted) return;

    final (message, error) = await viewModel.sell(patientId: patient.id, items: basket);
    if (context.mounted) careSnack(context, error ?? message!, isError: error != null);
  }

  Future<void> _takeBack(BuildContext context, PharmacyCounterViewModel viewModel) async {
    late final List<CounterEntry> entries;
    try {
      entries = await viewModel.returnable();
    } on ApiException catch (e) {
      if (context.mounted) careSnack(context, e.message, isError: true);
      return;
    }
    if (!context.mounted) return;

    if (entries.isEmpty) {
      careSnack(context, 'Nothing has been dispensed to return.', isError: true);
      return;
    }

    final chosen = await showModalBottomSheet<CounterEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickDispensingSheet(entries: entries),
    );
    if (chosen == null || !context.mounted) return;

    final lines = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReturnSheet(entry: chosen),
    );
    if (lines == null || lines.isEmpty || !context.mounted) return;

    final (message, error) = await viewModel.giveBack(chosen.id, lines, null);
    if (context.mounted) careSnack(context, error ?? message!, isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<PharmacyCounterViewModel>();
    final day = viewModel.day;

    return Scaffold(
      appBar: carePageAppBar(
        context,
        'Counter',
        actions: [
          IconButton(
            tooltip: 'Record a return',
            onPressed: () => _takeBack(context, viewModel),
            icon: const Icon(Icons.undo_rounded, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _sell(context, viewModel),
        backgroundColor: kCareDark,
        icon: const Icon(Icons.point_of_sale_rounded, color: Colors.white),
        label: const Text('New sale', style: CareText.onCareBold),
      ),
      body: Column(
        children: [
          if (day != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: CareCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Taken today', style: CareText.mutedXs),
                          Text(money((day.stats['takings_today'] ?? 0)), style: CareText.titleXxl),
                          Text('${day.stats['sales_today'] ?? 0} sales', style: CareText.mutedSm),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Refunded', style: CareText.mutedXs),
                        Text(money((day.stats['refunded_today'] ?? 0)), style: CareText.titleLg),
                        Text('${day.stats['returns_today'] ?? 0} returns', style: CareText.mutedSm),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: Row(
              children: [
                CareChoicePill(label: 'All', selected: viewModel.type == null, onTap: () => viewModel.showType(null)),
                const SizedBox(width: 8),
                CareChoicePill(
                    label: 'Sales', selected: viewModel.type == 'otc', onTap: () => viewModel.showType('otc')),
                const SizedBox(width: 8),
                CareChoicePill(
                    label: 'Returns', selected: viewModel.type == 'return', onTap: () => viewModel.showType('return')),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kCare,
              onRefresh: viewModel.load,
              child: _body(viewModel, day),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(PharmacyCounterViewModel viewModel, CounterDay? day) {
    if (viewModel.isLoading && day == null) return const CareStateView.loading();
    if (viewModel.loadError != null && day == null) return CareStateView.error(viewModel.loadError!);
    if (day == null) return const CareStateView.loading();

    if (day.entries.isEmpty) {
      return const CareStateView(
        icon: Icons.point_of_sale_outlined,
        title: 'Nothing over the counter yet',
        message: 'Walk-in sales and returns appear here.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 92),
      itemCount: day.entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final entry = day.entries[i];

        return CareCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: entry.isReturn ? kWarningBg : kSuccessBg,
                  borderRadius: BorderRadius.circular(CareRadius.control),
                ),
                child: Icon(
                  entry.isReturn ? Icons.undo_rounded : Icons.shopping_bag_outlined,
                  size: 19,
                  color: entry.isReturn ? kWarningFg : kSuccessFg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.patientName ?? 'Walk-in',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.titleMd),
                    Text([entry.dispensingNo, entry.date ?? ''].where((s) => s.isNotEmpty).join(' · '),
                        style: CareText.mutedSm),
                    if (entry.summary.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(entry.summary, style: CareText.mutedXs),
                    ],
                  ],
                ),
              ),
              Text(
                '${entry.isReturn ? '−' : ''}${money(entry.totalAmount)}',
                style: CareText.titleMd.copyWith(color: entry.isReturn ? kWarningFg : kInk),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Find the patient a sale is for.
class _PatientSheet extends StatefulWidget {
  final Future<List<PharmacyPatient>> Function(String query) search;
  const _PatientSheet({required this.search});

  @override
  State<_PatientSheet> createState() => _PatientSheetState();
}

class _PatientSheetState extends State<_PatientSheet> {
  List<PharmacyPatient> _results = [];
  bool _searching = false;

  Future<void> _run(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final found = await widget.search(query);
      if (mounted) setState(() => _results = found);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(CareRadius.sheet)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Who is it for?', style: CareText.titleXl),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                onChanged: _run,
                decoration: careFieldDecoration('Patient', hint: 'Name or MRN', icon: Icons.search_rounded),
              ),
              const SizedBox(height: 10),
              if (_searching) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: _results.isEmpty
                    ? const Center(child: Text('Search by MRN or full name.', style: CareText.mutedSm))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, i) {
                          final patient = _results[i];
                          return ListTile(
                            onTap: () => Navigator.of(context).pop(patient),
                            title: Text(patient.name, style: CareText.titleMd),
                            subtitle: Text(patient.mrn, style: CareText.mutedSm),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pick the medicines and how many of each.
class _BasketSheet extends StatefulWidget {
  final List<Drug> drugs;
  final String patientName;

  const _BasketSheet({required this.drugs, required this.patientName});

  @override
  State<_BasketSheet> createState() => _BasketSheetState();
}

class _BasketSheetState extends State<_BasketSheet> {
  final _quantities = <int, int>{};
  String _query = '';

  double get _total => widget.drugs
      .where((d) => (_quantities[d.id] ?? 0) > 0)
      .fold(0, (sum, d) => sum + d.unitPrice * (_quantities[d.id] ?? 0));

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final shown = widget.drugs
        .where((d) => _query.isEmpty || d.drugName.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(CareRadius.sheet)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        height: MediaQuery.of(context).size.height * 0.8,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sale for ${widget.patientName}', style: CareText.titleXl),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: careFieldDecoration('Search', hint: 'Medicine name', icon: Icons.search_rounded),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: shown.length,
                  itemBuilder: (context, i) {
                    final drug = shown[i];
                    final quantity = _quantities[drug.id] ?? 0;
                    // Stock is shown because selling what is not there
                    // is the mistake this screen can cause.
                    final short = quantity > drug.currentStock;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(drug.drugName, style: CareText.titleMd),
                                Text(
                                  '${money(drug.unitPrice, decimals: 2)} · ${drug.currentStock} in stock',
                                  style: short ? CareText.danger : CareText.mutedSm,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: quantity == 0
                                ? null
                                : () => setState(() => _quantities[drug.id] = quantity - 1),
                            icon: Icon(Icons.remove_circle_outline, color: quantity == 0 ? kCareHint : kCare),
                          ),
                          Text('$quantity', style: CareText.titleMd),
                          IconButton(
                            onPressed: () => setState(() => _quantities[drug.id] = quantity + 1),
                            icon: Icon(Icons.add_circle_outline, color: kCare),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              CarePrimaryButton(
                label: _total == 0 ? 'Add something' : 'Take ${money(_total, decimals: 2)}',
                onPressed: _total == 0
                    ? null
                    : () => Navigator.of(context).pop([
                          for (final entry in _quantities.entries)
                            if (entry.value > 0) {'drug_id': entry.key, 'quantity': entry.value},
                        ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Which dispensing is being returned against.
class _PickDispensingSheet extends StatelessWidget {
  final List<CounterEntry> entries;
  const _PickDispensingSheet({required this.entries});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(CareRadius.sheet)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      height: MediaQuery.of(context).size.height * 0.7,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Return against which?', style: CareText.titleXl),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final entry = entries[i];
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(entry),
                    title: Text(entry.patientName ?? 'Patient', style: CareText.titleMd),
                    subtitle: Text(
                      '${entry.dispensingNo} · ${entry.date ?? ''} · ${money(entry.totalAmount)}',
                      style: CareText.mutedSm,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How much of each line is coming back.
class _ReturnSheet extends StatefulWidget {
  final CounterEntry entry;
  const _ReturnSheet({required this.entry});

  @override
  State<_ReturnSheet> createState() => _ReturnSheetState();
}

class _ReturnSheetState extends State<_ReturnSheet> {
  final _quantities = <int, int>{};

  double get _refund => widget.entry.items
      .where((i) => (_quantities[i.itemId] ?? 0) > 0)
      .fold(0, (sum, i) => sum + i.unitPrice * (_quantities[i.itemId] ?? 0));

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(CareRadius.sheet)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('What is coming back?', style: CareText.titleXl),
            Text(widget.entry.dispensingNo, style: CareText.mutedSm),
            const SizedBox(height: 12),
            for (final item in widget.entry.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.medicineName, style: CareText.titleMd),
                          // The cap is what went out; more cannot come back.
                          Text('${item.quantity} given · ${money(item.unitPrice, decimals: 2)} each',
                              style: CareText.mutedSm),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: (_quantities[item.itemId] ?? 0) == 0
                          ? null
                          : () => setState(() => _quantities[item.itemId!] = (_quantities[item.itemId] ?? 0) - 1),
                      icon: Icon(Icons.remove_circle_outline,
                          color: (_quantities[item.itemId] ?? 0) == 0 ? kCareHint : kCare),
                    ),
                    Text('${_quantities[item.itemId] ?? 0}', style: CareText.titleMd),
                    IconButton(
                      onPressed: (_quantities[item.itemId] ?? 0) >= item.quantity
                          ? null
                          : () => setState(() => _quantities[item.itemId!] = (_quantities[item.itemId] ?? 0) + 1),
                      icon: Icon(Icons.add_circle_outline,
                          color: (_quantities[item.itemId] ?? 0) >= item.quantity ? kCareHint : kCare),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            CarePrimaryButton(
              label: _refund == 0 ? 'Nothing selected' : 'Refund ${money(_refund, decimals: 2)}',
              onPressed: _refund == 0
                  ? null
                  : () => Navigator.of(context).pop([
                        for (final entry in _quantities.entries)
                          if (entry.value > 0) {'item_id': entry.key, 'quantity': entry.value},
                      ]),
            ),
          ],
        ),
      ),
    );
  }
}

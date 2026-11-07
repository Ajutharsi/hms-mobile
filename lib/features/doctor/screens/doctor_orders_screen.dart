import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/hospital_settings.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/features/doctor/services/doctor_order_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_forms.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/doctor/models/doctor_order_models.dart';

class DoctorOrdersViewModel extends ChangeNotifier {
  final int patientId;
  final DoctorOrderApiService api;
  final AuthStorage authStorage;

  DoctorOrdersViewModel({
    required this.patientId,
    DoctorOrderApiService? api,
    AuthStorage? authStorage,
  })  : api = api ?? DoctorOrderApiService(),
        authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  DoctorOrderBoard? board;

  Future<String> _token() async => (await authStorage.readToken())!;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      await guardNetworkErrors(() async {
        board = await api.board(await _token(), patientId);
      });
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<OrderableTest>> tests() async =>
      guardNetworkErrors(() async => api.labTests(await _token()));

  /// Returns the server's message on success, or throws nothing: the
  /// error comes back as the second field.
  Future<(String? message, String? error)> place(
    Future<String> Function(DoctorOrderApiService api, String token) action,
  ) async {
    try {
      final message = await guardNetworkErrors(() async => action(api, await _token()));
      await load();
      return (message, null);
    } on ApiException catch (e) {
      return (null, e.message);
    }
  }
}

/// Lab, radiology, medicines and diet for one patient, in one place.
///
/// Each of these could already be created somewhere -- the lab's own
/// screen, the front desk, inside a consultation, the ward. What a
/// doctor could not do was decide on four things at the bedside and
/// enter them without walking through four parts of the app.
class DoctorOrdersScreen extends StatelessWidget {
  final int patientId;
  final String? patientName;

  const DoctorOrdersScreen({super.key, required this.patientId, this.patientName});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => DoctorOrdersViewModel(patientId: patientId),
        child: CareTheme(child: _OrdersView(fallbackName: patientName)),
      );
}

class _OrdersView extends StatelessWidget {
  final String? fallbackName;
  const _OrdersView({this.fallbackName});

  static const _kinds = <String, (IconData, String, Color Function())>{
    'lab': (Icons.science_rounded, 'Lab', _labColour),
    'radiology': (Icons.camera_rounded, 'Radiology', _radiologyColour),
    'medicine': (Icons.medication_rounded, 'Medicine', _medicineColour),
    'diet': (Icons.restaurant_rounded, 'Diet', _dietColour),
  };

  static Color _labColour() => kInfoFg;
  static Color _radiologyColour() => kCarePinkFg;
  static Color _medicineColour() => kCareDark;
  static Color _dietColour() => kSuccessFg;

  Future<void> _choose(BuildContext context, DoctorOrdersViewModel viewModel) async {
    final board = viewModel.board;

    final kind = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(CareRadius.sheet)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('What are you ordering?', style: CareText.titleXl),
              const SizedBox(height: 14),
              CareOptionTile(
                icon: Icons.science_rounded,
                title: 'Lab test',
                subtitle: 'Pick from the hospital catalogue',
                onTap: () => Navigator.of(context).pop('lab'),
              ),
              CareOptionTile(
                icon: Icons.camera_rounded,
                title: 'Radiology',
                subtitle: 'X-ray, scan or ultrasound',
                onTap: () => Navigator.of(context).pop('radiology'),
              ),
              CareOptionTile(
                icon: Icons.medication_rounded,
                title: 'Medicines',
                subtitle: board?.canPrescribe == true
                    ? 'Added to this patient\'s latest consultation'
                    : 'Needs a consultation first',
                onTap: () => Navigator.of(context).pop('medicine'),
              ),
              CareOptionTile(
                icon: Icons.restaurant_rounded,
                title: 'Diet',
                subtitle: 'What the ward should feed them',
                onTap: () => Navigator.of(context).pop('diet'),
              ),
            ],
          ),
        ),
      ),
    );
    if (kind == null || !context.mounted) return;

    switch (kind) {
      case 'lab':
        await _orderLab(context, viewModel);
      case 'radiology':
        await _orderRadiology(context, viewModel);
      case 'medicine':
        await _orderMedicine(context, viewModel);
      case 'diet':
        await _orderDiet(context, viewModel);
    }
  }

  Future<void> _orderLab(BuildContext context, DoctorOrdersViewModel viewModel) async {
    late final List<OrderableTest> tests;
    try {
      tests = await viewModel.tests();
    } on ApiException catch (e) {
      if (context.mounted) careSnack(context, e.message, isError: true);
      return;
    }
    if (!context.mounted) return;

    final picked = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TestPickerSheet(tests: tests),
    );
    if (picked == null || picked.isEmpty || !context.mounted) return;

    final (message, error) = await viewModel.place((api, token) => api.orderLab(token, viewModel.patientId, picked));
    if (context.mounted) careSnack(context, error ?? message!, isError: error != null);
  }

  Future<void> _orderRadiology(BuildContext context, DoctorOrdersViewModel viewModel) async {
    final values = await careFormSheet(
      context,
      title: 'Radiology order',
      submitLabel: 'Order',
      fields: const [
        CareFormField('modality', 'Modality',
            options: ['X-Ray', 'CT', 'MRI', 'Ultrasound', 'Mammography'], icon: Icons.camera_outlined),
        CareFormField('body_part', 'Body part', required: true, icon: Icons.accessibility_new_outlined),
        CareFormField('study_description', 'Study', required: true, icon: Icons.description_outlined),
        CareFormField('clinical_indication', 'Why', maxLines: 2, icon: Icons.help_outline_rounded),
        CareFormField('priority', 'Priority',
            options: ['routine', 'urgent', 'emergency'], icon: Icons.priority_high_rounded),
      ],
    );
    if (values == null || !context.mounted) return;

    final (message, error) =
        await viewModel.place((api, token) => api.orderRadiology(token, viewModel.patientId, values));
    if (context.mounted) careSnack(context, error ?? message!, isError: error != null);
  }

  Future<void> _orderMedicine(BuildContext context, DoctorOrdersViewModel viewModel) async {
    final values = await careFormSheet(
      context,
      title: 'Prescribe',
      submitLabel: 'Write',
      fields: const [
        CareFormField('medicine_name', 'Medicine', required: true, icon: Icons.medication_outlined),
        CareFormField('dosage', 'Dose', required: true, icon: Icons.straighten_outlined),
        CareFormField('frequency', 'Frequency', required: true, icon: Icons.repeat_rounded),
        CareFormField('duration', 'Duration', required: true, icon: Icons.timelapse_outlined),
        CareFormField('route', 'Route', options: ['oral', 'iv', 'im', 'topical', 'inhaled'], icon: Icons.route_outlined),
        CareFormField('instructions', 'Instructions', maxLines: 2, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final (message, error) = await viewModel.place(
      (api, token) => api.orderMedicines(token, viewModel.patientId, [values]),
    );
    if (context.mounted) careSnack(context, error ?? message!, isError: error != null);
  }

  Future<void> _orderDiet(BuildContext context, DoctorOrdersViewModel viewModel) async {
    final values = await careFormSheet(
      context,
      title: 'Diet order',
      submitLabel: 'Order',
      fields: const [
        CareFormField('diet_type', 'Diet',
            options: ['normal', 'diabetic', 'liquid', 'soft', 'low_salt', 'npo', 'other'],
            icon: Icons.restaurant_outlined),
        CareFormField('restrictions', 'Restrictions', maxLines: 2, icon: Icons.block_outlined),
        CareFormField('notes', 'Notes', maxLines: 2, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final (message, error) = await viewModel.place((api, token) => api.orderDiet(token, viewModel.patientId, values));
    if (context.mounted) careSnack(context, error ?? message!, isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<DoctorOrdersViewModel>();
    final board = viewModel.board;

    return Scaffold(
      appBar: carePageAppBar(context, 'Orders${board == null ? '' : ' — ${board.patientName}'}'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _choose(context, viewModel),
        backgroundColor: kCareDark,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New order', style: CareText.onCareBold),
      ),
      body: RefreshIndicator(
        color: kCare,
        onRefresh: viewModel.load,
        child: _body(context, viewModel, board),
      ),
    );
  }

  Widget _body(BuildContext context, DoctorOrdersViewModel viewModel, DoctorOrderBoard? board) {
    if (viewModel.isLoading && board == null) return const CareStateView.loading();
    if (viewModel.loadError != null && board == null) return CareStateView.error(viewModel.loadError!);
    if (board == null) return const CareStateView.loading();

    if (board.orders.isEmpty) {
      return const CareStateView(
        icon: Icons.assignment_outlined,
        title: 'Nothing ordered yet',
        message: 'Lab tests, scans, medicines and diet for this patient all start here.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 92),
      itemCount: board.orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final order = board.orders[i];
        final (icon, label, colour) = _kinds[order.kind] ?? (Icons.help_outline_rounded, order.kind, _medicineColour);

        return CareCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: kCareSoft, borderRadius: BorderRadius.circular(CareRadius.control)),
                child: Icon(icon, size: 20, color: colour()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(order.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.titleMd),
                        ),
                        CareChip(label: label, bg: kCareNeutralBg, fg: kMuted),
                      ],
                    ),
                    if ((order.detail ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(order.detail!, style: CareText.mutedSm),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      [order.date, order.status].where((s) => (s ?? '').isNotEmpty).join(' · '),
                      style: CareText.mutedXs,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Pick the tests to order, with a search box over the catalogue.
class _TestPickerSheet extends StatefulWidget {
  final List<OrderableTest> tests;
  const _TestPickerSheet({required this.tests});

  @override
  State<_TestPickerSheet> createState() => _TestPickerSheetState();
}

class _TestPickerSheetState extends State<_TestPickerSheet> {
  final _picked = <int>{};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final shown = widget.tests
        .where((t) => _query.isEmpty || t.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final total = widget.tests.where((t) => _picked.contains(t.id)).fold<double>(0, (sum, t) => sum + t.price);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(CareRadius.sheet)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        height: MediaQuery.of(context).size.height * 0.75,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Which tests?', style: CareText.titleXl),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: careFieldDecoration('Search', hint: 'Test name', icon: Icons.search_rounded),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: shown.length,
                  itemBuilder: (context, i) {
                    final test = shown[i];
                    final selected = _picked.contains(test.id);

                    return CheckboxListTile(
                      value: selected,
                      activeColor: kCare,
                      onChanged: (v) => setState(() => v == true ? _picked.add(test.id) : _picked.remove(test.id)),
                      title: Text(test.name, style: CareText.titleMd),
                      subtitle: Text(
                        [test.category, test.sampleType, money(test.price)]
                            .where((s) => (s ?? '').isNotEmpty)
                            .join(' · '),
                        style: CareText.mutedSm,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              CarePrimaryButton(
                label: _picked.isEmpty
                    ? 'Pick at least one'
                    : 'Order ${_picked.length} test${_picked.length == 1 ? '' : 's'} · ${money(total)}',
                onPressed: _picked.isEmpty ? null : () => Navigator.of(context).pop(_picked.toList()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/lab_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_forms.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/lab/models/lab_order.dart';

class LabSamplesViewModel extends ChangeNotifier {
  final LabApiService api;
  final AuthStorage authStorage;

  LabSamplesViewModel({LabApiService? api, AuthStorage? authStorage})
      : api = api ?? LabApiService(),
        authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<LabSample> orders = [];
  int waiting = 0;
  int collectedToday = 0;

  /// 'pending' or 'collected'.
  String state = 'pending';

  Future<String> _token() async => (await authStorage.readToken())!;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      await guardNetworkErrors(() async {
        final result = await api.samples(await _token(), state: state);
        orders = result.orders;
        waiting = result.waiting;
        collectedToday = result.collectedToday;
      });
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void showState(String value) {
    if (state == value) return;
    state = value;
    load();
  }

  Future<String?> collect(int orderId, Map<String, dynamic> body) async {
    try {
      await guardNetworkErrors(() async => api.collectSample(await _token(), orderId, body));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<Map<String, dynamic>?> findByBarcode(String barcode) async {
    try {
      return await guardNetworkErrors(() async => api.sampleByBarcode(await _token(), barcode));
    } on ApiException catch (e) {
      loadError = e.message;
      notifyListeners();
      return null;
    }
  }
}

/// Which tubes still have to be drawn, and what is on the ones that have.
///
/// An order used to go straight from "ordered" to a typed-in result, so
/// nothing told the person with the needle what was waiting, and a
/// mislabelled tube had nothing to trace it back with.
class LabSamplesScreen extends StatelessWidget {
  const LabSamplesScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => LabSamplesViewModel(),
        child: const CareTheme(child: _SamplesView()),
      );
}

class _SamplesView extends StatelessWidget {
  const _SamplesView();

  Future<void> _collect(BuildContext context, LabSamplesViewModel viewModel, LabSample sample) async {
    final values = await careFormSheet(
      context,
      title: 'Collect for ${sample.orderNo}',
      submitLabel: 'Mark collected',
      fields: const [
        CareFormField('sample_type', 'Sample type',
            options: ['Blood (EDTA)', 'Blood (plain)', 'Serum', 'Urine', 'Stool', 'Swab', 'Sputum', 'Other'],
            icon: Icons.science_outlined),
        // Left blank, the server labels the tube after the order.
        CareFormField('sample_barcode', 'Barcode (optional)', icon: Icons.qr_code_2_outlined),
        CareFormField('sample_notes', 'Notes', maxLines: 2, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.collect(sample.id, values);
    if (context.mounted) careSnack(context, error ?? 'Sample collected.', isError: error != null);
  }

  Future<void> _lookup(BuildContext context, LabSamplesViewModel viewModel) async {
    final controller = TextEditingController();

    final barcode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Find by barcode', style: CareText.titleLg),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: careFieldDecoration('Barcode', hint: 'S-2026-0001', icon: Icons.qr_code_2_outlined),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: CareText.mutedSmMedium)),
          TextButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Find')),
        ],
      ),
    );
    if (barcode == null || barcode.trim().isEmpty || !context.mounted) return;

    final found = await viewModel.findByBarcode(barcode.trim());
    if (!context.mounted) return;

    if (found == null) {
      careSnack(context, viewModel.loadError ?? 'No sample with that barcode.', isError: true);
      return;
    }

    final tests = (found['tests'] as List?)?.join(', ') ?? '';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(found['order_no']?.toString() ?? 'Sample', style: CareText.titleLg),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${found['patient_name'] ?? ''} · ${found['patient_mrn'] ?? ''}', style: CareText.bodyMd),
            const SizedBox(height: 6),
            Text('${found['sample_type'] ?? ''} · collected ${found['sample_collected_at'] ?? ''}',
                style: CareText.mutedSm),
            if (tests.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(tests, style: CareText.bodyMdMuted),
            ],
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<LabSamplesViewModel>();

    return Scaffold(
      appBar: carePageAppBar(
        context,
        'Sample collection',
        actions: [
          IconButton(
            tooltip: 'Find by barcode',
            onPressed: () => _lookup(context, viewModel),
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                CareChoicePill(
                  label: 'To collect (${viewModel.waiting})',
                  selected: viewModel.state == 'pending',
                  onTap: () => viewModel.showState('pending'),
                ),
                const SizedBox(width: 8),
                CareChoicePill(
                  label: 'Collected',
                  selected: viewModel.state == 'collected',
                  onTap: () => viewModel.showState('collected'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kCare,
              onRefresh: viewModel.load,
              child: _body(context, viewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, LabSamplesViewModel viewModel) {
    if (viewModel.isLoading && viewModel.orders.isEmpty) return const CareStateView.loading();
    if (viewModel.loadError != null && viewModel.orders.isEmpty) return CareStateView.error(viewModel.loadError!);
    if (viewModel.orders.isEmpty) {
      return CareStateView(
        icon: Icons.science_outlined,
        title: viewModel.state == 'pending' ? 'Nothing waiting' : 'Nothing collected yet',
        message: viewModel.state == 'pending'
            ? 'Every ordered test has had its sample taken.'
            : 'Samples you mark as collected appear here with their barcode.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: viewModel.orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final sample = viewModel.orders[i];

        return CareCard(
          onTap: sample.isCollected ? null : () => _collect(context, viewModel, sample),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sample.patientName ?? 'Patient',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.titleMd),
                        Text(
                          [sample.orderNo, sample.patientMrn, sample.orderDate]
                              .where((s) => (s ?? '').isNotEmpty)
                              .join(' · '),
                          style: CareText.mutedSm,
                        ),
                      ],
                    ),
                  ),
                  CareChip(
                    label: '${sample.testsCount} test${sample.testsCount == 1 ? '' : 's'}',
                    bg: kCareSoft,
                    fg: kCareDark,
                  ),
                ],
              ),
              if (sample.isCollected) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: kCareNeutralBg,
                    borderRadius: BorderRadius.circular(CareRadius.control),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_2_rounded, size: 20, color: kCare),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sample.barcode ?? '', style: CareText.titleSm),
                            Text(
                              [sample.sampleType, sample.collectedAt, sample.collectedBy]
                                  .where((s) => (s ?? '').isNotEmpty)
                                  .join(' · '),
                              style: CareText.mutedXs,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(Icons.pending_outlined, size: 17, color: kWarningFg),
                    SizedBox(width: 6),
                    Text('Tap to record the sample', style: CareText.mutedSm),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/lab/models/lab_order.dart';
import 'package:hms_mobile/features/lab/viewmodels/lab_orders_view_model.dart';

class LabOrderDetailScreen extends StatelessWidget {
  final int orderId;
  const LabOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => LabOrderDetailViewModel(orderId: orderId),
      child: const _LabOrderDetailView(),
    );
  }
}

class _LabOrderDetailView extends StatelessWidget {
  const _LabOrderDetailView();

  Future<void> _enterResults(BuildContext context, LabOrderDetailViewModel viewModel, List<LabOrderItem> pendingItems) async {
    final results = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (_) => _EnterResultsDialog(items: pendingItems),
    );
    if (results == null || !context.mounted) return;

    final error = await viewModel.saveResults(results);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'Results saved!')));
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<LabOrderDetailViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, viewModel.order?.orderNo ?? 'Lab Order'),
      body: _buildBody(context, viewModel),
    ));
  }

  Widget _buildBody(BuildContext context, LabOrderDetailViewModel viewModel) {
    if (viewModel.isLoading && viewModel.order == null) {
      return Center(child: CircularProgressIndicator(color: kCare));
    }
    if (viewModel.loadError != null && viewModel.order == null) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }

    final order = viewModel.order!;
    final pendingItems = order.items.where((i) => i.status == 'pending').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kCareBg, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.patientName ?? 'Patient', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
              Text(order.patientMrn ?? '', style: const TextStyle(fontSize: 12.5, color: kMuted)),
              const SizedBox(height: 8),
              Text('Ordered by ${order.doctorName ?? '—'} · ${order.orderDate ?? ''}', style: const TextStyle(fontSize: 12.5, color: kMuted)),
              if ((order.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(order.notes!, style: const TextStyle(fontSize: 12.5, color: kMuted)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Tests', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
        const SizedBox(height: 10),
        for (final item in order.items) ...[
          _ItemCard(item: item),
          const SizedBox(height: 10),
        ],
        if (pendingItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: viewModel.isSaving ? null : () => _enterResults(context, viewModel, pendingItems),
              style: ElevatedButton.styleFrom(backgroundColor: kCareDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: viewModel.isSaving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.science_outlined, color: Colors.white, size: 18),
              label: Text(viewModel.isSaving ? 'Saving...' : 'Enter results (${pendingItems.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  final LabOrderItem item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final completed = item.status == 'completed';
    final result = item.result;
    final flagColor = switch (result?.flag) {
      'high' => kDangerFg,
      'low' => kWarningFg,
      _ => kSuccessFg,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kCareBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.testName ?? 'Test', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: completed ? kSuccessBg : kWarningBg, borderRadius: BorderRadius.circular(7)),
                child: Text(item.status, style: TextStyle(color: completed ? kSuccessFg : kWarningFg, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${result.resultValue} ${result.unit ?? ''}', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: flagColor)),
                if (result.flag != null && result.flag != 'normal') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: flagColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(result.flag!.toUpperCase(), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: flagColor)),
                  ),
                ],
              ],
            ),
            if ((result.normalRange ?? '').isNotEmpty) Text('Normal: ${result.normalRange}', style: const TextStyle(fontSize: 11.5, color: kMuted)),
            if ((result.remarks ?? '').isNotEmpty) Text(result.remarks!, style: const TextStyle(fontSize: 11.5, color: kMuted)),
          ],
        ],
      ),
    );
  }
}

class _EnterResultsDialog extends StatefulWidget {
  final List<LabOrderItem> items;
  const _EnterResultsDialog({required this.items});

  @override
  State<_EnterResultsDialog> createState() => _EnterResultsDialogState();
}

class _EnterResultsDialogState extends State<_EnterResultsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<int, TextEditingController> _valueControllers = {for (final i in widget.items) i.id: TextEditingController()};
  late final Map<int, TextEditingController> _remarksControllers = {for (final i in widget.items) i.id: TextEditingController()};

  @override
  void dispose() {
    for (final c in _valueControllers.values) {
      c.dispose();
    }
    for (final c in _remarksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return AlertDialog(
      title: const Text('Enter results'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in widget.items) ...[
                  Text(item.testName ?? 'Test', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _valueControllers[item.id],
                    decoration: InputDecoration(labelText: 'Result value', suffixText: item.unit),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 6),
                  TextFormField(controller: _remarksControllers[item.id], decoration: const InputDecoration(labelText: 'Remarks (optional)')),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop([
              for (final item in widget.items)
                {
                  'item_id': item.id,
                  'result_value': _valueControllers[item.id]!.text.trim(),
                  'unit': item.unit,
                  'remarks': _remarksControllers[item.id]!.text.trim().isEmpty ? null : _remarksControllers[item.id]!.text.trim(),
                },
            ]);
          },
          child: const Text('Save results'),
        ),
      ],
    );
  }
}

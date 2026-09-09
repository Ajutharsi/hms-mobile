import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/receptionist/viewmodels/radiology_view_model.dart';

class RadiologyDetailScreen extends StatelessWidget {
  final int orderId;
  const RadiologyDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RadiologyDetailViewModel(orderId: orderId),
      child: const _RadiologyDetailView(),
    );
  }
}

class _RadiologyDetailView extends StatelessWidget {
  const _RadiologyDetailView();

  Future<void> _enterFindings(BuildContext context, RadiologyDetailViewModel viewModel) async {
    final result = await showDialog<Map<String, String>>(context: context, builder: (_) => const _FindingsDialog());
    if (result == null || !context.mounted) return;

    final error = await viewModel.enterFindings(
      findings: result['findings'],
      impression: result['impression'],
      radiologistName: result['radiologist_name'],
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Findings saved!')));
  }

  Future<void> _delete(BuildContext context, RadiologyDetailViewModel viewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Color(0xFFB3261E)))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await viewModel.destroy();
    if (!context.mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RadiologyDetailViewModel>();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        foregroundColor: kInk,
        elevation: 0,
        title: Text(viewModel.order?.orderNo ?? 'Radiology Order'),
        actions: [
          IconButton(onPressed: () => _delete(context, viewModel), icon: const Icon(Icons.delete_outline, color: kMuted)),
        ],
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, RadiologyDetailViewModel viewModel) {
    if (viewModel.isLoading && viewModel.order == null) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
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
    final completed = order.status == 'completed';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.patientName ?? 'Patient', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
              Text(order.patientMrn ?? '', style: const TextStyle(fontSize: 12.5, color: kMuted)),
              const SizedBox(height: 10),
              _row('Modality', order.modality),
              _row('Body part', order.bodyPart),
              _row('Study', order.studyDescription),
              if ((order.clinicalIndication ?? '').isNotEmpty) _row('Indication', order.clinicalIndication!),
              _row('Priority', order.priority),
              _row('Status', order.status),
              if (order.doctorName != null) _row('Referring doctor', order.doctorName!),
              if (order.orderDate != null) _row('Order date', order.orderDate!),
              if (order.scheduledAt != null) _row('Scheduled', order.scheduledAt!),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (completed) ...[
          const Text('Findings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kFieldFill)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((order.findings ?? '').isNotEmpty) ...[
                  const Text('Findings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
                  const SizedBox(height: 4),
                  Text(order.findings!, style: const TextStyle(fontSize: 13.5, color: kInk)),
                  const SizedBox(height: 10),
                ],
                if ((order.impression ?? '').isNotEmpty) ...[
                  const Text('Impression', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
                  const SizedBox(height: 4),
                  Text(order.impression!, style: const TextStyle(fontSize: 13.5, color: kInk)),
                  const SizedBox(height: 10),
                ],
                if ((order.radiologistName ?? '').isNotEmpty) Text('Radiologist: ${order.radiologistName}', style: const TextStyle(fontSize: 12, color: kMuted)),
                if (order.completedAt != null) Text('Completed: ${order.completedAt}', style: const TextStyle(fontSize: 12, color: kMuted)),
              ],
            ),
          ),
        ] else
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => _enterFindings(context, viewModel),
              style: ElevatedButton.styleFrom(backgroundColor: kTealDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.edit_note, color: Colors.white),
              label: const Text('Enter findings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12.5, color: kMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: kInk, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _FindingsDialog extends StatefulWidget {
  const _FindingsDialog();

  @override
  State<_FindingsDialog> createState() => _FindingsDialogState();
}

class _FindingsDialogState extends State<_FindingsDialog> {
  final _findingsController = TextEditingController();
  final _impressionController = TextEditingController();
  final _radiologistController = TextEditingController();

  @override
  void dispose() {
    _findingsController.dispose();
    _impressionController.dispose();
    _radiologistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter findings'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _findingsController, decoration: const InputDecoration(labelText: 'Findings'), maxLines: 4),
              const SizedBox(height: 10),
              TextField(controller: _impressionController, decoration: const InputDecoration(labelText: 'Impression'), maxLines: 3),
              const SizedBox(height: 10),
              TextField(controller: _radiologistController, decoration: const InputDecoration(labelText: 'Radiologist name')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(context).pop({
            'findings': _findingsController.text.trim(),
            'impression': _impressionController.text.trim(),
            'radiologist_name': _radiologistController.text.trim(),
          }),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/receptionist/models/scheme_billing.dart';
import 'package:hms_mobile/features/receptionist/screens/insurance_claims_screen.dart' show titleCase;
import 'package:hms_mobile/features/receptionist/screens/scheme_billing_screen.dart' show kSchemes, kSchemeStatuses, schemeStatusColors;
import 'package:hms_mobile/features/receptionist/viewmodels/scheme_billing_view_model.dart';

class SchemeBillingDetailScreen extends StatelessWidget {
  final int billId;
  const SchemeBillingDetailScreen({super.key, required this.billId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SchemeBillingDetailViewModel(billId: billId),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  Future<void> _edit(BuildContext context, SchemeBillingDetailViewModel viewModel, SchemeBilling bill) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _EditDialog(bill: bill));
    if (result == null || !context.mounted) return;
    final error = await viewModel.update(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Scheme bill updated!')));
  }

  Future<void> _updateStatus(BuildContext context, SchemeBillingDetailViewModel viewModel, SchemeBilling bill) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _StatusDialog(bill: bill));
    if (result == null || !context.mounted) return;
    final error = await viewModel.updateStatus(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Status updated!')));
  }

  Future<void> _delete(BuildContext context, SchemeBillingDetailViewModel viewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this scheme bill?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Color(0xFFB3261E)))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await viewModel.destroy();
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SchemeBillingDetailViewModel>();
    final bill = viewModel.bill;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kInk,
        elevation: 0,
        title: Text(bill?.schemeBillNo ?? 'Scheme Bill'),
        actions: bill == null
            ? null
            : [
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(context, viewModel, bill)),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context, viewModel)),
              ],
      ),
      floatingActionButton: bill == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _updateStatus(context, viewModel, bill),
              backgroundColor: kTealDark,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.flag_outlined, color: Colors.white),
              label: const Text('Update status', style: TextStyle(color: Colors.white)),
            ),
      body: _buildBody(viewModel),
    );
  }

  Widget _buildBody(SchemeBillingDetailViewModel viewModel) {
    if (viewModel.isLoading && viewModel.bill == null) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }
    if (viewModel.loadError != null && viewModel.bill == null) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }

    final bill = viewModel.bill!;
    final (fg, bg) = schemeStatusColors(bill.status);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            Expanded(child: Text(bill.patientName ?? 'Patient', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kInk))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Text(titleCase(bill.status), style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        Text(bill.patientMrn ?? '', style: const TextStyle(fontSize: 12.5, color: kMuted)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              _row('Scheme', bill.scheme.toUpperCase()),
              _row('Scheme name', bill.schemeName ?? '—'),
              _row('Beneficiary ID', bill.beneficiaryId ?? '—'),
              _row('Package code', bill.packageCode ?? '—'),
              _row('Package name', bill.packageName ?? '—'),
              _row('Package rate', '₹${bill.packageRate.toStringAsFixed(2)}'),
              _row('Actual bill', '₹${bill.actualBill.toStringAsFixed(2)}'),
              if (bill.schemePayment != null) _row('Scheme payment', '₹${bill.schemePayment!.toStringAsFixed(2)}'),
              if (bill.patientLiability != null) _row('Patient liability', '₹${bill.patientLiability!.toStringAsFixed(2)}'),
              _row('Submission date', bill.submissionDate ?? '—'),
              _row('Settlement date', bill.settlementDate ?? '—', showDivider: false),
            ],
          ),
        ),
        if ((bill.rejectionReason ?? '').isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kDangerBg, borderRadius: BorderRadius.circular(10)),
            child: Text('Rejection reason: ${bill.rejectionReason}', style: const TextStyle(fontSize: 12.5, color: kDangerFg)),
          ),
        ],
      ],
    );
  }

  Widget _row(String label, String value, {bool showDivider = true}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: kMuted))),
            Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk))),
          ],
        ),
        if (showDivider) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.white)),
      ],
    );
  }
}

class _EditDialog extends StatefulWidget {
  final SchemeBilling bill;
  const _EditDialog({required this.bill});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late String _scheme = widget.bill.scheme;
  late final _schemeNameController = TextEditingController(text: widget.bill.schemeName);
  late final _beneficiaryController = TextEditingController(text: widget.bill.beneficiaryId);
  late final _packageCodeController = TextEditingController(text: widget.bill.packageCode);
  late final _packageNameController = TextEditingController(text: widget.bill.packageName);
  late final _packageRateController = TextEditingController(text: widget.bill.packageRate.toString());
  late final _actualBillController = TextEditingController(text: widget.bill.actualBill.toString());

  @override
  void dispose() {
    _schemeNameController.dispose();
    _beneficiaryController.dispose();
    _packageCodeController.dispose();
    _packageNameController.dispose();
    _packageRateController.dispose();
    _actualBillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit scheme bill'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _scheme,
                decoration: const InputDecoration(labelText: 'Scheme'),
                items: kSchemes.map((s) => DropdownMenuItem(value: s, child: Text(titleCase(s)))).toList(),
                onChanged: (v) => setState(() => _scheme = v ?? _scheme),
              ),
              const SizedBox(height: 10),
              TextField(controller: _schemeNameController, decoration: const InputDecoration(labelText: 'Scheme name')),
              const SizedBox(height: 10),
              TextField(controller: _beneficiaryController, decoration: const InputDecoration(labelText: 'Beneficiary ID')),
              const SizedBox(height: 10),
              TextField(controller: _packageCodeController, decoration: const InputDecoration(labelText: 'Package code')),
              const SizedBox(height: 10),
              TextField(controller: _packageNameController, decoration: const InputDecoration(labelText: 'Package name')),
              const SizedBox(height: 10),
              TextField(controller: _packageRateController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Package rate')),
              const SizedBox(height: 10),
              TextField(controller: _actualBillController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Actual bill')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(context).pop({
            'scheme': _scheme,
            'scheme_name': _schemeNameController.text.trim().isEmpty ? null : _schemeNameController.text.trim(),
            'beneficiary_id': _beneficiaryController.text.trim().isEmpty ? null : _beneficiaryController.text.trim(),
            'package_code': _packageCodeController.text.trim().isEmpty ? null : _packageCodeController.text.trim(),
            'package_name': _packageNameController.text.trim().isEmpty ? null : _packageNameController.text.trim(),
            'package_rate': double.tryParse(_packageRateController.text) ?? widget.bill.packageRate,
            'actual_bill': double.tryParse(_actualBillController.text) ?? widget.bill.actualBill,
          }),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _StatusDialog extends StatefulWidget {
  final SchemeBilling bill;
  const _StatusDialog({required this.bill});

  @override
  State<_StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<_StatusDialog> {
  late String _status = widget.bill.status;
  final _paymentController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _paymentController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update status'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: kSchemeStatuses.map((s) => DropdownMenuItem(value: s, child: Text(titleCase(s)))).toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _paymentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Scheme payment', helperText: 'Recomputes patient liability if set'),
            ),
            const SizedBox(height: 10),
            TextField(controller: _reasonController, decoration: const InputDecoration(labelText: 'Rejection reason (optional)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(context).pop({
            'status': _status,
            if (_paymentController.text.trim().isNotEmpty) 'scheme_payment': double.tryParse(_paymentController.text),
            if (_reasonController.text.trim().isNotEmpty) 'rejection_reason': _reasonController.text.trim(),
          }),
          child: const Text('Update'),
        ),
      ],
    );
  }
}

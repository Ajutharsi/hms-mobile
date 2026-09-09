import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/receptionist/models/insurance_claim.dart';
import 'package:hms_mobile/features/receptionist/screens/insurance_claims_screen.dart';
import 'package:hms_mobile/features/receptionist/viewmodels/insurance_claims_view_model.dart';

const _kClaimStatuses = [
  'draft', 'submitted', 'pre_auth_pending', 'pre_auth_approved', 'pre_auth_rejected',
  'claim_submitted', 'approved', 'partially_approved', 'rejected', 'settled',
];

class InsuranceClaimDetailScreen extends StatelessWidget {
  final int claimId;
  const InsuranceClaimDetailScreen({super.key, required this.claimId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InsuranceClaimDetailViewModel(claimId: claimId),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  Future<void> _edit(BuildContext context, InsuranceClaimDetailViewModel viewModel, InsuranceClaim claim) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _EditDialog(claim: claim));
    if (result == null || !context.mounted) return;
    final error = await viewModel.update(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Claim updated!')));
  }

  Future<void> _updateStatus(BuildContext context, InsuranceClaimDetailViewModel viewModel, InsuranceClaim claim) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _StatusDialog(claim: claim));
    if (result == null || !context.mounted) return;
    final error = await viewModel.updateStatus(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Status updated!')));
  }

  Future<void> _delete(BuildContext context, InsuranceClaimDetailViewModel viewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this claim?'),
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
    final viewModel = context.watch<InsuranceClaimDetailViewModel>();
    final claim = viewModel.claim;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        foregroundColor: kInk,
        elevation: 0,
        title: Text(claim?.claimNo ?? 'Insurance Claim'),
        actions: claim == null
            ? null
            : [
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(context, viewModel, claim)),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context, viewModel)),
              ],
      ),
      floatingActionButton: claim == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _updateStatus(context, viewModel, claim),
              backgroundColor: kTealDark,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.flag_outlined, color: Colors.white),
              label: const Text('Update status', style: TextStyle(color: Colors.white)),
            ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, InsuranceClaimDetailViewModel viewModel) {
    if (viewModel.isLoading && viewModel.claim == null) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }
    if (viewModel.loadError != null && viewModel.claim == null) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }

    final claim = viewModel.claim!;
    final (fg, bg) = claimStatusColors(claim.status);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            Expanded(child: Text(claim.patientName ?? 'Patient', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kInk))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Text(titleCase(claim.status), style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        Text(claim.patientMrn ?? '', style: const TextStyle(fontSize: 12.5, color: kMuted)),
        const SizedBox(height: 16),
        _InfoCard(rows: [
          ('Insurance company', claim.insuranceCompany),
          ('TPA name', claim.tpaName ?? '—'),
          ('Policy number', claim.policyNumber),
          ('Member ID', claim.memberId ?? '—'),
          ('Claim type', titleCase(claim.claimType)),
          ('Claim amount', '₹${claim.claimAmount.toStringAsFixed(2)}'),
          if (claim.approvedAmount != null) ('Approved amount', '₹${claim.approvedAmount!.toStringAsFixed(2)}'),
          if (claim.patientLiability != null) ('Patient liability', '₹${claim.patientLiability!.toStringAsFixed(2)}'),
          ('Admission date', claim.admissionDate ?? '—'),
          ('Discharge date', claim.dischargeDate ?? '—'),
          ('ICD-10 code', claim.icd10Code ?? '—'),
        ]),
        if ((claim.diagnosis ?? '').isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Diagnosis', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 4),
          Text(claim.diagnosis!, style: const TextStyle(fontSize: 13, color: kMuted)),
        ],
        if ((claim.treatmentDetails ?? '').isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Treatment details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 4),
          Text(claim.treatmentDetails!, style: const TextStyle(fontSize: 13, color: kMuted)),
        ],
        if ((claim.rejectionReason ?? '').isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kDangerBg, borderRadius: BorderRadius.circular(10)),
            child: Text('Rejection reason: ${claim.rejectionReason}', style: const TextStyle(fontSize: 12.5, color: kDangerFg)),
          ),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<(String, String)> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Row(
              children: [
                Expanded(child: Text(rows[i].$1, style: const TextStyle(fontSize: 12.5, color: kMuted))),
                Flexible(child: Text(rows[i].$2, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk))),
              ],
            ),
            if (i != rows.length - 1) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.white)),
          ],
        ],
      ),
    );
  }
}

class _EditDialog extends StatefulWidget {
  final InsuranceClaim claim;
  const _EditDialog({required this.claim});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final _companyController = TextEditingController(text: widget.claim.insuranceCompany);
  late final _tpaController = TextEditingController(text: widget.claim.tpaName);
  late final _policyController = TextEditingController(text: widget.claim.policyNumber);
  late final _memberController = TextEditingController(text: widget.claim.memberId);
  late final _amountController = TextEditingController(text: widget.claim.claimAmount.toString());
  late final _diagnosisController = TextEditingController(text: widget.claim.diagnosis);
  late final _treatmentController = TextEditingController(text: widget.claim.treatmentDetails);
  late String _claimType = widget.claim.claimType;

  @override
  void dispose() {
    _companyController.dispose();
    _tpaController.dispose();
    _policyController.dispose();
    _memberController.dispose();
    _amountController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit claim'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _companyController, decoration: const InputDecoration(labelText: 'Insurance company')),
              const SizedBox(height: 10),
              TextField(controller: _tpaController, decoration: const InputDecoration(labelText: 'TPA name')),
              const SizedBox(height: 10),
              TextField(controller: _policyController, decoration: const InputDecoration(labelText: 'Policy number')),
              const SizedBox(height: 10),
              TextField(controller: _memberController, decoration: const InputDecoration(labelText: 'Member ID')),
              const SizedBox(height: 10),
              TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Claim amount')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _claimType,
                decoration: const InputDecoration(labelText: 'Claim type'),
                items: const [DropdownMenuItem(value: 'cashless', child: Text('Cashless')), DropdownMenuItem(value: 'reimbursement', child: Text('Reimbursement'))],
                onChanged: (v) => setState(() => _claimType = v ?? _claimType),
              ),
              const SizedBox(height: 10),
              TextField(controller: _diagnosisController, maxLines: 2, decoration: const InputDecoration(labelText: 'Diagnosis')),
              const SizedBox(height: 10),
              TextField(controller: _treatmentController, maxLines: 2, decoration: const InputDecoration(labelText: 'Treatment details')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(context).pop({
            'insurance_company': _companyController.text.trim(),
            'tpa_name': _tpaController.text.trim().isEmpty ? null : _tpaController.text.trim(),
            'policy_number': _policyController.text.trim(),
            'member_id': _memberController.text.trim().isEmpty ? null : _memberController.text.trim(),
            'claim_amount': double.tryParse(_amountController.text) ?? widget.claim.claimAmount,
            'claim_type': _claimType,
            'admission_date': widget.claim.admissionDate,
            'discharge_date': widget.claim.dischargeDate,
            'diagnosis': _diagnosisController.text.trim().isEmpty ? null : _diagnosisController.text.trim(),
            'treatment_details': _treatmentController.text.trim().isEmpty ? null : _treatmentController.text.trim(),
          }),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _StatusDialog extends StatefulWidget {
  final InsuranceClaim claim;
  const _StatusDialog({required this.claim});

  @override
  State<_StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<_StatusDialog> {
  late String _status = widget.claim.status;
  final _approvedController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _approvedController.dispose();
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
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _kClaimStatuses.map((s) => DropdownMenuItem(value: s, child: Text(titleCase(s)))).toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _approvedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Approved amount', helperText: 'Recomputes patient liability if set'),
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
            if (_approvedController.text.trim().isNotEmpty) 'approved_amount': double.tryParse(_approvedController.text),
            if (_reasonController.text.trim().isNotEmpty) 'rejection_reason': _reasonController.text.trim(),
          }),
          child: const Text('Update'),
        ),
      ],
    );
  }
}

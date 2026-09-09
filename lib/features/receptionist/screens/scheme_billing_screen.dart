import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/receptionist/models/reception_patient.dart';
import 'package:hms_mobile/features/receptionist/models/scheme_billing.dart';
import 'package:hms_mobile/features/receptionist/screens/insurance_claims_screen.dart' show ReceptionPatientPickerField, titleCase;
import 'package:hms_mobile/features/receptionist/screens/scheme_billing_detail_screen.dart';
import 'package:hms_mobile/features/receptionist/viewmodels/scheme_billing_view_model.dart';

const kSchemes = ['pmjay', 'ayushman', 'cghs', 'esi', 'state_scheme', 'other'];
const kSchemeStatuses = ['draft', 'submitted', 'approved', 'rejected', 'settled'];

(Color, Color) schemeStatusColors(String status) {
  if (status == 'approved' || status == 'settled') return (kSuccessFg, kSuccessBg);
  if (status == 'rejected') return (kDangerFg, kDangerBg);
  if (status == 'draft') return (kMuted, kFieldFill);
  return (kInfoFg, kInfoBg);
}

class SchemeBillingScreen extends StatelessWidget {
  const SchemeBillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SchemeBillingViewModel(),
      child: const _SchemeBillingView(),
    );
  }
}

class _SchemeBillingView extends StatelessWidget {
  const _SchemeBillingView();

  Future<void> _newBill(BuildContext context, SchemeBillingViewModel viewModel) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const _SchemeBillFormScreen()));
    if (saved == true) viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SchemeBillingViewModel>();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, foregroundColor: kInk, elevation: 0, title: const Text('Scheme Billing', style: TextStyle(fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newBill(context, viewModel),
        backgroundColor: kTealDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New scheme bill', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(color: kTeal, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    );
  }

  Widget _buildBody(BuildContext context, SchemeBillingViewModel viewModel) {
    if (viewModel.isLoading && viewModel.bills.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }
    if (viewModel.loadError != null && viewModel.bills.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }

    final stats = viewModel.stats;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        if (stats != null)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _StatTile(label: 'Total Claims', value: '${stats.total}', color: kTealDark, bg: kMint),
              _StatTile(label: 'Pending', value: '${stats.pending}', color: kWarningFg, bg: kWarningBg),
              _StatTile(label: 'Approved Amt', value: '₹${stats.approvedAmount.toStringAsFixed(0)}', color: kSuccessFg, bg: kSuccessBg),
              _StatTile(label: 'Settled', value: '${stats.settled}', color: kInfoFg, bg: kInfoBg),
            ],
          ),
        const SizedBox(height: 20),
        if (viewModel.bills.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('No scheme bills yet', style: TextStyle(color: kMuted))))
        else
          for (final bill in viewModel.bills) ...[
            _BillCard(
              bill: bill,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SchemeBillingDetailScreen(billId: bill.id)));
                viewModel.load();
              },
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  const _StatTile({required this.label, required this.value, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final SchemeBilling bill;
  final VoidCallback onTap;
  const _BillCard({required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = schemeStatusColors(bill.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kFieldFill)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(bill.patientName ?? 'Patient', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                  child: Text(titleCase(bill.status), style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            Text(bill.patientMrn ?? '', style: const TextStyle(fontSize: 12, color: kMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(7)),
                  child: Text(bill.scheme.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kInk)),
                ),
                const Spacer(),
                Text('₹${bill.packageRate.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTealDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SchemeBillFormScreen extends StatefulWidget {
  const _SchemeBillFormScreen();

  @override
  State<_SchemeBillFormScreen> createState() => _SchemeBillFormScreenState();
}

class _SchemeBillFormScreenState extends State<_SchemeBillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  ReceptionPatient? _patient;
  String? _patientError;
  String _scheme = kSchemes.first;
  final _schemeNameController = TextEditingController();
  final _beneficiaryController = TextEditingController();
  final _packageCodeController = TextEditingController();
  final _packageNameController = TextEditingController();
  final _packageRateController = TextEditingController();
  final _actualBillController = TextEditingController();
  final _icdController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _schemeNameController.dispose();
    _beneficiaryController.dispose();
    _packageCodeController.dispose();
    _packageNameController.dispose();
    _packageRateController.dispose();
    _actualBillController.dispose();
    _icdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_patient == null) {
      setState(() => _patientError = 'Pick a patient');
      return;
    }

    setState(() => _submitting = true);
    final viewModel = context.read<SchemeBillingViewModel>();
    final error = await viewModel.store({
      'patient_id': _patient!.id,
      'scheme': _scheme,
      'scheme_name': _schemeNameController.text.trim().isEmpty ? null : _schemeNameController.text.trim(),
      'beneficiary_id': _beneficiaryController.text.trim().isEmpty ? null : _beneficiaryController.text.trim(),
      'package_code': _packageCodeController.text.trim().isEmpty ? null : _packageCodeController.text.trim(),
      'package_name': _packageNameController.text.trim().isEmpty ? null : _packageNameController.text.trim(),
      'package_rate': double.tryParse(_packageRateController.text) ?? 0,
      'actual_bill': _actualBillController.text.trim().isEmpty ? null : double.tryParse(_actualBillController.text),
      'icd10_code': _icdController.text.trim().isEmpty ? null : _icdController.text.trim(),
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, foregroundColor: kInk, elevation: 0, title: const Text('New Scheme Bill')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            ReceptionPatientPickerField(value: _patient, errorText: _patientError, onChanged: (p) => setState(() { _patient = p; _patientError = null; })),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _scheme,
              decoration: authFieldDecoration('Scheme', hint: '', icon: Icons.request_quote_outlined),
              items: kSchemes.map((s) => DropdownMenuItem(value: s, child: Text(titleCase(s)))).toList(),
              onChanged: (v) => setState(() => _scheme = v ?? _scheme),
            ),
            const SizedBox(height: 14),
            TextFormField(controller: _schemeNameController, decoration: authFieldDecoration('Scheme name', hint: 'Optional', icon: Icons.badge_outlined)),
            const SizedBox(height: 14),
            TextFormField(controller: _beneficiaryController, decoration: authFieldDecoration('Beneficiary ID', hint: 'Optional', icon: Icons.person_outline)),
            const SizedBox(height: 14),
            TextFormField(controller: _packageCodeController, decoration: authFieldDecoration('Package code', hint: 'Optional', icon: Icons.qr_code_outlined)),
            const SizedBox(height: 14),
            TextFormField(controller: _packageNameController, decoration: authFieldDecoration('Package name', hint: 'Optional', icon: Icons.inventory_2_outlined)),
            const SizedBox(height: 14),
            TextFormField(
              controller: _packageRateController,
              keyboardType: TextInputType.number,
              decoration: authFieldDecoration('Package rate', hint: 'Required', icon: Icons.currency_rupee),
              validator: (v) => (double.tryParse(v ?? '') == null) ? 'Enter a valid rate' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(controller: _actualBillController, keyboardType: TextInputType.number, decoration: authFieldDecoration('Actual bill', hint: 'Optional', icon: Icons.receipt_outlined)),
            const SizedBox(height: 14),
            TextFormField(controller: _icdController, decoration: authFieldDecoration('ICD-10 code', hint: 'Optional', icon: Icons.tag_outlined)),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: kTealDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

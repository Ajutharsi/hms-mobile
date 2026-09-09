import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/receptionist_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/receptionist/models/insurance_claim.dart';
import 'package:hms_mobile/features/receptionist/models/reception_patient.dart';
import 'package:hms_mobile/features/receptionist/screens/insurance_claim_detail_screen.dart';
import 'package:hms_mobile/features/receptionist/viewmodels/insurance_claims_view_model.dart';

String titleCase(String s) => s.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

(Color, Color) claimStatusColors(String status) {
  if (status == 'approved' || status == 'partially_approved' || status == 'settled') return (kSuccessFg, kSuccessBg);
  if (status == 'rejected' || status == 'pre_auth_rejected') return (kDangerFg, kDangerBg);
  if (status == 'draft') return (kMuted, kFieldFill);
  return (kInfoFg, kInfoBg);
}

class InsuranceClaimsScreen extends StatelessWidget {
  const InsuranceClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InsuranceClaimsViewModel(),
      child: const _InsuranceClaimsView(),
    );
  }
}

class _InsuranceClaimsView extends StatelessWidget {
  const _InsuranceClaimsView();

  Future<void> _newClaim(BuildContext context, InsuranceClaimsViewModel viewModel) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const _ClaimFormScreen()));
    if (saved == true) viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InsuranceClaimsViewModel>();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, foregroundColor: kInk, elevation: 0, title: const Text('Insurance Claims', style: TextStyle(fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newClaim(context, viewModel),
        backgroundColor: kTealDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New claim', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(color: kTeal, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    );
  }

  Widget _buildBody(BuildContext context, InsuranceClaimsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.claims.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }
    if (viewModel.loadError != null && viewModel.claims.isEmpty) {
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
              _StatTile(label: 'Approved', value: '${stats.approved}', color: kSuccessFg, bg: kSuccessBg),
              _StatTile(label: 'Rejected', value: '${stats.rejected}', color: kDangerFg, bg: kDangerBg),
            ],
          ),
        const SizedBox(height: 20),
        if (viewModel.claims.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('No insurance claims yet', style: TextStyle(color: kMuted))))
        else
          for (final claim in viewModel.claims) ...[
            _ClaimCard(
              claim: claim,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => InsuranceClaimDetailScreen(claimId: claim.id)));
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
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final InsuranceClaim claim;
  final VoidCallback onTap;
  const _ClaimCard({required this.claim, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = claimStatusColors(claim.status);

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
                Expanded(child: Text(claim.patientName ?? 'Patient', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                  child: Text(titleCase(claim.status), style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(claim.patientMrn ?? '', style: const TextStyle(fontSize: 12, color: kMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text(claim.insuranceCompany, style: const TextStyle(fontSize: 12.5, color: kInk, fontWeight: FontWeight.w600))),
                Text('₹${claim.claimAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTealDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Patient search-and-select used by all three billing forms in this
/// module (Insurance Claims / IPD Deposits / Scheme Billing).
class ReceptionPatientPickerField extends StatefulWidget {
  final ReceptionPatient? value;
  final ValueChanged<ReceptionPatient?> onChanged;
  final String? errorText;
  const ReceptionPatientPickerField({super.key, required this.value, required this.onChanged, this.errorText});

  @override
  State<ReceptionPatientPickerField> createState() => _ReceptionPatientPickerFieldState();
}

class _ReceptionPatientPickerFieldState extends State<ReceptionPatientPickerField> {
  final _controller = TextEditingController();
  List<ReceptionPatient> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final token = await AuthStorage().readToken();
      final results = await guardNetworkErrors(() => ReceptionistApiService().patients(token!, q: query));
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: kMint, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.value!.name, style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                  Text(widget.value!.mrn, style: const TextStyle(fontSize: 12, color: kMuted)),
                ],
              ),
            ),
            IconButton(onPressed: () => widget.onChanged(null), icon: const Icon(Icons.close, size: 18)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: authFieldDecoration('Patient', hint: 'Search name or MRN', icon: Icons.search).copyWith(errorText: widget.errorText),
          onChanged: _search,
        ),
        if (_searching) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(color: kTeal)),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(12)),
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final p = _results[index];
                return ListTile(
                  dense: true,
                  title: Text(p.name),
                  subtitle: Text(p.mrn),
                  onTap: () {
                    widget.onChanged(p);
                    _controller.clear();
                    setState(() => _results = []);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ClaimFormScreen extends StatefulWidget {
  const _ClaimFormScreen();

  @override
  State<_ClaimFormScreen> createState() => _ClaimFormScreenState();
}

class _ClaimFormScreenState extends State<_ClaimFormScreen> {
  final _formKey = GlobalKey<FormState>();
  ReceptionPatient? _patient;
  final _companyController = TextEditingController();
  final _tpaController = TextEditingController();
  final _policyController = TextEditingController();
  final _memberController = TextEditingController();
  final _amountController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _icdController = TextEditingController();
  String _claimType = 'cashless';
  DateTime? _admissionDate;
  DateTime? _dischargeDate;
  bool _submitting = false;
  String? _patientError;

  @override
  void dispose() {
    _companyController.dispose();
    _tpaController.dispose();
    _policyController.dispose();
    _memberController.dispose();
    _amountController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _icdController.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(bool admission) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (admission ? _admissionDate : _dischargeDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (admission) {
        _admissionDate = picked;
      } else {
        _dischargeDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_patient == null) {
      setState(() => _patientError = 'Pick a patient');
      return;
    }

    setState(() => _submitting = true);
    final viewModel = context.read<InsuranceClaimsViewModel>();
    final error = await viewModel.store({
      'patient_id': _patient!.id,
      'insurance_company': _companyController.text.trim(),
      'tpa_name': _tpaController.text.trim().isEmpty ? null : _tpaController.text.trim(),
      'policy_number': _policyController.text.trim(),
      'member_id': _memberController.text.trim().isEmpty ? null : _memberController.text.trim(),
      'claim_amount': double.tryParse(_amountController.text) ?? 0,
      'claim_type': _claimType,
      'admission_date': _admissionDate != null ? _fmt(_admissionDate!) : null,
      'discharge_date': _dischargeDate != null ? _fmt(_dischargeDate!) : null,
      'diagnosis': _diagnosisController.text.trim().isEmpty ? null : _diagnosisController.text.trim(),
      'treatment_details': _treatmentController.text.trim().isEmpty ? null : _treatmentController.text.trim(),
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
      appBar: AppBar(backgroundColor: kBg, foregroundColor: kInk, elevation: 0, title: const Text('New Insurance Claim')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            ReceptionPatientPickerField(value: _patient, errorText: _patientError, onChanged: (p) => setState(() { _patient = p; _patientError = null; })),
            const SizedBox(height: 14),
            TextFormField(controller: _companyController, decoration: authFieldDecoration('Insurance company', hint: 'Required', icon: Icons.shield_outlined), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 14),
            TextFormField(controller: _tpaController, decoration: authFieldDecoration('TPA name', hint: 'Optional', icon: Icons.business_outlined)),
            const SizedBox(height: 14),
            TextFormField(controller: _policyController, decoration: authFieldDecoration('Policy number', hint: 'Required', icon: Icons.numbers_outlined), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 14),
            TextFormField(controller: _memberController, decoration: authFieldDecoration('Member ID', hint: 'Optional', icon: Icons.badge_outlined)),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: authFieldDecoration('Claim amount', hint: 'Required', icon: Icons.currency_rupee),
              validator: (v) => (double.tryParse(v ?? '') == null) ? 'Enter a valid amount' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _claimType,
              decoration: authFieldDecoration('Claim type', hint: '', icon: Icons.category_outlined),
              items: const [DropdownMenuItem(value: 'cashless', child: Text('Cashless')), DropdownMenuItem(value: 'reimbursement', child: Text('Reimbursement'))],
              onChanged: (v) => setState(() => _claimType = v ?? _claimType),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => _pickDate(true),
              child: InputDecorator(
                decoration: authFieldDecoration('Admission date', hint: 'Optional', icon: Icons.event_outlined),
                child: Text(_admissionDate != null ? _fmt(_admissionDate!) : 'Tap to pick', style: TextStyle(color: _admissionDate != null ? kInk : kMuted)),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => _pickDate(false),
              child: InputDecorator(
                decoration: authFieldDecoration('Discharge date', hint: 'Optional', icon: Icons.event_available_outlined),
                child: Text(_dischargeDate != null ? _fmt(_dischargeDate!) : 'Tap to pick', style: TextStyle(color: _dischargeDate != null ? kInk : kMuted)),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(controller: _diagnosisController, maxLines: 2, decoration: authFieldDecoration('Diagnosis', hint: 'Optional', icon: Icons.medical_information_outlined)),
            const SizedBox(height: 14),
            TextFormField(controller: _treatmentController, maxLines: 2, decoration: authFieldDecoration('Treatment details', hint: 'Optional', icon: Icons.healing_outlined)),
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
                    : const Text('Create claim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

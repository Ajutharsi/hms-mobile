import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/receptionist_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/receptionist/models/reception_appointment.dart';
import 'package:hms_mobile/features/receptionist/models/reception_patient.dart';
import 'package:hms_mobile/features/receptionist/models/referral.dart';
import 'package:hms_mobile/features/receptionist/screens/insurance_claims_screen.dart' show ReceptionPatientPickerField, titleCase;
import 'package:hms_mobile/features/receptionist/viewmodels/referrals_view_model.dart';

const _kPriorities = ['routine', 'urgent', 'emergency'];
const _kReferralStatuses = ['pending', 'accepted', 'completed', 'cancelled'];

(Color, Color) _priorityColors(String p) => switch (p) {
      'emergency' => (kDangerFg, kDangerBg),
      'urgent' => (kWarningFg, kWarningBg),
      _ => (kMuted, kFieldFill),
    };

(Color, Color) _statusColors(String s) => switch (s) {
      'accepted' => (kInfoFg, kInfoBg),
      'completed' => (kSuccessFg, kSuccessBg),
      'cancelled' => (kDangerFg, kDangerBg),
      _ => (kWarningFg, kWarningBg),
    };

class ReferralsScreen extends StatelessWidget {
  const ReferralsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReferralsViewModel(),
      child: const _ReferralsView(),
    );
  }
}

class _ReferralsView extends StatelessWidget {
  const _ReferralsView();

  Future<void> _newReferral(BuildContext context, ReferralsViewModel viewModel) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const _ReferralFormScreen()));
    if (saved == true) viewModel.load();
  }

  Future<void> _changeStatus(BuildContext context, ReferralsViewModel viewModel, Referral referral) async {
    final status = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Update status'),
        children: [
          for (final s in _kReferralStatuses)
            SimpleDialogOption(onPressed: () => Navigator.of(context).pop(s), child: Text(titleCase(s))),
        ],
      ),
    );
    if (status == null) return;
    final error = await viewModel.updateStatus(referral.id, status);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Referral status updated.')));
  }

  Future<void> _delete(BuildContext context, ReferralsViewModel viewModel, Referral referral) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this referral?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Color(0xFFB3261E)))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await viewModel.destroy(referral.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Referral deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReferralsViewModel>();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, foregroundColor: kInk, elevation: 0, title: const Text('Referrals', style: TextStyle(fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newReferral(context, viewModel),
        backgroundColor: kTealDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New referral', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              children: [
                ChoiceChip(label: const Text('All'), selected: viewModel.statusFilter == null, onSelected: (_) => viewModel.setFilter(null), selectedColor: kMint),
                const SizedBox(width: 8),
                for (final s in _kReferralStatuses) ...[
                  ChoiceChip(label: Text(titleCase(s)), selected: viewModel.statusFilter == s, onSelected: (_) => viewModel.setFilter(s), selectedColor: kMint),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(child: RefreshIndicator(color: kTeal, onRefresh: viewModel.load, child: _buildBody(context, viewModel))),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReferralsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.referrals.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }
    if (viewModel.loadError != null && viewModel.referrals.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }
    if (viewModel.referrals.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: const [
        SizedBox(height: 80),
        Icon(Icons.compare_arrows_outlined, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No referrals found', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: viewModel.referrals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final referral = viewModel.referrals[index];
        return _ReferralCard(
          referral: referral,
          onStatus: () => _changeStatus(context, viewModel, referral),
          onDelete: () => _delete(context, viewModel, referral),
        );
      },
    );
  }
}

class _ReferralCard extends StatelessWidget {
  final Referral referral;
  final VoidCallback onStatus;
  final VoidCallback onDelete;
  const _ReferralCard({required this.referral, required this.onStatus, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final (pFg, pBg) = _priorityColors(referral.priority);
    final (sFg, sBg) = _statusColors(referral.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kFieldFill)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(referral.patientName ?? 'Patient', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: sBg, borderRadius: BorderRadius.circular(8)),
                child: Text(titleCase(referral.status), style: TextStyle(color: sFg, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          Text(referral.patientMrn ?? '', style: const TextStyle(fontSize: 12, color: kMuted)),
          const SizedBox(height: 8),
          Text('${referral.referredByName ?? '—'} → ${referral.referredToName ?? '—'}', style: const TextStyle(fontSize: 12.5, color: kInk, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(referral.reason, style: const TextStyle(fontSize: 12.5, color: kMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: pBg, borderRadius: BorderRadius.circular(7)),
                child: Text(referral.priority, style: TextStyle(color: pFg, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(referral.referralNo ?? '', style: const TextStyle(fontSize: 11.5, color: kMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onStatus, child: const Text('Status', style: TextStyle(color: kTealDark, fontSize: 12.5, fontWeight: FontWeight.w600))),
              TextButton(onPressed: onDelete, child: const Text('Delete', style: TextStyle(color: Color(0xFFB3261E), fontSize: 12.5, fontWeight: FontWeight.w600))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReferralFormScreen extends StatefulWidget {
  const _ReferralFormScreen();

  @override
  State<_ReferralFormScreen> createState() => _ReferralFormScreenState();
}

class _ReferralFormScreenState extends State<_ReferralFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ReceptionistApiService();
  final _authStorage = AuthStorage();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoadingDoctors = true;
  bool _isSaving = false;
  String? _error;
  String? _patientError;

  List<ReceptionDoctor> _doctors = [];
  ReceptionPatient? _patient;
  ReceptionDoctor? _referredBy;
  ReceptionDoctor? _referredTo;
  String _priority = 'routine';
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    try {
      final token = await _authStorage.readToken();
      _doctors = await guardNetworkErrors(() => _api.doctors(token!));
    } catch (_) {
      _doctors = [];
    } finally {
      if (mounted) setState(() => _isLoadingDoctors = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now().add(const Duration(days: 30)));
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_patient == null) {
      setState(() => _patientError = 'Pick a patient.');
      return;
    }
    if (_referredBy == null || _referredTo == null) {
      setState(() => _error = 'Pick both referring and receiving doctors.');
      return;
    }
    if (_referredBy!.id == _referredTo!.id) {
      setState(() => _error = 'Referred-to doctor must differ from referred-by.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.referralStore(token!, {
            'patient_id': _patient!.id,
            'referred_by': _referredBy!.id,
            'referred_to': _referredTo!.id,
            'reason': _reasonController.text.trim(),
            if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
            'priority': _priority,
            'referral_date': '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
          }));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, foregroundColor: kInk, elevation: 0, title: const Text('New Referral', style: TextStyle(fontWeight: FontWeight.w700))),
      body: _isLoadingDoctors
          ? const Center(child: CircularProgressIndicator(color: kTeal))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  ReceptionPatientPickerField(value: _patient, errorText: _patientError, onChanged: (p) => setState(() { _patient = p; _patientError = null; })),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<ReceptionDoctor>(
                    initialValue: _referredBy,
                    decoration: authFieldDecoration('Referred by', hint: 'Select doctor', icon: Icons.medical_services_outlined),
                    items: _doctors.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
                    onChanged: (v) => setState(() => _referredBy = v),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<ReceptionDoctor>(
                    initialValue: _referredTo,
                    decoration: authFieldDecoration('Referred to', hint: 'Select doctor', icon: Icons.medical_information_outlined),
                    items: _doctors.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
                    onChanged: (v) => setState(() => _referredTo = v),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 2,
                    decoration: authFieldDecoration('Reason', hint: 'Required', icon: Icons.notes_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(controller: _notesController, maxLines: 2, decoration: authFieldDecoration('Notes (optional)', hint: '', icon: Icons.sticky_note_2_outlined)),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: authFieldDecoration('Priority', hint: '', icon: Icons.priority_high),
                    items: _kPriorities.map((p) => DropdownMenuItem(value: p, child: Text(titleCase(p)))).toList(),
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: authFieldDecoration('Referral date', hint: '', icon: Icons.calendar_today_outlined),
                      child: Text('${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    authErrorBanner(_error!),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: kTealDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create referral', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

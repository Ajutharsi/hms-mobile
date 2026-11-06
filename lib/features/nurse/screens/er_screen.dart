import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/nurse/models/er_registration.dart';
import 'package:hms_mobile/features/nurse/models/nurse_patient.dart';
import 'package:hms_mobile/features/nurse/viewmodels/er_view_model.dart';
import 'package:hms_mobile/features/nurse/widgets/patient_picker.dart';
import 'package:hms_mobile/features/patient/models/doctor.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';

const _kTriageLevels = ['red', 'yellow', 'green', 'black'];
const _kErStatuses = ['waiting', 'under_treatment', 'admitted', 'discharged', 'transferred', 'expired'];
const _kCloseStatuses = ['discharged', 'admitted', 'transferred', 'expired'];

String _titleCase(String s) => s.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

class ErScreen extends StatelessWidget {
  const ErScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => ErViewModel(),
      child: const _ErView(),
    );
  }
}

class _ErView extends StatelessWidget {
  const _ErView();

  Future<void> _register(BuildContext context, ErViewModel viewModel) async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const _RegisterErScreen()));
    if (created == true) viewModel.load();
  }

  Future<void> _triage(BuildContext context, ErViewModel viewModel, ErRegistration reg) async {
    final level = await showDialog<String>(context: context, builder: (_) => _TriageDialog(current: reg.triageLevel));
    if (level == null || !context.mounted) return;
    final error = await viewModel.triage(reg.id, level);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'Patient triaged.')));
  }

  Future<void> _update(BuildContext context, ErViewModel viewModel, ErRegistration reg) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _UpdateDialog(reg: reg));
    if (result == null || !context.mounted) return;
    final error = await viewModel.update(
      reg.id,
      attendingDoctorId: result['attending_doctor_id'] as int?,
      status: result['status'] as String,
      notes: result['notes'] as String?,
      icd10Code: result['icd10_code'] as String?,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'ER record updated.')));
  }

  Future<void> _discharge(BuildContext context, ErViewModel viewModel, ErRegistration reg) async {
    final result = await showDialog<Map<String, String?>>(context: context, builder: (_) => const _DischargeDialog());
    if (result == null || !context.mounted) return;
    final error = await viewModel.discharge(reg.id, status: result['status']!, notes: result['notes']);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'ER visit closed.')));
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<ErViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Emergency (ER)'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _register(context, viewModel),
        backgroundColor: kCareDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Register patient', style: CareText.onCare),
      ),
      body: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    ));
  }

  Widget _buildBody(BuildContext context, ErViewModel viewModel) {
    if (viewModel.isLoading && viewModel.registrations.isEmpty) {
      return const CareStateView.loading();
    }
    if (viewModel.loadError != null && viewModel.registrations.isEmpty) {
      return CareStateView.error(viewModel.loadError!);
    }

    final stats = viewModel.stats;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        if (stats != null)
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.1,
            children: [
              _StatTile(label: 'Waiting', value: '${stats.waiting}', color: kWarningFg, bg: kWarningBg),
              _StatTile(label: 'In treatment', value: '${stats.underTreatment}', color: kInfoFg, bg: kInfoBg),
              _StatTile(label: 'Red alert', value: '${stats.redAlert}', color: kDangerFg, bg: kDangerBg),
              _StatTile(label: 'Today', value: '${stats.todayTotal}', color: kCareDark, bg: kCareSoft),
            ],
          ),
        const SizedBox(height: 16),
        if (viewModel.registrations.isEmpty)
          const CareStateView.inline(icon: Icons.local_hospital_outlined, title: "No ER registrations", message: "Patients arriving at emergency appear here once registered.")
        else
          for (final reg in viewModel.registrations) ...[
            _ErCard(
              reg: reg,
              onTriage: () => _triage(context, viewModel, reg),
              onUpdate: () => _update(context, viewModel, reg),
              onDischarge: () => _discharge(context, viewModel, reg),
            ),
            const SizedBox(height: 12),
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
    watchCarePalette(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(CareRadius.control)),
      // Four of these share a row at a fixed aspect ratio, so the tile is
      // about 53px tall whatever the phone. At the system font scale this
      // user runs, the number and its label need more than that and the
      // tile overflowed; scaling down is better than clipping the count.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: CareText.statValue(color)),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: CareText.xxs, color: color, fontWeight: CareText.medium)),
          ],
        ),
      ),
    );
  }
}

class _ErCard extends StatelessWidget {
  final ErRegistration reg;
  final VoidCallback onTriage;
  final VoidCallback onUpdate;
  final VoidCallback onDischarge;
  const _ErCard({required this.reg, required this.onTriage, required this.onUpdate, required this.onDischarge});

  static const _triageColors = {
    'red': (kDangerFg, kDangerBg),
    'yellow': (kWarningFg, kWarningBg),
    'green': (kSuccessFg, kSuccessBg),
    'black': (Colors.white, Colors.black87),
  };

  static Map<String, (Color, Color)> get _statusColors => {
    'waiting': (kWarningFg, kWarningBg),
    'under_treatment': (kInfoFg, kInfoBg),
    'admitted': (kCareDark, kCareSoft),
    'discharged': (kSuccessFg, kSuccessBg),
    'transferred': (kMuted, kCareBg),
    'expired': (Colors.white, Colors.black87),
  };

  bool get _isClosed => ['discharged', 'transferred', 'expired'].contains(reg.status);

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final (tFg, tBg) = _triageColors[reg.triageLevel] ?? (kMuted, kCareBg);
    final (sFg, sBg) = _statusColors[reg.status] ?? (kMuted, kCareBg);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(CareRadius.card), border: Border.all(color: kCareBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reg.patientName, style: CareText.titleLg),
                    if (reg.patientMrn != null) Text(reg.patientMrn!, style: CareText.mutedXs),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: tBg, borderRadius: BorderRadius.circular(CareRadius.chip)),
                child: Text(reg.triageLevel.toUpperCase(), style: TextStyle(color: tFg, fontSize: CareText.xxs, fontWeight: CareText.bold)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: sBg, borderRadius: BorderRadius.circular(CareRadius.chip)),
                child: Text(_titleCase(reg.status), style: CareText.chip(sFg)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(reg.chiefComplaint, style: const TextStyle(fontSize: CareText.sm, color: kInk)),
          const SizedBox(height: 6),
          Row(
            children: [
              if (reg.age != null) Text('Age ${reg.age}', style: CareText.mutedXs),
              if (reg.age != null && (reg.gender ?? '').isNotEmpty) const Text('  ·  ', style: CareText.muted),
              if ((reg.gender ?? '').isNotEmpty) Text(reg.gender!, style: CareText.mutedXs),
            ],
          ),
          if ((reg.attendingDoctorName ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Attending: Dr. ${reg.attendingDoctorName}', style: CareText.mutedXs),
            ),
          if (!_isClosed) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton(onPressed: onTriage, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32), textStyle: CareText.plainSm), child: const Text('Triage')),
                OutlinedButton(onPressed: onUpdate, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32), textStyle: CareText.plainSm), child: const Text('Update')),
                FilledButton(
                  onPressed: onDischarge,
                  style: FilledButton.styleFrom(backgroundColor: kCareDark, minimumSize: const Size(0, 32), textStyle: CareText.plainSm),
                  child: const Text('Close visit'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TriageDialog extends StatefulWidget {
  final String current;
  const _TriageDialog({required this.current});

  @override
  State<_TriageDialog> createState() => _TriageDialogState();
}

class _TriageDialogState extends State<_TriageDialog> {
  late String _level = widget.current;

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return AlertDialog(
      title: const Text('Update triage level'),
      content: DropdownButtonFormField<String>(
                  isExpanded: true,
        initialValue: _level,
        items: _kTriageLevels.map((l) => DropdownMenuItem(value: l, child: Text(l.toUpperCase(), overflow: TextOverflow.ellipsis))).toList(),
        onChanged: (v) => setState(() => _level = v!),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(context).pop(_level), style: FilledButton.styleFrom(backgroundColor: kCareDark), child: const Text('Save')),
      ],
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final ErRegistration reg;
  const _UpdateDialog({required this.reg});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  late String _status = widget.reg.status;
  final _notesController = TextEditingController();
  final _icdController = TextEditingController();
  Doctor? _doctor;
  List<Doctor> _doctors = [];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final token = await AuthStorage().readToken();
      final doctors = await ApiService().getDoctors(token!);
      if (mounted) setState(() => _doctors = doctors);
    } catch (_) {}
  }

  @override
  void dispose() {
    _notesController.dispose();
    _icdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return AlertDialog(
      title: const Text('Update ER record'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
                  isExpanded: true,
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _kErStatuses.map((s) => DropdownMenuItem(value: s, child: Text(_titleCase(s), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 10),
            if (_doctors.isNotEmpty)
              DropdownButtonFormField<Doctor>(
                  isExpanded: true,
                initialValue: _doctor,
                decoration: const InputDecoration(labelText: 'Attending doctor (optional)'),
                items: _doctors.map((d) => DropdownMenuItem(value: d, child: Text(d.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _doctor = v),
              ),
            const SizedBox(height: 10),
            TextField(controller: _icdController, decoration: const InputDecoration(labelText: 'ICD-10 code (optional)')),
            const SizedBox(height: 10),
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop({
            'status': _status,
            'attending_doctor_id': _doctor?.id,
            'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            'icd10_code': _icdController.text.trim().isEmpty ? null : _icdController.text.trim(),
          }),
          style: FilledButton.styleFrom(backgroundColor: kCareDark),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _DischargeDialog extends StatefulWidget {
  const _DischargeDialog();

  @override
  State<_DischargeDialog> createState() => _DischargeDialogState();
}

class _DischargeDialogState extends State<_DischargeDialog> {
  String _status = 'discharged';
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return AlertDialog(
      title: const Text('Close ER visit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
                  isExpanded: true,
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Outcome'),
            items: _kCloseStatuses.map((s) => DropdownMenuItem(value: s, child: Text(_titleCase(s), overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setState(() => _status = v!),
          ),
          const SizedBox(height: 10),
          TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes (optional)'), maxLines: 3),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop({'status': _status, 'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim()}),
          style: FilledButton.styleFrom(backgroundColor: kCareDark),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _RegisterErScreen extends StatefulWidget {
  const _RegisterErScreen();

  @override
  State<_RegisterErScreen> createState() => _RegisterErScreenState();
}

class _RegisterErScreenState extends State<_RegisterErScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = NurseApiService();
  final _authStorage = AuthStorage();

  NursePatient? _existingPatient;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  String? _gender;
  String _triageLevel = 'green';
  final _complaintController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _arrivalController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _complaintController.dispose();
    _symptomsController.dispose();
    _arrivalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.erStore(
            token!,
            patientId: _existingPatient?.id,
            patientName: _nameController.text.trim(),
            patientPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            age: int.tryParse(_ageController.text.trim()),
            gender: _gender,
            triageLevel: _triageLevel,
            chiefComplaint: _complaintController.text.trim(),
            presentingSymptoms: _symptomsController.text.trim().isEmpty ? null : _symptomsController.text.trim(),
            modeOfArrival: _arrivalController.text.trim().isEmpty ? null : _arrivalController.text.trim(),
          ));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Register ER Patient'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PatientPickerField(
                label: 'Existing patient (optional)',
                value: _existingPatient,
                onChanged: (p) => setState(() {
                  _existingPatient = p;
                  _nameController.text = p.name;
                }),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                decoration: careFieldDecoration('Patient name', hint: 'Full name', icon: Icons.person_outline),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: careFieldDecoration('Phone', hint: 'Optional', icon: Icons.phone_outlined)),
              const SizedBox(height: 14),
              TextFormField(controller: _ageController, keyboardType: TextInputType.number, decoration: careFieldDecoration('Age', hint: 'Optional', icon: Icons.cake_outlined)),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                  isExpanded: true,
                initialValue: _gender,
                decoration: careFieldDecoration('Gender', hint: 'Optional', icon: Icons.wc_outlined),
                items: const [DropdownMenuItem(value: 'male', child: Text('Male', overflow: TextOverflow.ellipsis)), DropdownMenuItem(value: 'female', child: Text('Female', overflow: TextOverflow.ellipsis)), DropdownMenuItem(value: 'other', child: Text('Other', overflow: TextOverflow.ellipsis))],
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                  isExpanded: true,
                initialValue: _triageLevel,
                decoration: careFieldDecoration('Triage level', hint: '', icon: Icons.emergency_outlined),
                items: _kTriageLevels.map((l) => DropdownMenuItem(value: l, child: Text(l.toUpperCase(), overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _triageLevel = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _complaintController,
                decoration: careFieldDecoration('Chief complaint', hint: 'Reason for visit', icon: Icons.report_problem_outlined),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(controller: _symptomsController, maxLines: 3, decoration: careFieldDecoration('Presenting symptoms', hint: 'Optional', icon: Icons.notes_outlined)),
              const SizedBox(height: 14),
              TextFormField(controller: _arrivalController, decoration: careFieldDecoration('Mode of arrival', hint: 'e.g. ambulance, walk-in', icon: Icons.local_shipping_outlined)),
              const SizedBox(height: 20),
              if (_error != null) ...[authErrorBanner(_error!), const SizedBox(height: 14)],
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: kCareDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CareRadius.control))),
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Register patient', style: CareText.onCareBold),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

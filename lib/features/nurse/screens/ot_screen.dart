import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/nurse/models/nurse_patient.dart';
import 'package:hms_mobile/features/nurse/models/ot_schedule.dart';
import 'package:hms_mobile/features/nurse/viewmodels/ot_view_model.dart';
import 'package:hms_mobile/features/nurse/widgets/patient_picker.dart';
import 'package:hms_mobile/features/patient/models/doctor.dart';

class OtScreen extends StatelessWidget {
  const OtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => OtViewModel(),
      child: const _OtView(),
    );
  }
}

class _OtView extends StatelessWidget {
  const _OtView();

  Future<void> _schedule(BuildContext context, OtViewModel viewModel) async {
    final scheduled = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const _ScheduleOtScreen()));
    if (scheduled == true) viewModel.load();
  }

  Future<void> _start(BuildContext context, OtViewModel viewModel, OtSchedule ot) async {
    final error = await viewModel.start(ot.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'Surgery started.')),
    );
  }

  Future<void> _complete(BuildContext context, OtViewModel viewModel, OtSchedule ot) async {
    final result = await showDialog<Map<String, String>>(context: context, builder: (_) => _CompleteDialog(ot: ot));
    if (result == null || !context.mounted) return;

    final error = await viewModel.complete(ot.id, postOpNotes: result['post_op_notes'], complications: result['complications']);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'Surgery marked complete.')),
    );
  }

  Future<void> _cancel(BuildContext context, OtViewModel viewModel, OtSchedule ot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this surgery?'),
        content: Text('Cancel "${ot.procedureName}" for ${ot.patientName ?? 'this patient'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes, cancel', style: TextStyle(color: Color(0xFFB3261E)))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await viewModel.cancel(ot.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'OT schedule cancelled.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<OtViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Operation Theatre'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _schedule(context, viewModel),
        backgroundColor: kCareDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Schedule surgery', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    ));
  }

  Widget _buildBody(BuildContext context, OtViewModel viewModel) {
    if (viewModel.isLoading && viewModel.schedules.isEmpty) {
      return Center(child: CircularProgressIndicator(color: kCare));
    }
    if (viewModel.loadError != null && viewModel.schedules.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }
    if (viewModel.schedules.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: const [
        SizedBox(height: 80),
        Icon(Icons.medical_services_outlined, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No surgeries scheduled', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk)),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: viewModel.schedules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ot = viewModel.schedules[index];
        return _OtCard(
          ot: ot,
          onStart: () => _start(context, viewModel, ot),
          onComplete: () => _complete(context, viewModel, ot),
          onCancel: () => _cancel(context, viewModel, ot),
        );
      },
    );
  }
}

class _OtCard extends StatelessWidget {
  final OtSchedule ot;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  const _OtCard({required this.ot, required this.onStart, required this.onComplete, required this.onCancel});

  static const _priorityColors = {
    'elective': (kSuccessFg, kSuccessBg),
    'urgent': (kWarningFg, kWarningBg),
    'emergency': (kDangerFg, kDangerBg),
  };

  static Map<String, (Color, Color)> get _statusColors => {
    'scheduled': (kMuted, kCareBg),
    'in_progress': (kInfoFg, kInfoBg),
    'completed': (kSuccessFg, kSuccessBg),
    'cancelled': (kDangerFg, kDangerBg),
    'postponed': (kWarningFg, kWarningBg),
  };

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final (pFg, pBg) = _priorityColors[ot.priority] ?? (kMuted, kCareBg);
    final (sFg, sBg) = _statusColors[ot.status] ?? (kMuted, kCareBg);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kCareBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(ot.procedureName, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: kInk))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: sBg, borderRadius: BorderRadius.circular(8)),
                child: Text(ot.status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: sFg, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${ot.patientName ?? 'Patient'} · ${ot.patientMrn ?? ''}', style: const TextStyle(fontSize: 12.5, color: kMuted)),
          if ((ot.surgeonName ?? '').isNotEmpty) Text('Surgeon: ${ot.surgeonName}', style: const TextStyle(fontSize: 12.5, color: kMuted)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 14, color: kMuted),
              const SizedBox(width: 6),
              Expanded(child: Text(ot.scheduledStart ?? '—', style: const TextStyle(fontSize: 12.5, color: kMuted))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: pBg, borderRadius: BorderRadius.circular(8)),
                child: Text(ot.priority.toUpperCase(), style: TextStyle(color: pFg, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if ((ot.theatreNo ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Theatre ${ot.theatreNo}', style: const TextStyle(fontSize: 12.5, color: kMuted)),
          ],
          if (ot.status == 'scheduled' || ot.status == 'in_progress' || ot.status == 'postponed') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onCancel, child: const Text('Cancel', style: TextStyle(color: Color(0xFFB3261E)))),
                const SizedBox(width: 4),
                if (ot.status == 'scheduled')
                  FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Start'),
                    style: FilledButton.styleFrom(backgroundColor: kCareDark, minimumSize: const Size(0, 34), textStyle: const TextStyle(fontSize: 13)),
                  ),
                if (ot.status == 'in_progress')
                  FilledButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Complete'),
                    style: FilledButton.styleFrom(backgroundColor: kCareDark, minimumSize: const Size(0, 34), textStyle: const TextStyle(fontSize: 13)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CompleteDialog extends StatefulWidget {
  final OtSchedule ot;
  const _CompleteDialog({required this.ot});

  @override
  State<_CompleteDialog> createState() => _CompleteDialogState();
}

class _CompleteDialogState extends State<_CompleteDialog> {
  final _postOpController = TextEditingController();
  final _complicationsController = TextEditingController();

  @override
  void dispose() {
    _postOpController.dispose();
    _complicationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return AlertDialog(
      title: const Text('Complete surgery'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _postOpController,
              maxLines: 3,
              decoration: careFieldDecoration('Post-op notes', hint: 'Optional', icon: Icons.notes_outlined),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _complicationsController,
              maxLines: 3,
              decoration: careFieldDecoration('Complications', hint: 'Optional', icon: Icons.warning_amber_outlined),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop({'post_op_notes': _postOpController.text, 'complications': _complicationsController.text}),
          style: FilledButton.styleFrom(backgroundColor: kCareDark),
          child: const Text('Complete'),
        ),
      ],
    );
  }
}

class _ScheduleOtScreen extends StatefulWidget {
  const _ScheduleOtScreen();

  @override
  State<_ScheduleOtScreen> createState() => _ScheduleOtScreenState();
}

class _ScheduleOtScreenState extends State<_ScheduleOtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _theatreController = TextEditingController();
  final _procedureController = TextEditingController();
  final _icd10Controller = TextEditingController();
  final _preOpController = TextEditingController();

  NursePatient? _patient;
  Doctor? _surgeon;
  Doctor? _anaesthetist;
  String? _anaesthesiaType;
  String _priority = 'elective';
  DateTime? _scheduledStart;
  DateTime? _scheduledEnd;
  bool _submitting = false;
  String? _patientError;

  List<Doctor>? _doctors;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final token = await AuthStorage().readToken();
      final doctors = await ApiService().getDoctors(token ?? '');
      if (mounted) setState(() => _doctors = doctors);
    } catch (_) {
      if (mounted) setState(() => _doctors = []);
    }
  }

  @override
  void dispose() {
    _theatreController.dispose();
    _procedureController.dispose();
    _icd10Controller.dispose();
    _preOpController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initial = (isStart ? _scheduledStart : _scheduledEnd) ?? DateTime.now();
    final date = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return;
    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _scheduledStart = combined;
      } else {
        _scheduledEnd = combined;
      }
    });
  }

  String _fmt(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    setState(() => _patientError = _patient == null ? 'Pick a patient' : null);
    if (_patient == null || !_formKey.currentState!.validate() || _scheduledStart == null) {
      if (_scheduledStart == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick a scheduled start date/time.')));
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      final token = await AuthStorage().readToken();
      await guardNetworkErrors(() => NurseApiService().otStore(
            token!,
            patientId: _patient!.id,
            surgeonId: _surgeon?.id,
            anaesthetistId: _anaesthetist?.id,
            theatreNo: _theatreController.text.trim().isEmpty ? null : _theatreController.text.trim(),
            procedureName: _procedureController.text.trim(),
            icd10Code: _icd10Controller.text.trim().isEmpty ? null : _icd10Controller.text.trim(),
            anaesthesiaType: _anaesthesiaType,
            priority: _priority,
            scheduledStart: _fmt(_scheduledStart!),
            scheduledEnd: _scheduledEnd != null ? _fmt(_scheduledEnd!) : null,
            preOpNotes: _preOpController.text.trim().isEmpty ? null : _preOpController.text.trim(),
          ));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Schedule Surgery'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            PatientPickerField(value: _patient, errorText: _patientError, onChanged: (p) => setState(() => _patient = p)),
            const SizedBox(height: 14),
            TextFormField(
              controller: _procedureController,
              decoration: careFieldDecoration('Procedure name', hint: 'e.g. Appendectomy', icon: Icons.medical_services_outlined),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _DoctorDropdown(label: 'Surgeon (optional)', doctors: _doctors, value: _surgeon, onChanged: (d) => setState(() => _surgeon = d)),
            const SizedBox(height: 14),
            _DoctorDropdown(label: 'Anaesthetist (optional)', doctors: _doctors, value: _anaesthetist, onChanged: (d) => setState(() => _anaesthetist = d)),
            const SizedBox(height: 14),
            TextFormField(controller: _theatreController, decoration: careFieldDecoration('Theatre no.', hint: 'Optional', icon: Icons.meeting_room_outlined)),
            const SizedBox(height: 14),
            TextFormField(controller: _icd10Controller, decoration: careFieldDecoration('ICD-10 code', hint: 'Optional', icon: Icons.tag_outlined)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _anaesthesiaType,
              decoration: careFieldDecoration('Anaesthesia type', hint: 'Optional', icon: Icons.healing_outlined),
              items: const ['general', 'spinal', 'epidural', 'local', 'sedation']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1))))
                  .toList(),
              onChanged: (v) => setState(() => _anaesthesiaType = v),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: careFieldDecoration('Priority', hint: '', icon: Icons.priority_high_outlined),
              items: const ['elective', 'urgent', 'emergency'].map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1)))).toList(),
              onChanged: (v) => setState(() => _priority = v ?? 'elective'),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => _pickDateTime(true),
              child: InputDecorator(
                decoration: careFieldDecoration('Scheduled start', hint: 'Tap to pick', icon: Icons.schedule_outlined),
                child: Text(_scheduledStart != null ? _fmt(_scheduledStart!) : 'Tap to pick', style: TextStyle(color: _scheduledStart != null ? kInk : kMuted)),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => _pickDateTime(false),
              child: InputDecorator(
                decoration: careFieldDecoration('Scheduled end', hint: 'Optional', icon: Icons.schedule_outlined),
                child: Text(_scheduledEnd != null ? _fmt(_scheduledEnd!) : 'Optional', style: TextStyle(color: _scheduledEnd != null ? kInk : kMuted)),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(controller: _preOpController, maxLines: 3, decoration: careFieldDecoration('Pre-op notes', hint: 'Optional', icon: Icons.notes_outlined)),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: kCareDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

class _DoctorDropdown extends StatelessWidget {
  final String label;
  final List<Doctor>? doctors;
  final Doctor? value;
  final ValueChanged<Doctor?> onChanged;
  const _DoctorDropdown({required this.label, required this.doctors, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    if (doctors == null) {
      return SizedBox(height: 54, child: Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kCare))));
    }

    return DropdownButtonFormField<Doctor>(
      initialValue: value,
      decoration: careFieldDecoration(label, hint: 'Optional', icon: Icons.person_outline),
      isExpanded: true,
      items: doctors!.map((d) => DropdownMenuItem(value: d, child: Text(d.label, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }
}

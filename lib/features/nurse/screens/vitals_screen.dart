import 'package:flutter/material.dart';

import 'package:hms_mobile/core/models/date_display.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/nurse/models/nurse_patient.dart';
import 'package:hms_mobile/features/nurse/models/nurse_vital.dart';
import 'package:hms_mobile/features/nurse/viewmodels/vitals_view_model.dart';
import 'package:hms_mobile/features/nurse/widgets/patient_picker.dart';

class VitalsScreen extends StatelessWidget {
  const VitalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => VitalsViewModel(),
      child: const _VitalsView(),
    );
  }
}

class _VitalsView extends StatelessWidget {
  const _VitalsView();

  Future<void> _record(BuildContext context, VitalsViewModel viewModel) async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const _RecordVitalsScreen()));
    if (created == true) viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<VitalsViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Vitals'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _record(context, viewModel),
        backgroundColor: kCareDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Record vitals', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    ));
  }

  Widget _buildBody(BuildContext context, VitalsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.vitals.isEmpty) {
      return Center(child: CircularProgressIndicator(color: kCare));
    }
    if (viewModel.loadError != null && viewModel.vitals.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }
    if (viewModel.vitals.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: const [
        SizedBox(height: 80),
        Icon(Icons.favorite_border, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No vitals recorded yet', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk)),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: viewModel.vitals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final v = viewModel.vitals[index];
        return _VitalCard(
          vital: v,
          onTapTrend: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _VitalsHistoryScreen(patientId: v.patientId, patientName: v.patientName ?? 'Patient'))),
        );
      },
    );
  }
}

(Color, Color) _newsColors(int? score) {
  if (score == null) return (kMuted, kCareBg);
  if (score >= 5) return (kDangerFg, kDangerBg);
  if (score >= 3) return (kWarningFg, kWarningBg);
  return (kSuccessFg, kSuccessBg);
}

class _VitalCard extends StatelessWidget {
  final NurseVital vital;
  final VoidCallback onTapTrend;
  const _VitalCard({required this.vital, required this.onTapTrend});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final (newsFg, newsBg) = _newsColors(vital.newsScore);

    return InkWell(
      onTap: onTapTrend,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kCareBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vital.patientName ?? 'Patient', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
                      if (vital.patientMrn != null) Text(vital.patientMrn!, style: const TextStyle(fontSize: 11.5, color: kMuted)),
                    ],
                  ),
                ),
                if (vital.newsScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: newsBg, borderRadius: BorderRadius.circular(8)),
                    child: Text('NEWS ${vital.newsScore}', style: TextStyle(color: newsFg, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _Reading(icon: Icons.favorite_border, label: 'BP', value: vital.bloodPressure ?? '—'),
                _Reading(icon: Icons.monitor_heart_outlined, label: 'Pulse', value: vital.pulseRate != null ? '${vital.pulseRate}' : '—'),
                _Reading(icon: Icons.thermostat_outlined, label: 'Temp', value: vital.temperature != null ? '${vital.temperature}°' : '—'),
                _Reading(icon: Icons.air_outlined, label: 'SpO2', value: vital.spo2 != null ? '${vital.spo2}%' : '—'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 13, color: kMuted),
                const SizedBox(width: 6),
                Text(shortDateTime(vital.recordedAt), style: const TextStyle(fontSize: 12, color: kMuted)),
                if (vital.recordedByName != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.person_outline, size: 13, color: kMuted),
                  const SizedBox(width: 4),
                  Text(vital.recordedByName!, style: const TextStyle(fontSize: 12, color: kMuted)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Reading({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: kMuted),
        const SizedBox(width: 4),
        Text('$label ', style: const TextStyle(fontSize: 12, color: kMuted)),
        Text(value, style: const TextStyle(fontSize: 12.5, color: kInk, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _RecordVitalsScreen extends StatefulWidget {
  const _RecordVitalsScreen();

  @override
  State<_RecordVitalsScreen> createState() => _RecordVitalsScreenState();
}

class _RecordVitalsScreenState extends State<_RecordVitalsScreen> {
  final _bpController = TextEditingController();
  final _tempController = TextEditingController();
  final _pulseController = TextEditingController();
  final _rrController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _notesController = TextEditingController();

  NursePatient? _patient;
  bool _saving = false;
  String? _error;
  String? _patientError;

  @override
  void dispose() {
    _bpController.dispose();
    _tempController.dispose();
    _pulseController.dispose();
    _rrController.dispose();
    _spo2Controller.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _patientError = _patient == null ? 'Choose a patient' : null);
    if (_patient == null) {
      setState(() => _error = 'Choose a patient first.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final viewModel = context.read<VitalsViewModel>();
    final error = await viewModel.record(
      patientId: _patient!.id,
      bloodPressure: _bpController.text.trim().isEmpty ? null : _bpController.text.trim(),
      temperature: num.tryParse(_tempController.text.trim()),
      pulseRate: int.tryParse(_pulseController.text.trim()),
      respiratoryRate: int.tryParse(_rrController.text.trim()),
      spo2: int.tryParse(_spo2Controller.text.trim()),
      weight: num.tryParse(_weightController.text.trim()),
      height: num.tryParse(_heightController.text.trim()),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Record vitals'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[authErrorBanner(_error!), const SizedBox(height: 16)],
              PatientPickerField(value: _patient, errorText: _patientError, onChanged: (p) => setState(() => _patient = p)),
              const SizedBox(height: 16),
              TextField(controller: _bpController, decoration: careFieldDecoration('Blood pressure', hint: '120/80', icon: Icons.favorite_border)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextField(controller: _pulseController, keyboardType: TextInputType.number, decoration: careFieldDecoration('Pulse', hint: 'bpm', icon: Icons.monitor_heart_outlined))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _tempController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: careFieldDecoration('Temp', hint: '°C', icon: Icons.thermostat_outlined))),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextField(controller: _rrController, keyboardType: TextInputType.number, decoration: careFieldDecoration('Resp. rate', hint: '/min', icon: Icons.air_outlined))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _spo2Controller, keyboardType: TextInputType.number, decoration: careFieldDecoration('SpO2', hint: '%', icon: Icons.bubble_chart_outlined))),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextField(controller: _weightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: careFieldDecoration('Weight (optional)', hint: 'kg', icon: Icons.scale_outlined))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _heightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: careFieldDecoration('Height (optional)', hint: 'cm', icon: Icons.height))),
              ]),
              const SizedBox(height: 14),
              TextField(controller: _notesController, maxLines: 3, decoration: careFieldDecoration('Notes (optional)', hint: '', icon: Icons.notes_outlined)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: kCareDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : const Text('Save vitals', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class _VitalsHistoryScreen extends StatelessWidget {
  final int patientId;
  final String patientName;
  const _VitalsHistoryScreen({required this.patientId, required this.patientName});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => VitalsHistoryViewModel(patientId: patientId),
      child: _VitalsHistoryView(patientName: patientName),
    );
  }
}

class _VitalsHistoryView extends StatelessWidget {
  final String patientName;
  const _VitalsHistoryView({required this.patientName});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<VitalsHistoryViewModel>();

    return CareTheme(child: Scaffold(
      appBar: carePageAppBar(context, '$patientName — history'),
      body: viewModel.isLoading
          ? Center(child: CircularProgressIndicator(color: kCare))
          : viewModel.loadError != null
              ? Center(child: Text(viewModel.loadError!, style: const TextStyle(color: kMuted)))
              : viewModel.history.isEmpty
                  ? const Center(child: Text('No history yet.', style: TextStyle(color: kMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      itemCount: viewModel.history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _VitalCard(vital: viewModel.history[index], onTapTrend: () {}),
                    ),
    ));
  }
}

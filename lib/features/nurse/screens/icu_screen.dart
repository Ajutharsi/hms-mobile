import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/nurse/models/icu_chart.dart';
import 'package:hms_mobile/features/nurse/models/nurse_patient.dart';
import 'package:hms_mobile/features/nurse/viewmodels/icu_view_model.dart';
import 'package:hms_mobile/features/nurse/widgets/patient_picker.dart';

class IcuScreen extends StatelessWidget {
  const IcuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IcuViewModel(),
      child: const _IcuView(),
    );
  }
}

class _IcuView extends StatelessWidget {
  const _IcuView();

  Future<void> _newChart(BuildContext context, IcuViewModel viewModel) async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const _NewIcuChartScreen()));
    if (created == true) viewModel.load();
  }

  Future<void> _delete(BuildContext context, IcuViewModel viewModel, IcuChart chart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this chart?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Color(0xFFB3261E)))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await viewModel.destroy(chart.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Chart deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<IcuViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, foregroundColor: kInk, elevation: 0, title: const Text('ICU Charting', style: TextStyle(fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newChart(context, viewModel),
        backgroundColor: kTealDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New chart', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(color: kTeal, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    );
  }

  Widget _buildBody(BuildContext context, IcuViewModel viewModel) {
    if (viewModel.isLoading && viewModel.charts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }
    if (viewModel.loadError != null && viewModel.charts.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }
    if (viewModel.charts.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: const [
        SizedBox(height: 80),
        Icon(Icons.monitor_heart_outlined, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No ICU charts recorded yet', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk)),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: viewModel.charts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final chart = viewModel.charts[index];
        return _IcuCard(chart: chart, onDelete: () => _delete(context, viewModel, chart));
      },
    );
  }
}

(Color, Color, String) _gcsStyle(int? total) {
  if (total == null) return (kMuted, kFieldFill, '—');
  if (total < 9) return (kDangerFg, kDangerBg, 'Severe');
  if (total <= 12) return (kWarningFg, kWarningBg, 'Moderate');
  return (kSuccessFg, kSuccessBg, 'Mild');
}

class _IcuCard extends StatelessWidget {
  final IcuChart chart;
  final VoidCallback onDelete;
  const _IcuCard({required this.chart, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final (gcsFg, gcsBg, gcsLabel) = _gcsStyle(chart.gcsTotal);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kFieldFill)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chart.patientName ?? 'Patient', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
                    if (chart.patientMrn != null) Text(chart.patientMrn!, style: const TextStyle(fontSize: 11.5, color: kMuted)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 19, color: kMuted),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (chart.gcsTotal != null)
                _Chip(bg: gcsBg, fg: gcsFg, label: 'GCS ${chart.gcsTotal} · $gcsLabel'),
              if (chart.heartRate != null) _Chip(bg: kInfoBg, fg: kInfoFg, label: 'HR ${chart.heartRate}'),
              if ((chart.ventilatorMode ?? '').isNotEmpty) _Chip(bg: kFieldFill, fg: kMuted, label: 'Vent: ${chart.ventilatorMode}'),
              if ((chart.arterialBp ?? '').isNotEmpty) _Chip(bg: kFieldFill, fg: kMuted, label: 'BP ${chart.arterialBp}'),
              if (chart.fluidBalance != null) _Chip(bg: kFieldFill, fg: kMuted, label: 'Balance ${chart.fluidBalance}'),
            ],
          ),
          if ((chart.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(chart.notes!, style: const TextStyle(fontSize: 12.5, color: kMuted)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 13, color: kMuted),
              const SizedBox(width: 6),
              Text(chart.chartedAt ?? '', style: const TextStyle(fontSize: 12, color: kMuted)),
              if (chart.recordedByName != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.person_outline, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Text(chart.recordedByName!, style: const TextStyle(fontSize: 12, color: kMuted)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final Color bg;
  final Color fg;
  final String label;
  const _Chip({required this.bg, required this.fg, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _NewIcuChartScreen extends StatefulWidget {
  const _NewIcuChartScreen();

  @override
  State<_NewIcuChartScreen> createState() => _NewIcuChartScreenState();
}

class _NewIcuChartScreenState extends State<_NewIcuChartScreen> {
  NursePatient? _patient;
  String? _patientError;
  bool _submitting = false;

  final _ventilatorMode = TextEditingController();
  final _fio2 = TextEditingController();
  final _peep = TextEditingController();
  final _tidalVolume = TextEditingController();
  final _respRateSet = TextEditingController();

  final _arterialBp = TextEditingController();
  final _cvp = TextEditingController();
  final _heartRate = TextEditingController();
  final _rhythm = TextEditingController();

  int? _gcsEye;
  int? _gcsVerbal;
  int? _gcsMotor;

  final _intakeOral = TextEditingController();
  final _intakeIv = TextEditingController();
  final _outputUrine = TextEditingController();
  final _outputDrain = TextEditingController();

  final _linesDrains = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _ventilatorMode,
      _fio2,
      _peep,
      _tidalVolume,
      _respRateSet,
      _arterialBp,
      _cvp,
      _heartRate,
      _rhythm,
      _intakeOral,
      _intakeIv,
      _outputUrine,
      _outputDrain,
      _linesDrains,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_patient == null) {
      setState(() => _patientError = 'Pick a patient');
      return;
    }

    setState(() => _submitting = true);
    try {
      final token = await AuthStorage().readToken();
      final fields = <String, dynamic>{'patient_id': _patient!.id};
      void addStr(String key, TextEditingController c) {
        if (c.text.trim().isNotEmpty) fields[key] = c.text.trim();
      }

      void addNum(String key, TextEditingController c) {
        final v = num.tryParse(c.text.trim());
        if (v != null) fields[key] = v;
      }

      addStr('ventilator_mode', _ventilatorMode);
      addNum('fio2', _fio2);
      addNum('peep', _peep);
      addNum('tidal_volume', _tidalVolume);
      addNum('respiratory_rate_set', _respRateSet);
      addStr('arterial_bp', _arterialBp);
      addNum('cvp', _cvp);
      addNum('heart_rate', _heartRate);
      addStr('rhythm', _rhythm);
      if (_gcsEye != null) fields['gcs_eye'] = _gcsEye;
      if (_gcsVerbal != null) fields['gcs_verbal'] = _gcsVerbal;
      if (_gcsMotor != null) fields['gcs_motor'] = _gcsMotor;
      addNum('intake_oral', _intakeOral);
      addNum('intake_iv', _intakeIv);
      addNum('output_urine', _outputUrine);
      addNum('output_drain', _outputDrain);
      addStr('lines_drains', _linesDrains);
      addStr('notes', _notes);

      await guardNetworkErrors(() => NurseApiService().icuStore(token!, fields));
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, foregroundColor: kInk, elevation: 0, title: const Text('New ICU Chart')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          PatientPickerField(value: _patient, errorText: _patientError, onChanged: (p) => setState(() => _patient = p)),
          const SizedBox(height: 20),
          const _SectionLabel('Respiratory'),
          TextField(controller: _ventilatorMode, decoration: authFieldDecoration('Ventilator mode', hint: 'Optional', icon: Icons.air_outlined)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _fio2, keyboardType: TextInputType.number, decoration: authFieldDecoration('FiO2 %', hint: '0-100', icon: Icons.bubble_chart_outlined))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _peep, keyboardType: TextInputType.number, decoration: authFieldDecoration('PEEP', hint: '0-50', icon: Icons.compress_outlined))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _tidalVolume, keyboardType: TextInputType.number, decoration: authFieldDecoration('Tidal volume', hint: 'Optional', icon: Icons.air))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _respRateSet, keyboardType: TextInputType.number, decoration: authFieldDecoration('Set resp. rate', hint: 'Optional', icon: Icons.speed_outlined))),
          ]),
          const SizedBox(height: 20),
          const _SectionLabel('Cardiac'),
          TextField(controller: _arterialBp, decoration: authFieldDecoration('Arterial BP', hint: '120/80', icon: Icons.favorite_border)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _cvp, keyboardType: TextInputType.number, decoration: authFieldDecoration('CVP', hint: 'Optional', icon: Icons.monitor_heart_outlined))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _heartRate, keyboardType: TextInputType.number, decoration: authFieldDecoration('Heart rate', hint: '0-300', icon: Icons.favorite))),
          ]),
          const SizedBox(height: 12),
          TextField(controller: _rhythm, decoration: authFieldDecoration('Rhythm', hint: 'Optional', icon: Icons.show_chart)),
          const SizedBox(height: 20),
          const _SectionLabel('Neuro (GCS)'),
          Row(children: [
            Expanded(child: _GcsDropdown(label: 'Eye', max: 4, value: _gcsEye, onChanged: (v) => setState(() => _gcsEye = v))),
            const SizedBox(width: 10),
            Expanded(child: _GcsDropdown(label: 'Verbal', max: 5, value: _gcsVerbal, onChanged: (v) => setState(() => _gcsVerbal = v))),
            const SizedBox(width: 10),
            Expanded(child: _GcsDropdown(label: 'Motor', max: 6, value: _gcsMotor, onChanged: (v) => setState(() => _gcsMotor = v))),
          ]),
          const SizedBox(height: 20),
          const _SectionLabel('Fluid balance'),
          Row(children: [
            Expanded(child: TextField(controller: _intakeOral, keyboardType: TextInputType.number, decoration: authFieldDecoration('Intake oral', hint: 'mL', icon: Icons.local_drink_outlined))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _intakeIv, keyboardType: TextInputType.number, decoration: authFieldDecoration('Intake IV', hint: 'mL', icon: Icons.opacity_outlined))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _outputUrine, keyboardType: TextInputType.number, decoration: authFieldDecoration('Output urine', hint: 'mL', icon: Icons.water_drop_outlined))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _outputDrain, keyboardType: TextInputType.number, decoration: authFieldDecoration('Output drain', hint: 'mL', icon: Icons.water_drop_outlined))),
          ]),
          const SizedBox(height: 20),
          TextField(controller: _linesDrains, decoration: authFieldDecoration('Lines / drains', hint: 'Optional', icon: Icons.link)),
          const SizedBox(height: 12),
          TextField(controller: _notes, maxLines: 3, decoration: authFieldDecoration('Notes', hint: 'Optional', icon: Icons.notes_outlined)),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: kTealDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save chart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.3)),
    );
  }
}

class _GcsDropdown extends StatelessWidget {
  final String label;
  final int max;
  final int? value;
  final ValueChanged<int?> onChanged;
  const _GcsDropdown({required this.label, required this.max, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: authFieldDecoration(label, hint: '', icon: Icons.remove_red_eye_outlined),
      items: List.generate(max, (i) => i + 1).map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
      onChanged: onChanged,
    );
  }
}

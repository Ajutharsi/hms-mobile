import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/nurse/models/round_assignment.dart';
import 'package:hms_mobile/features/nurse/viewmodels/rounds_view_model.dart';

class MyRoundsScreen extends StatelessWidget {
  const MyRoundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => MyRoundsViewModel(),
      child: const _MyRoundsView(),
    );
  }
}

class _MyRoundsView extends StatelessWidget {
  const _MyRoundsView();

  static const _alertStyle = {
    'ok': (kSuccessFg, kSuccessBg, 'On track'),
    'warning': (kWarningFg, kWarningBg, 'Due soon'),
    'danger': (kDangerFg, kDangerBg, 'Overdue'),
  };

  Future<void> _markRound(BuildContext context, MyRoundsViewModel viewModel, RoundAssignment assignment, RoundPatient patient) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _MarkRoundDialog(patient: patient),
    );
    if (result == null || !context.mounted) return;

    final error = await viewModel.markRound(
      patient.id,
      assignmentId: assignment.id,
      bloodPressure: result['blood_pressure']?.isEmpty == true ? null : result['blood_pressure'],
      temperature: result['temperature']?.isEmpty == true ? null : result['temperature'],
      pulseRate: result['pulse_rate']?.isEmpty == true ? null : result['pulse_rate'],
      spo2: result['spo2']?.isEmpty == true ? null : result['spo2'],
      notes: result['notes']?.isEmpty == true ? null : result['notes'],
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'Round marked complete for ${patient.name}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<MyRoundsViewModel>();

    return CareTheme(child: Scaffold(
      appBar: carePageAppBar(context, 'My Rounds'),
      body: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    ));
  }

  Widget _buildBody(BuildContext context, MyRoundsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.assignments.isEmpty) {
      return Center(child: CircularProgressIndicator(color: kCare));
    }

    if (viewModel.loadError != null && viewModel.assignments.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
          const SizedBox(height: 12),
          Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
        ],
      );
    }

    if (viewModel.assignments.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.schedule_outlined, color: kMuted, size: 40),
          SizedBox(height: 12),
          Text('You have no active round assignments', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: viewModel.assignments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final assignment = viewModel.assignments[index];
        final (fg, bg, label) = _alertStyle[assignment.alertStatus] ?? (kMuted, kCareBg, assignment.alertStatus);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: assignment.alertStatus == 'danger' ? kDangerFg : kCareBg, width: assignment.alertStatus == 'danger' ? 1.4 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(assignment.wardName, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: kInk))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                    child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                assignment.isOverdue
                    ? 'Round was due at ${assignment.nextRoundAt ?? '—'}'
                    : 'Next round: ${assignment.nextRoundAt ?? '—'}${assignment.minutesLeft != null ? ' (${assignment.minutesLeft}m left)' : ''}',
                style: const TextStyle(fontSize: 12.5, color: kMuted),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: kCareBorder),
              const SizedBox(height: 10),
              for (final patient in assignment.patients) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: kInk)),
                            Text('${patient.mrn} · Bed ${patient.bedNo}', style: const TextStyle(fontSize: 11.5, color: kMuted)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => _markRound(context, viewModel, assignment, patient),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kCareDark,
                          side: BorderSide(color: kCareDark),
                          minimumSize: const Size(0, 32),
                          textStyle: const TextStyle(fontSize: 12.5),
                        ),
                        child: const Text('Mark round'),
                      ),
                    ],
                  ),
                ),
                if (patient != assignment.patients.last) Divider(height: 16, color: kCareBg),
              ],
              if (assignment.patients.isEmpty) const Text('No admitted patients in this ward right now.', style: TextStyle(color: kMuted, fontSize: 12.5)),
            ],
          ),
        );
      },
    );
  }
}

class _MarkRoundDialog extends StatefulWidget {
  final RoundPatient patient;
  const _MarkRoundDialog({required this.patient});

  @override
  State<_MarkRoundDialog> createState() => _MarkRoundDialogState();
}

class _MarkRoundDialogState extends State<_MarkRoundDialog> {
  final _bp = TextEditingController();
  final _temp = TextEditingController();
  final _pulse = TextEditingController();
  final _spo2 = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _bp.dispose();
    _temp.dispose();
    _pulse.dispose();
    _spo2.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return AlertDialog(
      title: Text('Mark round — ${widget.patient.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _bp, decoration: const InputDecoration(labelText: 'Blood pressure', hintText: '120/80')),
            const SizedBox(height: 8),
            TextField(controller: _temp, decoration: const InputDecoration(labelText: 'Temperature')),
            const SizedBox(height: 8),
            TextField(controller: _pulse, decoration: const InputDecoration(labelText: 'Pulse rate')),
            const SizedBox(height: 8),
            TextField(controller: _spo2, decoration: const InputDecoration(labelText: 'SpO2')),
            const SizedBox(height: 8),
            TextField(controller: _notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kCareDark),
          onPressed: () => Navigator.of(context).pop({
            'blood_pressure': _bp.text.trim(),
            'temperature': _temp.text.trim(),
            'pulse_rate': _pulse.text.trim(),
            'spo2': _spo2.text.trim(),
            'notes': _notes.text.trim(),
          }),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

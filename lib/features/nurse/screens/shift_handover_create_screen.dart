import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/nurse/models/shift_handover.dart';
import 'package:hms_mobile/features/nurse/viewmodels/handover_create_view_model.dart';

/// New-handover flow: pick ward/shifts/incoming nurse/date, edit a card per
/// admitted patient in that ward, add optional tasks, then submit as a
/// draft. Long single-scroll form (not a Stepper) — the patient-card editing
/// is the bulk of the work and benefits from staying all on screen together.
class ShiftHandoverCreateScreen extends StatelessWidget {
  const ShiftHandoverCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => HandoverCreateViewModel(),
      child: const _CreateView(),
    );
  }
}

class _CreateView extends StatelessWidget {
  const _CreateView();

  static const _shifts = ['morning', 'evening', 'night'];

  Future<void> _submit(BuildContext context, HandoverCreateViewModel viewModel) async {
    final id = await viewModel.submit();
    if (!context.mounted) return;
    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: kCareDark, content: const Text('Handover saved as draft.')));
      Navigator.of(context).pop(id);
    } else if (viewModel.submitError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.submitError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<HandoverCreateViewModel>();

    return CareTheme(child: Scaffold(
      appBar: carePageAppBar(context, 'New Handover'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: viewModel.isSubmitting ? null : () => _submit(context, viewModel),
              style: FilledButton.styleFrom(backgroundColor: kCareDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: viewModel.isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save as draft', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
      body: viewModel.isLoadingMeta
          ? Center(child: CircularProgressIndicator(color: kCare))
          : viewModel.metaError != null
              ? Center(child: Text(viewModel.metaError!, style: const TextStyle(color: kMuted)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    _section('Handover details'),
                    _DropdownField<int>(
                      label: 'Ward',
                      value: viewModel.wardId,
                      items: [for (final w in viewModel.wards) DropdownMenuItem(value: w['id'] as int, child: Text(w['name']?.toString() ?? ''))],
                      onChanged: viewModel.selectWard,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DropdownField<String>(
                            label: 'Current shift',
                            value: viewModel.currentShift,
                            items: [for (final s in _shifts) DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))],
                            onChanged: (v) {
                              if (v != null) {
                                viewModel.currentShift = v;
                                viewModel.touch();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DropdownField<String>(
                            label: 'Next shift',
                            value: viewModel.nextShift,
                            items: [for (final s in _shifts) DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))],
                            onChanged: (v) {
                              if (v != null) {
                                viewModel.nextShift = v;
                                viewModel.touch();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DropdownField<int>(
                      label: 'Incoming nurse',
                      value: viewModel.incomingNurseId,
                      items: [for (final n in viewModel.nurses) DropdownMenuItem(value: n['id'] as int, child: Text(n['name']?.toString() ?? ''))],
                      onChanged: (v) {
                        viewModel.incomingNurseId = v;
                        viewModel.touch();
                      },
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: viewModel.handoverDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 7)),
                          lastDate: DateTime.now().add(const Duration(days: 7)),
                        );
                        if (picked != null) {
                          viewModel.handoverDate = picked;
                          viewModel.touch();
                        }
                      },
                      child: InputDecorator(
                        decoration: careFieldDecoration('Handover date', hint: '', icon: Icons.calendar_today_outlined),
                        child: Text('${viewModel.handoverDate.year}-${viewModel.handoverDate.month.toString().padLeft(2, '0')}-${viewModel.handoverDate.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: viewModel.shiftSummaryController,
                      maxLines: 3,
                      decoration: careFieldDecoration('Shift summary', hint: 'Optional', icon: Icons.notes_outlined),
                    ),
                    const SizedBox(height: 24),
                    _section('Patients (${viewModel.patients.length})'),
                    if (viewModel.wardId == null)
                      const Text('Pick a ward to load its admitted patients.', style: TextStyle(color: kMuted, fontSize: 13))
                    else if (viewModel.isLoadingPatients)
                      Center(child: Padding(padding: const EdgeInsets.all(20), child: CircularProgressIndicator(color: kCare)))
                    else if (viewModel.patientsError != null)
                      Text(viewModel.patientsError!, style: const TextStyle(color: kMuted))
                    else if (viewModel.patients.isEmpty)
                      const Text('No admitted patients in this ward.', style: TextStyle(color: kMuted, fontSize: 13))
                    else
                      for (final card in viewModel.patients) ...[
                        _PatientEditCard(card: card, onChanged: viewModel.touch),
                        const SizedBox(height: 10),
                      ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _section('Tasks'),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: viewModel.addTask,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add task'),
                        ),
                      ],
                    ),
                    for (int i = 0; i < viewModel.tasks.length; i++) ...[
                      _TaskRow(index: i, viewModel: viewModel),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
    ));
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.3)),
      );
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  const _DropdownField({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      decoration: careFieldDecoration(label, hint: '', icon: Icons.arrow_drop_down_circle_outlined),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final int index;
  final HandoverCreateViewModel viewModel;
  const _TaskRow({required this.index, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final task = viewModel.tasks[index];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: kCareBg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: task.descriptionController,
              decoration: const InputDecoration(hintText: 'Task description', border: InputBorder.none, isDense: true),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: kMuted),
            onPressed: () => viewModel.removeTask(index),
          ),
        ],
      ),
    );
  }
}

class _PatientEditCard extends StatefulWidget {
  final HandoverPatientCard card;
  final VoidCallback onChanged;
  const _PatientEditCard({required this.card, required this.onChanged});

  @override
  State<_PatientEditCard> createState() => _PatientEditCardState();
}

class _PatientEditCardState extends State<_PatientEditCard> {
  bool _expanded = false;

  static const _conditions = ['stable', 'improving', 'critical', 'observation'];
  static const _medStatuses = ['completed', 'pending', 'missed'];
  static const _ivStatuses = ['running', 'completed'];

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final card = widget.card;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kCareBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk)),
                      Text('${card.mrn} · Bed ${card.bedNo}', style: const TextStyle(fontSize: 11.5, color: kMuted)),
                    ],
                  ),
                ),
                if (card.vitals != null)
                  Text(
                    '${card.vitals!.bloodPressure ?? '—'} · SpO2 ${card.vitals!.spo2 ?? '—'}',
                    style: const TextStyle(fontSize: 11, color: kMuted),
                  ),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: kMuted),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniDropdown(
                    label: 'Condition',
                    value: card.condition,
                    options: _conditions,
                    onChanged: (v) {
                      setState(() => card.condition = v!);
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniDropdown(
                    label: 'Medication',
                    value: card.medicationStatus ?? card.suggestedMedStatus,
                    options: _medStatuses,
                    onChanged: (v) {
                      setState(() => card.medicationStatus = v);
                      widget.onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MiniDropdown(
              label: 'IV fluid status (optional)',
              value: card.ivFluidStatus,
              options: _ivStatuses,
              nullable: true,
              onChanged: (v) {
                setState(() => card.ivFluidStatus = v);
                widget.onChanged();
              },
            ),
            const SizedBox(height: 10),
            _textField('Doctor instructions', card.doctorInstructions, (v) => card.doctorInstructions = v),
            const SizedBox(height: 8),
            _textField('Pending procedures', card.pendingProcedures, (v) => card.pendingProcedures = v),
            const SizedBox(height: 8),
            _textField('Pending lab reports', card.pendingLabReports, (v) => card.pendingLabReports = v),
            const SizedBox(height: 8),
            _textField('Pending imaging', card.pendingImaging, (v) => card.pendingImaging = v),
            const SizedBox(height: 8),
            _textField('Special notes', card.specialNotes, (v) => card.specialNotes = v),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: card.isHighPriority,
                  activeColor: kCareDark,
                  onChanged: (v) {
                    setState(() => card.isHighPriority = v ?? false);
                    widget.onChanged();
                  },
                ),
                const Text('High priority', style: TextStyle(fontSize: 13, color: kInk)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _textField(String label, String? initial, void Function(String?) onChangedField) {
    return TextFormField(
      initialValue: initial,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      onChanged: (v) {
        onChangedField(v.isEmpty ? null : v);
        widget.onChanged();
      },
    );
  }
}

class _MiniDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final bool nullable;
  final void Function(String?) onChanged;
  const _MiniDropdown({required this.label, required this.value, required this.options, required this.onChanged, this.nullable = false});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      items: [
        if (nullable) const DropdownMenuItem<String>(value: null, child: Text('—')),
        for (final o in options) DropdownMenuItem(value: o, child: Text(o[0].toUpperCase() + o.substring(1))),
      ],
      onChanged: onChanged,
    );
  }
}

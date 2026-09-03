import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/nurse/models/nurse_patient.dart';
import 'package:hms_mobile/features/nurse/models/nursing_note.dart';
import 'package:hms_mobile/features/nurse/viewmodels/nursing_notes_view_model.dart';
import 'package:hms_mobile/features/nurse/widgets/patient_picker.dart';

const _kNoteTypes = ['nursing', 'progress', 'handover', 'assessment', 'discharge_summary'];
const _kShifts = ['morning', 'afternoon', 'night'];
const _kPriorities = ['routine', 'urgent', 'critical'];

String _titleCase(String s) => s.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

class NursingNotesScreen extends StatelessWidget {
  const NursingNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NursingNotesViewModel(),
      child: const _NursingNotesView(),
    );
  }
}

class _NursingNotesView extends StatelessWidget {
  const _NursingNotesView();

  Future<void> _newNote(BuildContext context, NursingNotesViewModel viewModel) async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const _NoteFormScreen()));
    if (created == true) viewModel.load();
  }

  Future<void> _editNote(BuildContext context, NursingNotesViewModel viewModel, NursingNote note) async {
    final updated = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => _NoteFormScreen(existing: note)));
    if (updated == true) viewModel.load();
  }

  Future<void> _deleteNote(BuildContext context, NursingNotesViewModel viewModel, NursingNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Color(0xFFB3261E)))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await viewModel.destroy(note.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Note deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NursingNotesViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, foregroundColor: kInk, elevation: 0, title: const Text('Nursing Notes', style: TextStyle(fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newNote(context, viewModel),
        backgroundColor: kTealDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New note', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        color: kTeal,
        onRefresh: viewModel.load,
        child: _buildBody(context, viewModel),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NursingNotesViewModel viewModel) {
    if (viewModel.isLoading && viewModel.notes.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }
    if (viewModel.loadError != null && viewModel.notes.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }
    if (viewModel.notes.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: const [
        SizedBox(height: 80),
        Icon(Icons.description_outlined, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No nursing notes yet', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk)),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: viewModel.notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final note = viewModel.notes[index];
        return _NoteCard(
          note: note,
          onEdit: () => _editNote(context, viewModel, note),
          onDelete: () => _deleteNote(context, viewModel, note),
        );
      },
    );
  }
}

class _NoteCard extends StatefulWidget {
  final NursingNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _NoteCard({required this.note, required this.onEdit, required this.onDelete});

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _expanded = false;

  static const _priorityColors = {
    'routine': (kMuted, kFieldFill),
    'urgent': (kWarningFg, kWarningBg),
    'critical': (kDangerFg, kDangerBg),
  };

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final (fg, bg) = _priorityColors[note.priority] ?? (kMuted, kFieldFill);
    final isLong = note.note.length > 140;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: fg, width: 3),
          top: const BorderSide(color: kFieldFill),
          right: const BorderSide(color: kFieldFill),
          bottom: const BorderSide(color: kFieldFill),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.patientName ?? 'Patient', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
                    if (note.patientMrn != null) Text(note.patientMrn!, style: const TextStyle(fontSize: 11.5, color: kMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                child: Text(note.priority.toUpperCase(), style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            _MiniChip(label: _titleCase(note.noteType)),
            if (note.shift != null) _MiniChip(label: _titleCase(note.shift!)),
          ]),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: isLong ? () => setState(() => _expanded = !_expanded) : null,
            child: Text(
              note.note,
              maxLines: _expanded ? null : 3,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, color: kInk, height: 1.4),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 13, color: kMuted),
              const SizedBox(width: 4),
              Text(note.notedAt ?? '', style: const TextStyle(fontSize: 11.5, color: kMuted)),
              if (note.writtenByName != null) ...[
                const SizedBox(width: 10),
                const Icon(Icons.person_outline, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Text(note.writtenByName!, style: const TextStyle(fontSize: 11.5, color: kMuted)),
              ],
              const Spacer(),
              IconButton(
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18, color: kMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 14),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFB3261E)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: const TextStyle(fontSize: 10.5, color: kMuted, fontWeight: FontWeight.w600)),
    );
  }
}

class _NoteFormScreen extends StatefulWidget {
  final NursingNote? existing;
  const _NoteFormScreen({this.existing});

  @override
  State<_NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<_NoteFormScreen> {
  final _noteController = TextEditingController();

  NursePatient? _patient;
  String _noteType = 'nursing';
  String? _shift;
  String _priority = 'routine';
  bool _saving = false;
  String? _error;
  String? _patientError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _noteController.text = existing.note;
      _noteType = existing.noteType;
      _shift = existing.shift;
      _priority = existing.priority;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isEdit) {
      setState(() => _patientError = _patient == null ? 'Choose a patient' : null);
      if (_patient == null) {
        setState(() => _error = 'Choose a patient first.');
        return;
      }
    }
    if (_noteController.text.trim().isEmpty) {
      setState(() => _error = 'Write a note before saving.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final viewModel = context.read<NursingNotesViewModel>();
    final error = _isEdit
        ? await viewModel.update(widget.existing!.id, noteType: _noteType, shift: _shift, note: _noteController.text.trim(), priority: _priority)
        : await viewModel.create(patientId: _patient!.id, noteType: _noteType, shift: _shift, note: _noteController.text.trim(), priority: _priority);

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, foregroundColor: kInk, elevation: 0, title: Text(_isEdit ? 'Edit note' : 'New note', style: const TextStyle(fontWeight: FontWeight.w700))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[authErrorBanner(_error!), const SizedBox(height: 16)],
              if (!_isEdit) ...[
                PatientPickerField(value: _patient, errorText: _patientError, onChanged: (p) => setState(() => _patient = p)),
                const SizedBox(height: 16),
              ],
              const Text('Note type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _noteType,
                isExpanded: true,
                decoration: InputDecoration(filled: true, fillColor: kFieldFill, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                items: _kNoteTypes.map((t) => DropdownMenuItem(value: t, child: Text(_titleCase(t)))).toList(),
                onChanged: (v) => setState(() => _noteType = v ?? _noteType),
              ),
              const SizedBox(height: 16),
              const Text('Shift (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _shift,
                isExpanded: true,
                decoration: InputDecoration(filled: true, fillColor: kFieldFill, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                hint: const Text('None'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('None')),
                  ..._kShifts.map((s) => DropdownMenuItem<String?>(value: s, child: Text(_titleCase(s)))),
                ],
                onChanged: (v) => setState(() => _shift = v),
              ),
              const SizedBox(height: 16),
              const Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _kPriorities.map((p) {
                  final selected = _priority == p;
                  return ChoiceChip(label: Text(_titleCase(p)), selected: selected, selectedColor: kMint, onSelected: (_) => setState(() => _priority = p));
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLines: 8,
                maxLength: 5000,
                decoration: authFieldDecoration('Note', hint: 'What should the next shift know?', icon: Icons.notes_outlined),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: kTealDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : Text(_isEdit ? 'Save changes' : 'Add note', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

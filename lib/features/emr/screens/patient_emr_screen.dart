import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_forms.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/emr/models/emr_models.dart';
import 'package:hms_mobile/features/emr/viewmodels/patient_emr_view_model.dart';

/// The patient's medical record: allergies, problem list, history and
/// attachments.
///
/// The web has had this from the start and the app had none of it, so a
/// doctor at the bedside could read a consultation but not find out that
/// the patient reacts to penicillin. That is why severe allergies get a
/// strip of their own above everything else.
class PatientEmrScreen extends StatelessWidget {
  final int patientId;
  final String? patientName;

  const PatientEmrScreen({super.key, required this.patientId, this.patientName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientEmrViewModel(patientId: patientId),
      child: CareTheme(child: _EmrView(fallbackName: patientName)),
    );
  }
}

class _EmrView extends StatelessWidget {
  final String? fallbackName;
  const _EmrView({this.fallbackName});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<PatientEmrViewModel>();
    final record = viewModel.record;

    return Scaffold(
      appBar: carePageAppBar(context, 'Medical record'),
      body: RefreshIndicator(
        color: kCare,
        onRefresh: viewModel.load,
        child: _body(context, viewModel, record),
      ),
    );
  }

  Widget _body(BuildContext context, PatientEmrViewModel viewModel, PatientEmr? record) {
    if (viewModel.isLoading && record == null) return const CareStateView.loading();
    if (viewModel.loadError != null && record == null) return CareStateView.error(viewModel.loadError!);
    if (record == null) {
      return const CareStateView(
        icon: Icons.folder_off_outlined,
        title: 'No record',
        message: 'This patient has no medical record yet.',
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _Header(patient: record.patient, fallbackName: fallbackName),
        if (record.severeAllergies.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SevereStrip(allergies: record.severeAllergies),
        ],
        const SizedBox(height: 18),
        _AllergiesSection(record: record),
        const SizedBox(height: 18),
        _ProblemsSection(record: record),
        const SizedBox(height: 18),
        _RecordsSection(record: record),
        const SizedBox(height: 18),
        _AttachmentsSection(record: record),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final EmrPatient patient;
  final String? fallbackName;
  const _Header({required this.patient, this.fallbackName});

  @override
  Widget build(BuildContext context) {
    final name = patient.name.isNotEmpty ? patient.name : (fallbackName ?? 'Patient');
    final facts = [
      if (patient.mrn.isNotEmpty) patient.mrn,
      if ((patient.gender ?? '').isNotEmpty) patient.gender!,
      if ((patient.bloodGroup ?? '').isNotEmpty) patient.bloodGroup!,
    ];

    return Row(
      children: [
        CareAvatar(name: name, radius: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.titleXl),
              if (facts.isNotEmpty) Text(facts.join('  ·  '), style: CareText.mutedSm),
            ],
          ),
        ),
      ],
    );
  }
}

/// The one thing on this screen somebody may be reading in a hurry.
class _SevereStrip extends StatelessWidget {
  final List<EmrAllergy> allergies;
  const _SevereStrip({required this.allergies});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: kDangerBg,
        borderRadius: BorderRadius.circular(CareRadius.card),
        border: Border.all(color: kDangerFg.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: kDangerFg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Severe allergy', style: CareText.titleSm),
                const SizedBox(height: 2),
                Text(
                  allergies.map((a) => a.allergen).join(', '),
                  style: CareText.bodyMd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Title row with an "Add" button, used by all four sections.
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  final String addLabel;
  const _SectionHeader({required this.title, required this.onAdd, this.addLabel = 'Add'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: CareText.titleLg)),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(addLabel, style: CareText.titleSmMedium),
        ),
      ],
    );
  }
}

class _AllergiesSection extends StatelessWidget {
  final PatientEmr record;
  const _AllergiesSection({required this.record});

  Future<void> _add(BuildContext context) async {
    final viewModel = context.read<PatientEmrViewModel>();
    final values = await careFormSheet(
      context,
      title: 'Add allergy',
      fields: const [
        CareFormField('allergen', 'Allergen', required: true, icon: Icons.coronavirus_outlined),
        CareFormField('type', 'Type',
            options: ['drug', 'food', 'environmental', 'other'], icon: Icons.category_outlined),
        CareFormField('severity', 'Severity',
            options: ['mild', 'moderate', 'severe'], icon: Icons.priority_high_rounded),
        CareFormField('reaction', 'Reaction', maxLines: 2, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.addAllergy(token, viewModel.patientId, values));
    if (context.mounted) careSnack(context, error ?? 'Allergy added.', isError: error != null);
  }

  Future<void> _remove(BuildContext context, EmrAllergy allergy) async {
    final viewModel = context.read<PatientEmrViewModel>();
    final yes = await careConfirm(context,
        title: 'Remove ${allergy.allergen}?',
        message: 'It disappears from this patient\'s record for everyone.',
        confirmLabel: 'Remove');
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.removeAllergy(token, allergy.id));
    if (context.mounted) careSnack(context, error ?? 'Allergy removed.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: 'Allergies', onAdd: () => _add(context)),
        const SizedBox(height: 6),
        if (record.allergies.isEmpty)
          const CareCard(child: Text('No known allergies recorded.', style: CareText.mutedSm))
        else
          CareCard(
            child: Column(
              children: [
                for (final allergy in record.allergies)
                  _Row(
                    title: allergy.allergen,
                    subtitle: [
                      allergy.type,
                      if ((allergy.reaction ?? '').isNotEmpty) allergy.reaction!,
                    ].join(' · '),
                    badge: allergy.severity,
                    badgeFg: allergy.severity == 'severe' ? kDangerFg : kWarningFg,
                    badgeBg: allergy.severity == 'severe' ? kDangerBg : kWarningBg,
                    onRemove: () => _remove(context, allergy),
                    isLast: allergy == record.allergies.last,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProblemsSection extends StatelessWidget {
  final PatientEmr record;
  const _ProblemsSection({required this.record});

  Future<void> _add(BuildContext context) async {
    final viewModel = context.read<PatientEmrViewModel>();
    final values = await careFormSheet(
      context,
      title: 'Add problem',
      fields: const [
        CareFormField('problem_name', 'Problem', required: true, icon: Icons.sick_outlined),
        CareFormField('status', 'Status', options: ['active', 'chronic', 'resolved'], icon: Icons.flag_outlined),
        CareFormField('onset_date', 'Onset date (YYYY-MM-DD)', icon: Icons.event_outlined),
        CareFormField('notes', 'Notes', maxLines: 2, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.addProblem(token, viewModel.patientId, values));
    if (context.mounted) careSnack(context, error ?? 'Problem added.', isError: error != null);
  }

  Future<void> _edit(BuildContext context, EmrProblem problem) async {
    final viewModel = context.read<PatientEmrViewModel>();
    final values = await careFormSheet(
      context,
      title: problem.problemName,
      submitLabel: 'Update',
      fields: [
        CareFormField('status', 'Status',
            initial: problem.status, options: const ['active', 'chronic', 'resolved'], icon: Icons.flag_outlined),
        CareFormField('notes', 'Notes', initial: problem.notes, maxLines: 3, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.updateProblem(token, problem.id, values));
    if (context.mounted) careSnack(context, error ?? 'Problem updated.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: 'Problem list', onAdd: () => _add(context)),
        const SizedBox(height: 6),
        if (record.problems.isEmpty)
          const CareCard(child: Text('Nothing on the problem list.', style: CareText.mutedSm))
        else
          CareCard(
            child: Column(
              children: [
                for (final problem in record.problems)
                  _Row(
                    title: problem.problemName,
                    subtitle: [
                      if ((problem.onsetDate ?? '').isNotEmpty) 'since ${problem.onsetDate}',
                      if ((problem.notes ?? '').isNotEmpty) problem.notes!,
                    ].join(' · '),
                    badge: problem.status,
                    badgeFg: problem.status == 'resolved' ? kSuccessFg : kCareDark,
                    badgeBg: problem.status == 'resolved' ? kSuccessBg : kCareSoft,
                    onTap: () => _edit(context, problem),
                    isLast: problem == record.problems.last,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecordsSection extends StatelessWidget {
  final PatientEmr record;
  const _RecordsSection({required this.record});

  Future<void> _add(BuildContext context) async {
    final viewModel = context.read<PatientEmrViewModel>();
    final today = DateTime.now().toIso8601String().split('T').first;
    final values = await careFormSheet(
      context,
      title: 'Add to history',
      fields: [
        const CareFormField('record_type', 'Type',
            options: ['Consultation', 'Procedure', 'Surgery', 'Discharge summary', 'Immunisation', 'Other'],
            icon: Icons.description_outlined),
        CareFormField('record_date', 'Date', initial: today, required: true, icon: Icons.event_outlined),
        const CareFormField('description', 'What happened', required: true, maxLines: 3, icon: Icons.notes_outlined),
        const CareFormField('notes', 'Notes', maxLines: 2, icon: Icons.sticky_note_2_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.addRecord(token, viewModel.patientId, values));
    if (context.mounted) careSnack(context, error ?? 'Added to history.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: 'History', onAdd: () => _add(context)),
        const SizedBox(height: 6),
        if (record.records.isEmpty)
          const CareCard(child: Text('No history recorded yet.', style: CareText.mutedSm))
        else
          CareCard(
            child: Column(
              children: [
                for (final item in record.records)
                  _Row(
                    title: item.recordType,
                    subtitle: [
                      item.description,
                      if ((item.doctorName ?? '').isNotEmpty) item.doctorName!,
                    ].join(' · '),
                    badge: item.recordDate,
                    badgeFg: kCareDark,
                    badgeBg: kCareSoft,
                    isLast: item == record.records.last,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AttachmentsSection extends StatelessWidget {
  final PatientEmr record;
  const _AttachmentsSection({required this.record});

  Future<void> _add(BuildContext context) async {
    final viewModel = context.read<PatientEmrViewModel>();

    // Photos only from here: the server also takes PDFs and documents,
    // but a photo of a wound or a paper report is what this is for --
    // taken on the spot as often as picked from the roll.
    final source = await careImageSource(context);
    if (source == null || !context.mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      // Larger than a profile picture: this may be a paper report
      // that has to stay readable. Still well under the 2MB the
      // server accepts.
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return;

    final bytes = await picked.readAsBytes();
    if (!context.mounted) return;

    final error = await viewModel.uploadPhoto(bytes: bytes, filename: picked.name);
    if (context.mounted) careSnack(context, error ?? 'Photo attached.', isError: error != null);
  }

  Future<void> _remove(BuildContext context, EmrAttachment attachment) async {
    final viewModel = context.read<PatientEmrViewModel>();
    final yes = await careConfirm(context,
        title: 'Remove ${attachment.fileName}?',
        message: 'The file is deleted from the server.',
        confirmLabel: 'Remove');
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.removeAttachment(token, attachment.id));
    if (context.mounted) careSnack(context, error ?? 'Attachment removed.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: 'Attachments', onAdd: () => _add(context), addLabel: 'Photo'),
        const SizedBox(height: 6),
        if (record.attachments.isEmpty)
          const CareCard(child: Text('No files attached.', style: CareText.mutedSm))
        else
          CareCard(
            child: Column(
              children: [
                for (final attachment in record.attachments)
                  _Row(
                    title: attachment.fileName,
                    subtitle: [
                      if ((attachment.fileSize ?? '').isNotEmpty) attachment.fileSize!,
                      if ((attachment.uploadedBy ?? '').isNotEmpty) 'by ${attachment.uploadedBy}',
                    ].join(' · '),
                    leading: attachment.isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
                    onRemove: () => _remove(context, attachment),
                    isLast: attachment == record.attachments.last,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One line inside a section card.
class _Row extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeFg;
  final Color? badgeBg;
  final IconData? leading;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool isLast;

  const _Row({
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeFg,
    this.badgeBg,
    this.leading,
    this.onTap,
    this.onRemove,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) ...[
                  Icon(leading, size: 20, color: kCare),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: CareText.titleMd),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: CareText.mutedSm),
                      ],
                    ],
                  ),
                ),
                if ((badge ?? '').isNotEmpty)
                  CareChip(label: badge!, bg: badgeBg ?? kCareSoft, fg: badgeFg ?? kCareDark),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded, size: 18, color: kCareHint),
                    tooltip: 'Remove',
                  ),
                if (onTap != null) const Icon(Icons.chevron_right_rounded, color: kCareHint),
              ],
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, color: kCareBorder),
      ],
    );
  }
}

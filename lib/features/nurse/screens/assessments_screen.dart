import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/assessment_api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_forms.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/nurse/models/nursing_assessment.dart';

class AssessmentsViewModel extends ChangeNotifier {
  /// Set to show one patient's history instead of the ward's latest.
  final int? patientId;
  final AssessmentApiService api;
  final AuthStorage authStorage;

  AssessmentsViewModel({this.patientId, AssessmentApiService? api, AuthStorage? authStorage})
      : api = api ?? AssessmentApiService(),
        authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<NursingAssessment> rows = [];
  int needsAttention = 0;

  Future<String> _token() async => (await authStorage.readToken())!;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      await guardNetworkErrors(() async {
        final result = await api.assessments(await _token(), patientId: patientId);
        rows = result.rows;
        needsAttention = result.needsAttention;
      });
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> mutate(Future<void> Function(AssessmentApiService api, String token) action) async {
    try {
      await guardNetworkErrors(() async => action(api, await _token()));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

/// Fall risk, pain, pressure-sore risk and the early warning score.
///
/// These four were being written into free-text nursing notes, where
/// nothing can trend them or flag the dangerous ones. Here the list
/// leads with the patients who need attention.
class AssessmentsScreen extends StatelessWidget {
  final int? patientId;
  final String? patientName;

  const AssessmentsScreen({super.key, this.patientId, this.patientName});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AssessmentsViewModel(patientId: patientId),
        child: CareTheme(child: _AssessmentsView(patientName: patientName)),
      );
}

class _AssessmentsView extends StatelessWidget {
  final String? patientName;
  const _AssessmentsView({this.patientName});

  Future<void> _record(BuildContext context, AssessmentsViewModel viewModel) async {
    final values = await careFormSheet(
      context,
      title: 'Record assessment',
      submitLabel: 'Save',
      fields: const [
        CareFormField('fall_risk_score', 'Fall risk (Morse 0-125)',
            keyboard: TextInputType.number, icon: Icons.elderly_outlined),
        CareFormField('ews_score', 'Early warning score (0-20)',
            keyboard: TextInputType.number, icon: Icons.monitor_heart_outlined),
        CareFormField('pain_score', 'Pain (0-10)', keyboard: TextInputType.number, icon: Icons.sentiment_dissatisfied_outlined),
        CareFormField('braden_score', 'Braden (6-23, lower is worse)',
            keyboard: TextInputType.number, icon: Icons.bed_outlined),
        CareFormField('notes', 'Notes', maxLines: 3, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.record(token, viewModel.patientId!, values));
    if (context.mounted) careSnack(context, error ?? 'Assessment saved.', isError: error != null);
  }

  Future<void> _remove(BuildContext context, AssessmentsViewModel viewModel, NursingAssessment row) async {
    final yes = await careConfirm(context,
        title: 'Remove this assessment?',
        message: 'It disappears from the patient\'s record.',
        confirmLabel: 'Remove');
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.remove(token, row.id));
    if (context.mounted) careSnack(context, error ?? 'Assessment removed.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AssessmentsViewModel>();
    final forOnePatient = viewModel.patientId != null;

    return Scaffold(
      appBar: carePageAppBar(context, patientName == null ? 'Assessments' : 'Assessments — $patientName'),
      // Recording needs a patient, so the button only appears when the
      // screen was opened from one.
      floatingActionButton: forOnePatient
          ? FloatingActionButton.extended(
              onPressed: () => _record(context, viewModel),
              backgroundColor: kCareDark,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Record', style: CareText.onCareBold),
            )
          : null,
      body: RefreshIndicator(
        color: kCare,
        onRefresh: viewModel.load,
        child: _body(context, viewModel, forOnePatient),
      ),
    );
  }

  Widget _body(BuildContext context, AssessmentsViewModel viewModel, bool forOnePatient) {
    if (viewModel.isLoading && viewModel.rows.isEmpty) return const CareStateView.loading();
    if (viewModel.loadError != null && viewModel.rows.isEmpty) return CareStateView.error(viewModel.loadError!);
    if (viewModel.rows.isEmpty) {
      return CareStateView(
        icon: Icons.assignment_outlined,
        title: 'No assessments yet',
        message: forOnePatient
            ? 'Tap Record to score fall risk, pain, pressure-sore risk or the early warning score.'
            : 'Open a patient and record the first one.',
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 16, 20, forOnePatient ? 90 : 28),
      children: [
        if (viewModel.needsAttention > 0) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: kDangerBg,
              borderRadius: BorderRadius.circular(CareRadius.card),
              border: Border.all(color: kDangerFg.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.priority_high_rounded, color: kDangerFg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    viewModel.needsAttention == 1
                        ? '1 assessment needs attention'
                        : '${viewModel.needsAttention} assessments need attention',
                    style: CareText.titleSm,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        for (final row in viewModel.rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              forOnePatient ? (row.assessedAt ?? '') : (row.patientName ?? 'Patient'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CareText.titleMd,
                            ),
                            Text(
                              forOnePatient
                                  ? (row.assessedBy ?? '')
                                  : [row.patientMrn, row.assessedAt].where((s) => (s ?? '').isNotEmpty).join(' · '),
                              style: CareText.mutedSm,
                            ),
                          ],
                        ),
                      ),
                      if (row.needsAttention)
                        const CareChip(label: 'attention', bg: kDangerBg, fg: kDangerFg, icon: Icons.warning_amber_rounded),
                      IconButton(
                        onPressed: () => _remove(context, viewModel, row),
                        icon: const Icon(Icons.close_rounded, size: 18, color: kCareHint),
                        tooltip: 'Remove',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final score in row.scores)
                        _ScorePill(label: score.label, value: score.value, band: score.band),
                    ],
                  ),
                  if ((row.notes ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(row.notes!, style: CareText.bodyMdMuted),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A score with the band it falls in, coloured by how urgent it is.
class _ScorePill extends StatelessWidget {
  final String label;
  final String value;
  final String? band;

  const _ScorePill({required this.label, required this.value, this.band});

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = switch (band) {
      'high' || 'severe' => (kDangerFg, kDangerBg),
      'medium' || 'moderate' => (kWarningFg, kWarningBg),
      'low' || 'mild' || 'none' => (kSuccessFg, kSuccessBg),
      _ => (kCareDark, kCareSoft),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(CareRadius.control)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: CareText.mutedXs),
          Text(
            band == null ? value : '$value · $band',
            style: CareText.titleSm.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

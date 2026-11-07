import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/features/patient/services/patient_api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/patient/models/health_record.dart';

class HealthRecordsViewModel extends ChangeNotifier {
  final PatientApiService api;
  final AuthStorage authStorage;

  HealthRecordsViewModel({PatientApiService? api, AuthStorage? authStorage})
      : api = api ?? PatientApiService(),
        authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  HealthRecord? record;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      await guardNetworkErrors(() async {
        final token = await authStorage.readToken();
        record = await api.getHealthRecords(token!);
      });
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

/// What the hospital holds about you.
///
/// Appointments, prescriptions, lab results and bills already had their
/// own screens. This is the clinical side: what a doctor found, what
/// you react to, and what happened while you were admitted.
class HealthRecordsScreen extends StatelessWidget {
  const HealthRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => HealthRecordsViewModel(),
        child: const CareTheme(child: _RecordsView()),
      );
}

class _RecordsView extends StatelessWidget {
  const _RecordsView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<HealthRecordsViewModel>();
    final record = viewModel.record;

    return Scaffold(
      appBar: carePageAppBar(context, 'My health records'),
      body: RefreshIndicator(
        color: kCare,
        onRefresh: viewModel.load,
        child: _body(context, viewModel, record),
      ),
    );
  }

  Widget _body(BuildContext context, HealthRecordsViewModel viewModel, HealthRecord? record) {
    if (viewModel.isLoading && record == null) return const CareStateView.loading();
    if (viewModel.loadError != null && record == null) return CareStateView.error(viewModel.loadError!);
    if (record == null) return const CareStateView.loading();

    if (record.isEmpty) {
      return const CareStateView(
        icon: Icons.folder_open_outlined,
        title: 'Nothing recorded yet',
        message: 'Once you have been seen at the hospital, your consultations and results appear here.',
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        CareCard(
          child: Row(
            children: [
              CareAvatar(name: record.name, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.titleXl),
                    Text(
                      [record.mrn, record.gender ?? '', record.bloodGroup ?? '']
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      style: CareText.mutedSm,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (record.allergies.isNotEmpty) ...[
          const SizedBox(height: 18),
          const CareSectionTitle(title: 'Allergies'),
          const SizedBox(height: 8),
          // First, and in warning colours: this is the part a patient is
          // asked to repeat at every desk.
          for (final allergy in record.allergies)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: allergy.severity == 'severe' ? kDangerBg : kWarningBg,
                  borderRadius: BorderRadius.circular(CareRadius.card),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: allergy.severity == 'severe' ? kDangerFg : kWarningFg),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${allergy.allergen} · ${allergy.severity}', style: CareText.titleSm),
                          if ((allergy.reaction ?? '').isNotEmpty)
                            Text(allergy.reaction!, style: CareText.mutedSm),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        if (record.problems.isNotEmpty) ...[
          const SizedBox(height: 18),
          const CareSectionTitle(title: 'Ongoing conditions'),
          const SizedBox(height: 8),
          CareCard(
            child: Column(
              children: [
                for (final problem in record.problems)
                  _Line(
                    title: problem.problemName,
                    subtitle: (problem.onsetDate ?? '').isEmpty ? '' : 'since ${problem.onsetDate}',
                    badge: problem.status,
                    isLast: problem == record.problems.last,
                  ),
              ],
            ),
          ),
        ],
        if (record.consultations.isNotEmpty) ...[
          const SizedBox(height: 18),
          const CareSectionTitle(title: 'Consultations'),
          const SizedBox(height: 8),
          for (final consultation in record.consultations)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            consultation.diagnosis?.isNotEmpty == true
                                ? consultation.diagnosis!
                                : (consultation.chiefComplaint ?? 'Consultation'),
                            style: CareText.titleMd,
                          ),
                        ),
                        if ((consultation.date ?? '').isNotEmpty)
                          CareChip(label: consultation.date!, bg: kCareSoft, fg: kCareDark),
                      ],
                    ),
                    if ((consultation.doctorName ?? '').isNotEmpty)
                      Text(consultation.doctorName!, style: CareText.mutedSm),
                    if ((consultation.treatmentPlan ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(consultation.treatmentPlan!, style: CareText.bodyMdMuted),
                    ],
                  ],
                ),
              ),
            ),
        ],
        if (record.stays.isNotEmpty) ...[
          const SizedBox(height: 18),
          const CareSectionTitle(title: 'Hospital stays'),
          const SizedBox(height: 8),
          for (final stay in record.stays)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(stay.span, style: CareText.titleMd)),
                        CareChip.status(stay.status),
                      ],
                    ),
                    Text(
                      [stay.admissionNo, stay.wardName ?? '', stay.doctorName ?? '']
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      style: CareText.mutedSm,
                    ),
                    if ((stay.reason ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(stay.reason!, style: CareText.bodyMdMuted),
                    ],
                    if ((stay.dischargeNotes ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: kCareNeutralBg,
                          borderRadius: BorderRadius.circular(CareRadius.control),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('On discharge', style: CareText.mutedXs),
                            Text(stay.dischargeNotes!, style: CareText.bodyMd),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
        if (record.vitals.isNotEmpty) ...[
          const SizedBox(height: 18),
          const CareSectionTitle(title: 'Vitals'),
          const SizedBox(height: 8),
          CareCard(
            child: Column(
              children: [
                for (final reading in record.vitals)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reading.recordedAt ?? '', style: CareText.mutedXs),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 16,
                          runSpacing: 6,
                          children: [
                            for (final value in reading.readings)
                              Text('${value.label} ${value.value}', style: CareText.titleSm),
                          ],
                        ),
                        if (reading != record.vitals.last) ...[
                          const SizedBox(height: 8),
                          Divider(height: 1, color: kCareBorder),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final bool isLast;

  const _Line({required this.title, required this.subtitle, required this.badge, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: CareText.titleMd),
                    if (subtitle.isNotEmpty) Text(subtitle, style: CareText.mutedSm),
                  ],
                ),
              ),
              CareChip(
                label: badge,
                bg: badge == 'resolved' ? kSuccessBg : kCareSoft,
                fg: badge == 'resolved' ? kSuccessFg : kCareDark,
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: kCareBorder),
      ],
    );
  }
}

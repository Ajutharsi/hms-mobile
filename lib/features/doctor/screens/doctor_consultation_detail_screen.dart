import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/doctor/models/doctor_models.dart';
import 'package:hms_mobile/features/doctor/screens/doctor_appointment_detail_screen.dart'
    show DoctorConsultationCard, DoctorVitalsCard;
import 'package:hms_mobile/features/doctor/viewmodels/doctor_view_models.dart';

/// One past consultation on its own page.
///
/// `GET /doctor/consultations/{id}` was already serving this and nothing
/// called it: the patient's history listed consultations as flat blocks,
/// so the treatment plan, the notes and the prescription written that day
/// were only reachable through the appointment that created them.
class DoctorConsultationDetailScreen extends StatelessWidget {
  final int consultationId;
  const DoctorConsultationDetailScreen({super.key, required this.consultationId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorConsultationDetailViewModel(consultationId: consultationId),
      child: const CareTheme(child: _ConsultationDetailView()),
    );
  }
}

class _ConsultationDetailView extends StatelessWidget {
  const _ConsultationDetailView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<DoctorConsultationDetailViewModel>();
    final consultation = viewModel.consultation;

    return Scaffold(
      appBar: carePageAppBar(context, 'Consultation'),
      body: RefreshIndicator(
        color: kCare,
        onRefresh: viewModel.load,
        child: switch ((viewModel.isLoading, viewModel.loadError, consultation)) {
          (true, _, null) => const CareStateView.loading(),
          (_, final String error, null) => CareStateView.error(error),
          (_, _, null) => const CareStateView(
              icon: Icons.description_outlined,
              title: 'Consultation not found',
              message: 'It may have been removed since this list was loaded.',
            ),
          (_, _, final DoctorConsultation record) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                _Heading(consultation: record),
                if (record.vitals.recordedAt != null ||
                    (record.vitals.bloodPressure ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const CareSectionTitle(title: 'Vitals that day'),
                  const SizedBox(height: 8),
                  DoctorVitalsCard(vitals: record.vitals),
                ],
                const SizedBox(height: 16),
                const CareSectionTitle(title: 'Record'),
                const SizedBox(height: 8),
                // Reused from the appointment screen, so a consultation
                // reads the same wherever it is opened from -- including
                // the "write prescription" route when there is none yet.
                DoctorConsultationCard(consultation: record, onChanged: viewModel.load),
              ],
            ),
        },
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final DoctorConsultation consultation;
  const _Heading({required this.consultation});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CareAvatar(name: consultation.patientName ?? 'Patient', radius: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                consultation.patientName ?? 'Patient',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CareText.titleXl,
              ),
              if ((consultation.date ?? '').isNotEmpty)
                Text(consultation.date!, style: CareText.mutedSm),
            ],
          ),
        ),
      ],
    );
  }
}

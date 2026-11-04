import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/models/date_display.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/doctor/models/doctor_models.dart';
import 'package:hms_mobile/features/doctor/screens/consultation_form_screen.dart';
import 'package:hms_mobile/features/doctor/screens/doctor_patient_detail_screen.dart';
import 'package:hms_mobile/features/doctor/screens/prescription_form_screen.dart';
import 'package:hms_mobile/features/doctor/viewmodels/doctor_view_models.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';

/// One visit: who is being seen, the latest vitals nursing recorded, and
/// the consultation — either written already, or the button to write it.
class DoctorAppointmentDetailScreen extends StatelessWidget {
  final int appointmentId;
  const DoctorAppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorAppointmentDetailViewModel(appointmentId: appointmentId),
      child: const CareTheme(child: _DetailView()),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<DoctorAppointmentDetailViewModel>();

    return Scaffold(
      appBar: carePageAppBar(context, 'Visit'),
      body: RefreshIndicator(
        color: kCare,
        onRefresh: viewModel.load,
        child: _buildBody(context, viewModel),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DoctorAppointmentDetailViewModel viewModel) {
    if (viewModel.isLoading && viewModel.detail == null) return const CareStateView.loading();
    if (viewModel.loadError != null && viewModel.detail == null) return CareStateView.error(viewModel.loadError!);

    final detail = viewModel.detail!;
    final appointment = detail.appointment;
    final patient = detail.patient;
    final consultation = detail.consultation;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        CareCard(
          onTap: patient == null
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DoctorPatientDetailScreen(patientId: patient.id, name: patient.name),
                  )),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CareAvatar(name: patient?.name ?? appointment.patientName ?? 'Patient', imageUrl: patient?.photoUrl, radius: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient?.name ?? appointment.patientName ?? 'Patient',
                            style: CareText.titleXl),
                        const SizedBox(height: 2),
                        Text(
                          [
                            patient?.mrn ?? appointment.patientMrn ?? '',
                            if ((patient?.gender ?? '').isNotEmpty) patient!.gender!,
                            if (patient?.age != null) '${patient!.age} yrs',
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: CareText.mutedSm,
                        ),
                      ],
                    ),
                  ),
                  if (patient != null) const Icon(Icons.chevron_right_rounded, color: kCareChevron),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  CareChip(label: appointment.date, bg: kCarePinkBg, fg: kCarePinkFg, icon: Icons.calendar_today_rounded),
                  if (appointment.time.isNotEmpty)
                    CareChip(label: appointment.time, bg: kCareSoft, fg: kCareDark, icon: Icons.access_time_rounded),
                  CareChip.status(appointment.status),
                  if (appointment.type.isNotEmpty)
                    CareChip(label: appointment.type.toUpperCase(), bg: kInfoBg, fg: kInfoFg),
                ],
              ),
              if ((appointment.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(appointment.notes!, style: CareText.mutedSmItalic),
              ],
            ],
          ),
        ),
        if (detail.latestVitals != null && !detail.latestVitals!.isEmpty) ...[
          const SizedBox(height: 18),
          const CareSectionTitle(title: 'Latest vitals'),
          const SizedBox(height: 10),
          _VitalsCard(vitals: detail.latestVitals!),
        ],
        const SizedBox(height: 18),
        CareSectionTitle(title: consultation == null ? 'Consultation' : 'Consultation notes'),
        const SizedBox(height: 10),
        if (consultation == null)
          CareCard(
            child: Column(
              children: [
                const Row(
                  children: [
                    CareIconBox(icon: Icons.edit_note_rounded, size: 44),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Not consulted yet', style: CareText.titleLg),
                          SizedBox(height: 2),
                          Text('Write the complaint, diagnosis and plan.', style: CareText.mutedSm),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                CarePrimaryButton(
                  label: 'Start consultation',
                  icon: Icons.medical_services_rounded,
                  onPressed: () async {
                    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
                      builder: (_) => ConsultationFormScreen(
                        appointmentId: viewModel.appointmentId,
                        patientName: patient?.name ?? appointment.patientName ?? 'Patient',
                        prefillVitals: detail.latestVitals,
                      ),
                    ));
                    if (saved == true) viewModel.load();
                  },
                ),
              ],
            ),
          )
        else
          _ConsultationCard(consultation: consultation, onChanged: viewModel.load),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _VitalsCard extends StatelessWidget {
  final VitalsSnapshot vitals;
  const _VitalsCard({required this.vitals});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final entries = <(IconData, String, String?)>[
      (Icons.monitor_heart_rounded, 'BP', vitals.bloodPressure),
      (Icons.thermostat_rounded, 'Temp', vitals.temperature),
      (Icons.favorite_rounded, 'Pulse', vitals.pulseRate),
      (Icons.air_rounded, 'SpO₂', vitals.spo2),
    ].where((e) => (e.$3 ?? '').isNotEmpty).toList();

    return CareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 18,
            runSpacing: 12,
            children: [
              for (final entry in entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(entry.$1, size: 17, color: kCare),
                    const SizedBox(width: 6),
                    Text('${entry.$2}: ', style: CareText.mutedSm),
                    Text(entry.$3!, style: CareText.titleMd),
                  ],
                ),
            ],
          ),
          if ((vitals.recordedAt ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Recorded ${shortDateTime(vitals.recordedAt)}', style: CareText.mutedXs),
          ],
        ],
      ),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  final DoctorConsultation consultation;
  final VoidCallback onChanged;

  const _ConsultationCard({required this.consultation, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final prescription = consultation.prescription;

    Widget row(String label, String? value) {
      if ((value ?? '').isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: CareText.xs, color: kMuted, fontWeight: CareText.bold)),
            const SizedBox(height: 2),
            Text(value!, style: const TextStyle(fontSize: CareText.md, color: kInk)),
          ],
        ),
      );
    }

    return Column(
      children: [
        CareCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              row('Chief complaint', consultation.chiefComplaint),
              row('Diagnosis', consultation.diagnosis),
              if ((consultation.icd10Code ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  // Align, or the stretching Column would pull the chip
                  // across the whole card.
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CareChip(label: 'ICD-10 ${consultation.icd10Code}', bg: kCareSoft, fg: kCareDark),
                  ),
                ),
              row('Treatment plan', consultation.treatmentPlan),
              row('Notes', consultation.notes),
              if (!consultation.vitals.isEmpty) _VitalsCard(vitals: consultation.vitals),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const CareSectionTitle(title: 'Prescription'),
        const SizedBox(height: 10),
        if (prescription == null)
          CareCard(
            child: Column(
              children: [
                const Row(
                  children: [
                    CareIconBox(icon: Icons.medication_rounded, size: 44),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No prescription yet', style: CareText.titleLg),
                          SizedBox(height: 2),
                          Text('The pharmacy dispenses against this.', style: CareText.mutedSm),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                CarePrimaryButton(
                  label: 'Write prescription',
                  icon: Icons.medication_rounded,
                  onPressed: () async {
                    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
                      builder: (_) => PrescriptionFormScreen(
                        consultationId: consultation.id,
                        patientName: consultation.patientName ?? 'Patient',
                      ),
                    ));
                    if (saved == true) onChanged();
                  },
                ),
              ],
            ),
          )
        else
          CareCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(prescription.prescriptionNo,
                          style: CareText.titleLg),
                    ),
                    CareChip(
                      label: '${prescription.items.length} medicine${prescription.items.length == 1 ? '' : 's'}',
                      bg: kCareSoft,
                      fg: kCareDark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final item in prescription.items)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kCareBg, borderRadius: BorderRadius.circular(CareRadius.field)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CareIconBox(icon: Icons.medication_rounded, size: 34),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.medicineName, style: CareText.titleMd),
                              const SizedBox(height: 4),
                              Text(
                                [item.dosage, item.frequency, item.duration, if ((item.route ?? '').isNotEmpty) item.route!]
                                    .where((s) => s.isNotEmpty)
                                    .join(' · '),
                                style: CareText.mutedSm,
                              ),
                              if ((item.instructions ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(item.instructions!, style: CareText.mutedSm),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if ((prescription.notes ?? '').isNotEmpty)
                  Text(prescription.notes!, style: const TextStyle(fontSize: CareText.sm, color: kMuted, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
      ],
    );
  }
}

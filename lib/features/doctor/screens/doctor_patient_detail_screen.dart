import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/doctor/screens/doctor_appointment_detail_screen.dart';
import 'package:hms_mobile/features/doctor/viewmodels/doctor_view_models.dart';

/// A patient as the doctor sees them: who they are, the latest vitals, and
/// the history of what this doctor has written for them.
class DoctorPatientDetailScreen extends StatelessWidget {
  final int patientId;
  final String name;

  const DoctorPatientDetailScreen({super.key, required this.patientId, required this.name});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorPatientDetailViewModel(patientId: patientId),
      child: CareTheme(child: _PatientDetailView(name: name)),
    );
  }
}

class _PatientDetailView extends StatelessWidget {
  final String name;
  const _PatientDetailView({required this.name});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<DoctorPatientDetailViewModel>();

    return Scaffold(
      appBar: carePageAppBar(context, name),
      body: RefreshIndicator(
        color: kCare,
        onRefresh: viewModel.load,
        child: _buildBody(context, viewModel),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DoctorPatientDetailViewModel viewModel) {
    if (viewModel.isLoading && viewModel.detail == null) return const CareStateView.loading();
    if (viewModel.loadError != null && viewModel.detail == null) return CareStateView.error(viewModel.loadError!);

    final detail = viewModel.detail!;
    final patient = detail.patient;
    final vitals = detail.latestVitals;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        CareCard(
          child: Column(
            children: [
              Row(
                children: [
                  CareAvatar(name: patient.name, imageUrl: patient.photoUrl, radius: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient.name, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: kInk)),
                        const SizedBox(height: 2),
                        Text(patient.mrn, style: const TextStyle(fontSize: 12.5, color: kMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if ((patient.gender ?? '').isNotEmpty) CareChip(label: patient.gender!, bg: kCareSoft, fg: kCareDark),
                  if (patient.age != null) CareChip(label: '${patient.age} yrs', bg: kCareSoft, fg: kCareDark),
                  if ((patient.bloodGroup ?? '').isNotEmpty)
                    CareChip(label: patient.bloodGroup!, bg: kCarePinkBg, fg: kCarePinkFg, icon: Icons.water_drop_rounded),
                  if ((patient.phone ?? '').isNotEmpty)
                    CareChip(label: patient.phone!, bg: kInfoBg, fg: kInfoFg, icon: Icons.phone_rounded),
                  if ((patient.status ?? '').isNotEmpty) CareChip.status(patient.status!),
                ],
              ),
            ],
          ),
        ),
        if (vitals != null && !vitals.isEmpty) ...[
          const SizedBox(height: 18),
          const CareSectionTitle(title: 'Latest vitals'),
          const SizedBox(height: 10),
          CareCard(
            child: Wrap(
              spacing: 18,
              runSpacing: 12,
              children: [
                for (final entry in <(IconData, String, String?)>[
                  (Icons.monitor_heart_rounded, 'BP', vitals.bloodPressure),
                  (Icons.thermostat_rounded, 'Temp', vitals.temperature),
                  (Icons.favorite_rounded, 'Pulse', vitals.pulseRate),
                  (Icons.air_rounded, 'SpO₂', vitals.spo2),
                ].where((e) => (e.$3 ?? '').isNotEmpty))
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(entry.$1, size: 17, color: kCare),
                      const SizedBox(width: 6),
                      Text('${entry.$2}: ', style: const TextStyle(fontSize: 12.5, color: kMuted)),
                      Text(entry.$3!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
                    ],
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        const CareSectionTitle(title: 'My consultations'),
        const SizedBox(height: 10),
        if (detail.consultations.isEmpty)
          const CareCard(
            child: Text('You have not consulted this patient yet.', style: TextStyle(fontSize: 13, color: kMuted)),
          )
        else
          CareCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final consultation in detail.consultations) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(consultation.chiefComplaint ?? 'Consultation',
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kInk)),
                          ),
                          if ((consultation.date ?? '').isNotEmpty)
                            CareChip(label: consultation.date!, bg: kCarePinkBg, fg: kCarePinkFg),
                        ],
                      ),
                      if ((consultation.diagnosis ?? '').isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(consultation.diagnosis!, style: const TextStyle(fontSize: 12.5, color: kMuted)),
                      ],
                    ],
                  ),
                  if (consultation != detail.consultations.last)
                    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: kCareBorder)),
                ],
              ],
            ),
          ),
        const SizedBox(height: 18),
        const CareSectionTitle(title: 'Visits'),
        const SizedBox(height: 10),
        if (detail.appointments.isEmpty)
          const CareCard(child: Text('No visits with you yet.', style: TextStyle(fontSize: 13, color: kMuted)))
        else
          for (final appointment in detail.appointments) ...[
            CareCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => DoctorAppointmentDetailScreen(appointmentId: appointment.id),
              )),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const CareIconBox(icon: Icons.calendar_month_rounded, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${appointment.date}  ${appointment.time}'.trim(),
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kInk)),
                        if (appointment.type.isNotEmpty)
                          Text(appointment.type.toUpperCase(), style: const TextStyle(fontSize: 11.5, color: kMuted)),
                      ],
                    ),
                  ),
                  CareChip.status(appointment.status),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

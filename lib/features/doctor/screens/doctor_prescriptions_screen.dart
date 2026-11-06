import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/doctor/models/doctor_models.dart';
import 'package:hms_mobile/features/doctor/viewmodels/doctor_view_models.dart';

/// Everything this doctor has prescribed, newest first.
///
/// The web has the same list; `GET /doctor/prescriptions` was already
/// serving it and no screen called it, so a doctor could only see a
/// prescription by reopening the consultation that created it.
class DoctorPrescriptionsScreen extends StatelessWidget {
  /// Set to show one patient's prescriptions instead of all of them.
  final int? patientId;
  final String? patientName;

  const DoctorPrescriptionsScreen({super.key, this.patientId, this.patientName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorPrescriptionsViewModel(patientId: patientId),
      child: CareTheme(child: _PrescriptionsView(patientName: patientName)),
    );
  }
}

class _PrescriptionsView extends StatelessWidget {
  final String? patientName;
  const _PrescriptionsView({this.patientName});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<DoctorPrescriptionsViewModel>();

    return Scaffold(
      appBar: carePageAppBar(context, patientName == null ? 'Prescriptions' : 'Prescriptions — $patientName'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: TextField(
              onChanged: viewModel.search,
              decoration: careFieldDecoration(
                'Search',
                hint: 'Patient, number or medicine',
                icon: Icons.search_rounded,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kCare,
              onRefresh: viewModel.load,
              child: _buildList(viewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(DoctorPrescriptionsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.all.isEmpty) return const CareStateView.loading();
    if (viewModel.loadError != null && viewModel.all.isEmpty) return CareStateView.error(viewModel.loadError!);

    final rows = viewModel.prescriptions;
    if (rows.isEmpty) {
      return CareStateView(
        icon: Icons.medication_outlined,
        title: viewModel.query.isEmpty ? 'No prescriptions yet' : 'Nothing matches that',
        message: viewModel.query.isEmpty
            ? 'Prescriptions you write during a consultation appear here.'
            : 'Try a different patient, number or medicine.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _PrescriptionCard(prescription: rows[index]),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final DoctorPrescriptionSummary prescription;
  const _PrescriptionCard({required this.prescription});

  @override
  Widget build(BuildContext context) {
    final status = prescription.status;

    return CareCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CareIconBox(icon: Icons.medication_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription.patientName ?? 'Unknown patient',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CareText.titleMd,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (prescription.prescriptionNo.isNotEmpty) prescription.prescriptionNo,
                        if ((prescription.date ?? '').isNotEmpty) prescription.date!,
                      ].join('  ·  '),
                      style: CareText.mutedSm,
                    ),
                  ],
                ),
              ),
              if (status != null && status.isNotEmpty) CareChip.status(status),
            ],
          ),
          if (prescription.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: kCareNeutralBg,
                borderRadius: BorderRadius.circular(CareRadius.control),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in prescription.items) _MedicineLine(item: item),
                ],
              ),
            ),
          ],
          if ((prescription.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(prescription.notes!, style: CareText.mutedSmItalic),
          ],
        ],
      ),
    );
  }
}

class _MedicineLine extends StatelessWidget {
  final PrescribedMedicine item;
  const _MedicineLine({required this.item});

  @override
  Widget build(BuildContext context) {
    // Dose, frequency and duration read as one instruction, the way they
    // are written on paper.
    final detail = [
      item.dosage,
      item.frequency,
      item.duration,
      if ((item.route ?? '').isNotEmpty) item.route!,
    ].where((part) => part.trim().isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.medicineName, style: CareText.titleSm),
          if (detail.isNotEmpty) Text(detail, style: CareText.mutedXs),
          if ((item.instructions ?? '').isNotEmpty) Text(item.instructions!, style: CareText.mutedXs),
        ],
      ),
    );
  }
}

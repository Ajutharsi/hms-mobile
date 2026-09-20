import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/patient/models/prescription.dart';
import 'package:hms_mobile/features/patient/viewmodels/prescriptions_view_model.dart';

/// The prescriptions list body — shown under a [CarePageHeader] on the
/// "My Prescriptions" page the home shell pushes.
class PrescriptionsTabBody extends StatelessWidget {
  const PrescriptionsTabBody({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PrescriptionsViewModel>();

    return RefreshIndicator(
      color: kCare,
      onRefresh: viewModel.loadPrescriptions,
      child: _buildBody(viewModel),
    );
  }

  Widget _buildBody(PrescriptionsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.prescriptions.isEmpty) return const CareStateView.loading();
    if (viewModel.errorMessage != null && viewModel.prescriptions.isEmpty) return CareStateView.error(viewModel.errorMessage!);
    if (viewModel.prescriptions.isEmpty) {
      return const CareStateView(
        icon: Icons.medication_rounded,
        title: 'No prescriptions yet',
        message: 'Prescriptions your doctor writes for you will show up here.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      itemCount: viewModel.prescriptions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _PrescriptionCard(prescription: viewModel.prescriptions[index]),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final Prescription prescription;
  const _PrescriptionCard({required this.prescription});

  @override
  Widget build(BuildContext context) {
    final doctor = prescription.doctorName ?? 'Doctor';
    return CareCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 6, 12, 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          iconColor: kCare,
          collapsedIconColor: kMuted,
          leading: CareAvatar(name: doctor, radius: 23),
          title: Text(doctor, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                CareChip(label: prescription.date, bg: kCarePinkBg, fg: kCarePinkFg, icon: Icons.calendar_today_rounded),
                CareChip.status(prescription.status),
                CareChip(
                  label: '${prescription.items.length} medicine${prescription.items.length == 1 ? '' : 's'}',
                  bg: kCareSoft,
                  fg: kCareDark,
                ),
              ],
            ),
          ),
          children: [
            if ((prescription.doctorSpecialization ?? '').isNotEmpty || prescription.prescriptionNo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if ((prescription.doctorSpecialization ?? '').isNotEmpty)
                      Expanded(child: Text(prescription.doctorSpecialization!, style: const TextStyle(fontSize: 12.5, color: kMuted))),
                    if (prescription.prescriptionNo.isNotEmpty)
                      Text(prescription.prescriptionNo, style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            if ((prescription.notes ?? '').isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(prescription.notes!, style: const TextStyle(fontSize: 13, color: kMuted, fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 10),
            ],
            ...prescription.items.map((item) => _MedicineRow(item: item)),
          ],
        ),
      ),
    );
  }
}

class _MedicineRow extends StatelessWidget {
  final PrescriptionItem item;
  const _MedicineRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kCareBg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CareIconBox(icon: Icons.medication_rounded, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.medicineName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _detail(Icons.medication_liquid_outlined, item.dosage),
                    _detail(Icons.repeat_rounded, item.frequency),
                    _detail(Icons.calendar_month_outlined, item.duration),
                    if ((item.route ?? '').isNotEmpty) _detail(Icons.route_outlined, item.route!),
                  ],
                ),
                if ((item.instructions ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(item.instructions!, style: const TextStyle(fontSize: 12.5, color: kMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: kCare),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12.5, color: kMuted)),
      ],
    );
  }
}

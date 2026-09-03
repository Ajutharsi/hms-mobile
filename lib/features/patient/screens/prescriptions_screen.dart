import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/features/patient/models/prescription.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/patient/viewmodels/prescriptions_view_model.dart';

/// The Prescriptions tab body — embedded inside [HomeScreen]'s bottom-nav
/// shell rather than being its own full Scaffold.
class PrescriptionsTabBody extends StatelessWidget {
  const PrescriptionsTabBody({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PrescriptionsViewModel>();

    return RefreshIndicator(
      color: kTeal,
      onRefresh: viewModel.loadPrescriptions,
      child: _buildBody(viewModel),
    );
  }

  Widget _buildBody(PrescriptionsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.prescriptions.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }

    if (viewModel.errorMessage != null && viewModel.prescriptions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
          const SizedBox(height: 12),
          Text(viewModel.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
        ],
      );
    }

    if (viewModel.prescriptions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.medication_outlined, color: kMuted, size: 40),
          SizedBox(height: 12),
          Text(
            'No prescriptions yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk),
          ),
          SizedBox(height: 6),
          Text(
            "Prescriptions your doctor writes for you will show up here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 13.5),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
    return Container(
      decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          iconColor: kTeal,
          collapsedIconColor: kMuted,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  prescription.doctorName ?? 'Doctor',
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: kInk),
                ),
              ),
              _StatusChip(status: prescription.status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                if ((prescription.doctorSpecialization ?? '').isNotEmpty) ...[
                  Text(prescription.doctorSpecialization!, style: const TextStyle(fontSize: 12.5, color: kMuted)),
                  const SizedBox(width: 12),
                ],
                const Icon(Icons.calendar_today_outlined, size: 13, color: kMuted),
                const SizedBox(width: 5),
                Text(prescription.date, style: const TextStyle(fontSize: 12.5, color: kMuted)),
              ],
            ),
          ),
          children: [
            if ((prescription.notes ?? '').isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  prescription.notes!,
                  style: const TextStyle(fontSize: 13, color: kMuted, fontStyle: FontStyle.italic),
                ),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.medicineName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 4),
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
    );
  }

  Widget _detail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: kMuted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12.5, color: kMuted)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      'active' => (const Color(0xFFE3F1EE), kTealDark, 'Active'),
      'completed' => (const Color(0xFFE6F4E6), const Color(0xFF2F7D5B), 'Completed'),
      _ => (kFieldFill, kMuted, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}

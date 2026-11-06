import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/receptionist/models/reception_appointment.dart';
import 'package:hms_mobile/features/doctor/screens/doctor_appointment_detail_screen.dart';
import 'package:hms_mobile/features/receptionist/screens/appointment_form_screen.dart';
import 'package:hms_mobile/features/receptionist/viewmodels/reception_appointments_view_model.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';

const _kStatusFilters = [null, 'scheduled', 'completed', 'cancelled', 'no_show'];

class ReceptionAppointmentsScreen extends StatelessWidget {
  /// Whether tapping an appointment can also open its clinical record.
  ///
  /// The web lets an administrator write a consultation against any
  /// appointment, on the doctor's behalf; the front desk may not, and the
  /// API refuses them. So the admin shell passes true and nobody else
  /// does — rather than showing the front desk a button that 403s.
  final bool canOpenConsultation;

  const ReceptionAppointmentsScreen({super.key, this.canOpenConsultation = false});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => ReceptionAppointmentsViewModel(),
      child: _ReceptionAppointmentsView(canOpenConsultation: canOpenConsultation),
    );
  }
}

class _ReceptionAppointmentsView extends StatelessWidget {
  final bool canOpenConsultation;
  const _ReceptionAppointmentsView({required this.canOpenConsultation});

  Future<void> _book(BuildContext context, ReceptionAppointmentsViewModel viewModel) async {
    final booked = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AppointmentFormScreen()));
    if (booked == true) viewModel.load();
  }

  Future<void> _edit(BuildContext context, ReceptionAppointmentsViewModel viewModel, ReceptionAppointment appt) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => AppointmentFormScreen(existing: appt)));
    if (saved == true) viewModel.load();
  }

  /// The consultation and prescription for this appointment. Reusing the
  /// doctor's own screen: it takes nothing but an id, and the record it
  /// writes is filed against the appointment's doctor either way.
  Future<void> _openConsultation(BuildContext context, ReceptionAppointmentsViewModel viewModel, ReceptionAppointment appt) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DoctorAppointmentDetailScreen(appointmentId: appt.id)),
    );
    if (context.mounted) viewModel.load();
  }

  /// Which of the two to open. With one choice, go straight there.
  Future<void> _tap(BuildContext context, ReceptionAppointmentsViewModel viewModel, ReceptionAppointment appt) async {
    if (!canOpenConsultation) return _edit(context, viewModel, appt);

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(CareRadius.sheet)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            ListTile(
              leading: const CareIconBox(icon: Icons.edit_calendar_outlined, size: 38, filled: false),
              title: const Text('Edit the booking', style: CareText.titleMd),
              subtitle: const Text('Doctor, date and time', style: CareText.mutedSm),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: const CareIconBox(icon: Icons.medical_information_outlined, size: 38, filled: false),
              title: const Text('Clinical record', style: CareText.titleMd),
              subtitle: const Text('Consultation and prescription', style: CareText.mutedSm),
              onTap: () => Navigator.of(context).pop('consultation'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'edit') return _edit(context, viewModel, appt);
    return _openConsultation(context, viewModel, appt);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<ReceptionAppointmentsViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Appointments'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _book(context, viewModel),
        backgroundColor: kCareDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Book appointment', style: CareText.onCare),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              children: [
                for (final status in _kStatusFilters) ...[
                  ChoiceChip(
                    label: Text(status == null ? 'All' : status.replaceAll('_', ' ')),
                    selected: viewModel.statusFilter == status,
                    onSelected: (_) => viewModel.setFilter(status),
                    selectedColor: kCareSoft,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(child: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(context, viewModel))),
        ],
      ),
    ));
  }

  Widget _buildBody(BuildContext context, ReceptionAppointmentsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.appointments.isEmpty) {
      return const CareStateView.loading();
    }
    if (viewModel.loadError != null && viewModel.appointments.isEmpty) {
      return CareStateView.error(viewModel.loadError!);
    }
    if (viewModel.appointments.isEmpty) {
      return const CareStateView(icon: Icons.event_outlined, title: 'No appointments found');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: viewModel.appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final appt = viewModel.appointments[index];
        return _AppointmentCard(appointment: appt, onTap: () => _tap(context, viewModel, appt));
      },
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final ReceptionAppointment appointment;
  final VoidCallback onTap;
  const _AppointmentCard({required this.appointment, required this.onTap});

  static Map<String, (Color, Color)> get _statusColors => {
    'scheduled': (kInfoFg, kInfoBg),
    'completed': (kSuccessFg, kSuccessBg),
    'cancelled': (kDangerFg, kDangerBg),
    'no_show': (kMuted, kCareBg),
  };

  static Map<String, (Color, Color)> get _typeColors => {
    'op': (kInfoFg, kInfoBg),
    'emergency': (kDangerFg, kDangerBg),
    'consult': (kCareDark, kCareSoft),
    'followup': (kSuccessFg, kSuccessBg),
  };

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final (sFg, sBg) = _statusColors[appointment.status] ?? (kMuted, kCareBg);
    final (tFg, tBg) = _typeColors[appointment.type] ?? (kMuted, kCareBg);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CareRadius.card),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(CareRadius.card), border: Border.all(color: kCareBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(appointment.patientName ?? 'Patient', style: CareText.titleLg)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: sBg, borderRadius: BorderRadius.circular(CareRadius.chip)),
                  child: Text(appointment.status.replaceAll('_', ' '), style: CareText.chip(sFg)),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text('${appointment.patientMrn ?? ''} · ${appointment.doctorName ?? ''}', style: CareText.mutedXs),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 13, color: kMuted),
                const SizedBox(width: 6),
                Text(appointment.date, style: CareText.mutedXs),
                const SizedBox(width: 12),
                const Icon(Icons.access_time_rounded, size: 13, color: kMuted),
                const SizedBox(width: 6),
                Text(appointment.time, style: CareText.mutedXs),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: tBg, borderRadius: BorderRadius.circular(CareRadius.chip)),
                  child: Text(appointment.type, style: TextStyle(color: tFg, fontSize: CareText.xxs, fontWeight: CareText.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

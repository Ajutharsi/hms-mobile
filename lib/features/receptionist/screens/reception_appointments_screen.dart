import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/receptionist/models/reception_appointment.dart';
import 'package:hms_mobile/features/receptionist/screens/appointment_form_screen.dart';
import 'package:hms_mobile/features/receptionist/viewmodels/reception_appointments_view_model.dart';

const _kStatusFilters = [null, 'scheduled', 'completed', 'cancelled', 'no_show'];

class ReceptionAppointmentsScreen extends StatelessWidget {
  const ReceptionAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReceptionAppointmentsViewModel(),
      child: const _ReceptionAppointmentsView(),
    );
  }
}

class _ReceptionAppointmentsView extends StatelessWidget {
  const _ReceptionAppointmentsView();

  Future<void> _book(BuildContext context, ReceptionAppointmentsViewModel viewModel) async {
    final booked = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AppointmentFormScreen()));
    if (booked == true) viewModel.load();
  }

  Future<void> _edit(BuildContext context, ReceptionAppointmentsViewModel viewModel, ReceptionAppointment appt) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => AppointmentFormScreen(existing: appt)));
    if (saved == true) viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReceptionAppointmentsViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, foregroundColor: kInk, elevation: 0, title: const Text('Appointments', style: TextStyle(fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _book(context, viewModel),
        backgroundColor: kTealDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Book appointment', style: TextStyle(color: Colors.white)),
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
                    selectedColor: kMint,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(child: RefreshIndicator(color: kTeal, onRefresh: viewModel.load, child: _buildBody(context, viewModel))),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReceptionAppointmentsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.appointments.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }
    if (viewModel.loadError != null && viewModel.appointments.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }
    if (viewModel.appointments.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: const [
        SizedBox(height: 80),
        Icon(Icons.event_outlined, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No appointments found', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: viewModel.appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final appt = viewModel.appointments[index];
        return _AppointmentCard(appointment: appt, onTap: () => _edit(context, viewModel, appt));
      },
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final ReceptionAppointment appointment;
  final VoidCallback onTap;
  const _AppointmentCard({required this.appointment, required this.onTap});

  static const _statusColors = {
    'scheduled': (kInfoFg, kInfoBg),
    'completed': (kSuccessFg, kSuccessBg),
    'cancelled': (kDangerFg, kDangerBg),
    'no_show': (kMuted, kFieldFill),
  };

  static const _typeColors = {
    'op': (kInfoFg, kInfoBg),
    'emergency': (kDangerFg, kDangerBg),
    'consult': (kTealDark, kMint),
    'followup': (kSuccessFg, kSuccessBg),
  };

  @override
  Widget build(BuildContext context) {
    final (sFg, sBg) = _statusColors[appointment.status] ?? (kMuted, kFieldFill);
    final (tFg, tBg) = _typeColors[appointment.type] ?? (kMuted, kFieldFill);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kFieldFill)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(appointment.patientName ?? 'Patient', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: sBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(appointment.status.replaceAll('_', ' '), style: TextStyle(color: sFg, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text('${appointment.patientMrn ?? ''} · ${appointment.doctorName ?? ''}', style: const TextStyle(fontSize: 12, color: kMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 13, color: kMuted),
                const SizedBox(width: 6),
                Text(appointment.date, style: const TextStyle(fontSize: 12, color: kMuted)),
                const SizedBox(width: 12),
                const Icon(Icons.access_time_rounded, size: 13, color: kMuted),
                const SizedBox(width: 6),
                Text(appointment.time, style: const TextStyle(fontSize: 12, color: kMuted)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: tBg, borderRadius: BorderRadius.circular(7)),
                  child: Text(appointment.type, style: TextStyle(color: tFg, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

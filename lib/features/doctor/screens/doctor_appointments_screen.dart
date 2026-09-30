import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/doctor/screens/doctor_appointment_detail_screen.dart';
import 'package:hms_mobile/features/doctor/screens/doctor_home_screen.dart' show DoctorAppointmentCard;
import 'package:hms_mobile/features/doctor/viewmodels/doctor_view_models.dart';

/// The doctor's working list of visits, filtered by what still needs doing.
class DoctorAppointmentsScreen extends StatelessWidget {
  final String initialFilter;
  const DoctorAppointmentsScreen({super.key, this.initialFilter = 'all'});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorAppointmentsViewModel()..setFilter(initialFilter),
      child: const CareTheme(child: _AppointmentsView()),
    );
  }
}

class _AppointmentsView extends StatelessWidget {
  const _AppointmentsView();

  static const _filters = [
    ('all', 'All'),
    ('today', 'Today'),
    ('scheduled', 'Scheduled'),
    ('completed', 'Completed'),
  ];

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<DoctorAppointmentsViewModel>();

    return Scaffold(
      appBar: carePageAppBar(context, 'Appointments'),
      body: Column(
        children: [
          SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final (value, label) = _filters[index];
                return CareChoicePill(
                  label: label,
                  selected: viewModel.filter == value,
                  onTap: () => viewModel.setFilter(value),
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kCare,
              onRefresh: viewModel.load,
              child: _buildList(context, viewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, DoctorAppointmentsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.appointments.isEmpty) return const CareStateView.loading();
    if (viewModel.loadError != null && viewModel.appointments.isEmpty) return CareStateView.error(viewModel.loadError!);
    if (viewModel.appointments.isEmpty) {
      return const CareStateView(
        icon: Icons.event_available_rounded,
        title: 'No appointments here',
        message: 'Try another filter — bookings made by reception show up in this list.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: viewModel.appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final appointment = viewModel.appointments[index];
        return DoctorAppointmentCard(
          appointment: appointment,
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => DoctorAppointmentDetailScreen(appointmentId: appointment.id),
            ));
            if (context.mounted) viewModel.load();
          },
        );
      },
    );
  }
}

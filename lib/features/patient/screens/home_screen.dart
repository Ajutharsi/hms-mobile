import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/features/patient/models/appointment.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/patient/viewmodels/home_view_model.dart';
import 'package:hms_mobile/features/patient/viewmodels/invoices_view_model.dart';
import 'package:hms_mobile/features/patient/viewmodels/lab_results_view_model.dart';
import 'package:hms_mobile/features/patient/viewmodels/prescriptions_view_model.dart';
import 'package:hms_mobile/features/patient/viewmodels/profile_view_model.dart';
import 'package:hms_mobile/features/patient/screens/book_appointment_screen.dart';
import 'package:hms_mobile/features/patient/screens/dashboard_screen.dart';
import 'package:hms_mobile/features/patient/screens/invoices_screen.dart';
import 'package:hms_mobile/features/patient/screens/lab_results_screen.dart';
import 'package:hms_mobile/features/auth/screens/login_screen.dart';
import 'package:hms_mobile/features/patient/screens/prescriptions_screen.dart';
import 'package:hms_mobile/features/patient/screens/profile_screen.dart';

/// The patient's home shell — a bottom-nav container holding every Patient
/// Portal section: Appointments, Prescriptions, Lab Results, Billing.
class HomeScreen extends StatelessWidget {
  final AppUser user;
  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel(user: user)),
        ChangeNotifierProvider(create: (_) => PrescriptionsViewModel()),
        ChangeNotifierProvider(create: (_) => LabResultsViewModel()),
        ChangeNotifierProvider(create: (_) => InvoicesViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: const _HomeShell(),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _tabIndex = 0;

  Future<void> _bookAppointment(BuildContext context, HomeViewModel viewModel) async {
    final booked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const BookAppointmentScreen()),
    );
    if (booked == true) viewModel.loadAppointments();
  }

  Future<void> _logout(BuildContext context, HomeViewModel viewModel) async {
    await viewModel.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeViewModel = context.watch<HomeViewModel>();
    final firstName = homeViewModel.user.firstName;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kInk,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hi there,', style: TextStyle(fontSize: 12.5, color: kMuted, fontWeight: FontWeight.w400)),
            Text(firstName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: homeViewModel.isLoggingOut
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kTeal),
                  )
                : const Icon(Icons.logout_rounded, color: kMuted),
            onPressed: homeViewModel.isLoggingOut ? null : () => _logout(context, homeViewModel),
          ),
        ],
      ),
      drawer: _PatientDrawer(
        onNavigateTab: (index) => setState(() => _tabIndex = index),
        onBookAppointment: () => _bookAppointment(context, homeViewModel),
      ),
      floatingActionButton: _tabIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _bookAppointment(context, homeViewModel),
              backgroundColor: kTealDark,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Book appointment', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            DashboardTabBody(
              onBookAppointment: () => _bookAppointment(context, homeViewModel),
              onNavigateTab: (index) => setState(() => _tabIndex = index),
            ),
            const _AppointmentsTab(),
            const PrescriptionsTabBody(),
            const LabResultsTabBody(),
            const InvoicesTabBody(),
            const ProfileTabBody(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        indicatorColor: kMint,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: kMuted),
            selectedIcon: Icon(Icons.dashboard, color: kTealDark),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined, color: kMuted),
            selectedIcon: Icon(Icons.event, color: kTealDark),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined, color: kMuted),
            selectedIcon: Icon(Icons.medication, color: kTealDark),
            label: 'Prescriptions',
          ),
          NavigationDestination(
            icon: Icon(Icons.biotech_outlined, color: kMuted),
            selectedIcon: Icon(Icons.biotech, color: kTealDark),
            label: 'Lab Results',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: kMuted),
            selectedIcon: Icon(Icons.receipt_long, color: kTealDark),
            label: 'Billing',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: kMuted),
            selectedIcon: Icon(Icons.person, color: kTealDark),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Mirrors the web patient portal's persistent sidebar (MAIN / PATIENT
/// PORTAL groups) as a drawer — mobile keeps the bottom nav for the most
/// common taps too, this just matches the web's navigation structure.
class _PatientDrawer extends StatelessWidget {
  final void Function(int) onNavigateTab;
  final VoidCallback onBookAppointment;
  const _PatientDrawer({required this.onNavigateTab, required this.onBookAppointment});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: kMint, borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.add_rounded, color: kTealDark),
                  ),
                  const SizedBox(width: 10),
                  const Text('HMS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kInk)),
                ],
              ),
            ),
            const _DrawerGroupLabel('MAIN'),
            _DrawerTile(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              onTap: () {
                onNavigateTab(0);
                Navigator.of(context).pop();
              },
            ),
            const _DrawerGroupLabel('PATIENT PORTAL'),
            _DrawerTile(
              icon: Icons.event_outlined,
              label: 'My Appointments',
              onTap: () {
                onNavigateTab(1);
                Navigator.of(context).pop();
              },
            ),
            _DrawerTile(
              icon: Icons.event_available_outlined,
              label: 'Book Appointment',
              onTap: () {
                Navigator.of(context).pop();
                onBookAppointment();
              },
            ),
            _DrawerTile(
              icon: Icons.medication_outlined,
              label: 'My Prescriptions',
              onTap: () {
                onNavigateTab(2);
                Navigator.of(context).pop();
              },
            ),
            _DrawerTile(
              icon: Icons.receipt_long_outlined,
              label: 'My Bills',
              onTap: () {
                onNavigateTab(4);
                Navigator.of(context).pop();
              },
            ),
            _DrawerTile(
              icon: Icons.biotech_outlined,
              label: 'My Lab Results',
              onTap: () {
                onNavigateTab(3);
                Navigator.of(context).pop();
              },
            ),
            _DrawerTile(
              icon: Icons.person_outline,
              label: 'My Profile',
              onTap: () {
                onNavigateTab(5);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DrawerGroupLabel extends StatelessWidget {
  final String label;
  const _DrawerGroupLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.6)),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      leading: Icon(icon, size: 20, color: kMuted),
      title: Text(label, style: const TextStyle(fontSize: 14, color: kInk, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

class _AppointmentsTab extends StatelessWidget {
  const _AppointmentsTab();

  Future<void> _confirmCancel(BuildContext context, HomeViewModel viewModel, Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: Text('Cancel your appointment with ${appointment.doctorName} on ${appointment.date}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No, keep it')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, cancel', style: TextStyle(color: Color(0xFFB3261E))),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await viewModel.cancelAppointment(appointment.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error == null ? kTealDark : null,
        content: Text(error ?? 'Appointment cancelled.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return RefreshIndicator(
      color: kTeal,
      onRefresh: viewModel.loadAppointments,
      child: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, HomeViewModel viewModel) {
    if (viewModel.isLoading && viewModel.appointments.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }

    if (viewModel.loadError != null && viewModel.appointments.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
          const SizedBox(height: 12),
          Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
        ],
      );
    }

    if (viewModel.appointments.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.event_available_outlined, color: kMuted, size: 40),
          SizedBox(height: 12),
          Text(
            'No appointments yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk),
          ),
          SizedBox(height: 6),
          Text(
            'Tap "Book appointment" to schedule your first visit.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 13.5),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: viewModel.appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final appointment = viewModel.appointments[index];
        return _AppointmentCard(
          appointment: appointment,
          onCancel: () => _confirmCancel(context, viewModel, appointment),
        );
      },
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onCancel;

  const _AppointmentCard({required this.appointment, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kFieldFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  appointment.doctorName ?? 'Doctor',
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: kInk),
                ),
              ),
              _StatusChip(status: appointment.status),
            ],
          ),
          if ((appointment.doctorSpecialization ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              appointment.doctorSpecialization!,
              style: const TextStyle(fontSize: 12.5, color: kMuted),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: kMuted),
              const SizedBox(width: 6),
              Text(appointment.date, style: const TextStyle(fontSize: 13, color: kMuted)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time_rounded, size: 14, color: kMuted),
              const SizedBox(width: 6),
              Text(appointment.time, style: const TextStyle(fontSize: 13, color: kMuted)),
              if (appointment.tokenNumber != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.confirmation_number_outlined, size: 14, color: kMuted),
                const SizedBox(width: 6),
                Text('Token #${appointment.tokenNumber}', style: const TextStyle(fontSize: 13, color: kMuted)),
              ],
            ],
          ),
          if (appointment.isScheduled) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFFB3261E), fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      'scheduled' => (const Color(0xFFE3F1EE), kTealDark, 'Scheduled'),
      'completed' => (const Color(0xFFE6F4E6), const Color(0xFF2F7D5B), 'Completed'),
      'cancelled' => (const Color(0xFFF1E9E9), const Color(0xFF8A6B6B), 'Cancelled'),
      'no_show' => (const Color(0xFFFBEAE8), const Color(0xFFB3261E), 'No-show'),
      _ => (kFieldFill, kMuted, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}

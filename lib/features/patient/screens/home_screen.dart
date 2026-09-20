import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/patient/models/appointment.dart';
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

/// The patient's home shell — bottom nav (Home / Appointments / Lab /
/// Profile) around a center "Book" button, plus a drawer that mirrors the
/// web patient portal's sidebar. Prescriptions and Bills open as their own
/// pages from the home options list and the drawer.
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
      child: const CareTheme(child: _HomeShell()),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  static const _tabs = [PatientSection.home, PatientSection.appointments, PatientSection.lab, PatientSection.profile];
  static const _tabTitles = ['Home', 'My Appointments', 'Lab Results', 'My Profile'];

  int _tabIndex = 0;

  Future<void> _bookAppointment() async {
    final viewModel = context.read<HomeViewModel>();
    final booked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const BookAppointmentScreen()),
    );
    if (booked == true) {
      viewModel.loadAppointments();
      if (mounted) context.read<ProfileViewModel>().load();
    }
  }

  // Generic so the provider is registered under the concrete view-model
  // type the pushed body looks up, not as a bare ChangeNotifier.
  void _pushSection<T extends ChangeNotifier>(String title, T viewModel, Widget body) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider<T>.value(
          value: viewModel,
          child: CareTheme(
            child: Scaffold(
              appBar: carePageAppBar(context, title),
              body: body,
            ),
          ),
        ),
      ),
    );
  }

  void _open(PatientSection section) {
    switch (section) {
      case PatientSection.book:
        _bookAppointment();
      case PatientSection.prescriptions:
        _pushSection('My Prescriptions', context.read<PrescriptionsViewModel>(), const PrescriptionsTabBody());
      case PatientSection.bills:
        _pushSection('Bills & Payments', context.read<InvoicesViewModel>(), const InvoicesTabBody());
      default:
        setState(() => _tabIndex = _tabs.indexOf(section));
    }
  }

  Future<void> _logout() async {
    final viewModel = context.read<HomeViewModel>();
    await viewModel.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeViewModel = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: kCareBg,
      drawer: _PatientDrawer(
        user: homeViewModel.user,
        photoUrl: context.watch<ProfileViewModel>().profile?.profilePhotoUrl,
        isLoggingOut: homeViewModel.isLoggingOut,
        onOpen: _open,
        onLogout: _logout,
      ),
      body: Column(
        children: [
          if (_tabIndex != 0) CarePageHeader(title: _tabTitles[_tabIndex], showBack: false),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                DashboardTabBody(onOpen: _open),
                const _AppointmentsTab(),
                const LabResultsTabBody(),
                const ProfileTabBody(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CareBottomNav(
        selectedIndex: _tabIndex,
        onSelected: (i) => setState(() => _tabIndex = i),
        centerIcon: Icons.add_rounded,
        onCenterTap: _bookAppointment,
        items: const [
          CareNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
          CareNavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Visits'),
          CareNavItem(icon: Icons.biotech_outlined, activeIcon: Icons.biotech_rounded, label: 'Lab'),
          CareNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}

/// Mirrors the web patient portal's sidebar (MAIN / PATIENT PORTAL).
class _PatientDrawer extends StatelessWidget {
  final AppUser user;
  final String? photoUrl;
  final bool isLoggingOut;
  final void Function(PatientSection) onOpen;
  final VoidCallback onLogout;

  const _PatientDrawer({
    required this.user,
    required this.photoUrl,
    required this.isLoggingOut,
    required this.onOpen,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    void go(PatientSection section) {
      Navigator.of(context).pop();
      onOpen(section);
    }

    final topInset = MediaQuery.of(context).padding.top;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(28))),
      child: Column(
        children: [
          CareHeaderBackground(
            radius: 0,
            padding: EdgeInsets.fromLTRB(22, topInset + 24, 22, 22),
            child: Row(
              children: [
                CareAvatar(name: user.name, imageUrl: photoUrl ?? user.profilePhotoUrl, radius: 30, ring: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              children: [
                _DrawerTile(icon: Icons.home_rounded, label: 'Home', onTap: () => go(PatientSection.home)),
                _DrawerTile(icon: Icons.calendar_month_rounded, label: 'My Appointments', onTap: () => go(PatientSection.appointments)),
                _DrawerTile(icon: Icons.event_available_rounded, label: 'Book Appointment', onTap: () => go(PatientSection.book)),
                _DrawerTile(icon: Icons.medication_rounded, label: 'My Prescriptions', onTap: () => go(PatientSection.prescriptions)),
                _DrawerTile(icon: Icons.biotech_rounded, label: 'My Lab Results', onTap: () => go(PatientSection.lab)),
                _DrawerTile(icon: Icons.receipt_long_rounded, label: 'My Bills', onTap: () => go(PatientSection.bills)),
                _DrawerTile(icon: Icons.person_rounded, label: 'My Profile', onTap: () => go(PatientSection.profile)),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: CarePrimaryButton(
                label: 'Log out',
                icon: Icons.logout_rounded,
                loading: isLoggingOut,
                onPressed: onLogout,
              ),
            ),
          ),
        ],
      ),
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
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: CareIconBox(icon: icon, size: 36, filled: false),
      title: Text(label, style: const TextStyle(fontSize: 14.5, color: kInk, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFB5C2C0)),
    );
  }
}

class _AppointmentsTab extends StatefulWidget {
  const _AppointmentsTab();

  @override
  State<_AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<_AppointmentsTab> {
  bool _showUpcoming = true;

  Future<void> _confirmCancel(HomeViewModel viewModel, Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Cancel appointment?'),
        content: Text('Cancel your appointment with ${appointment.doctorName ?? 'the doctor'} on ${appointment.date}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No, keep it')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, cancel', style: TextStyle(color: kCarePinkFg, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await viewModel.cancelAppointment(appointment.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error == null ? kCareDark : null,
        content: Text(error ?? 'Appointment cancelled.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    // Soonest visit first; the API returns newest-booked first.
    final upcoming = viewModel.appointments.where((a) => a.isScheduled).toList()
      ..sort((a, b) => '${a.date} ${a.time}'.compareTo('${b.date} ${b.time}'));
    final history = viewModel.appointments.where((a) => !a.isScheduled).toList();
    final shown = _showUpcoming ? upcoming : history;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kCareBorder)),
            child: Row(
              children: [
                _SegmentButton(label: 'Upcoming (${upcoming.length})', selected: _showUpcoming, onTap: () => setState(() => _showUpcoming = true)),
                _SegmentButton(label: 'History (${history.length})', selected: !_showUpcoming, onTap: () => setState(() => _showUpcoming = false)),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: kCare,
            onRefresh: viewModel.loadAppointments,
            child: _buildList(viewModel, shown),
          ),
        ),
      ],
    );
  }

  Widget _buildList(HomeViewModel viewModel, List<Appointment> shown) {
    if (viewModel.isLoading && viewModel.appointments.isEmpty) return const CareStateView.loading();
    if (viewModel.loadError != null && viewModel.appointments.isEmpty) return CareStateView.error(viewModel.loadError!);
    if (shown.isEmpty) {
      return CareStateView(
        icon: Icons.event_available_rounded,
        title: _showUpcoming ? 'No upcoming appointments' : 'No past appointments',
        message: _showUpcoming ? 'Tap the + button below to book a visit.' : 'Completed and cancelled visits will show up here.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: shown.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final appointment = shown[index];
        return AppointmentCard(
          appointment: appointment,
          onCancel: appointment.isScheduled ? () => _confirmCancel(viewModel, appointment) : null,
        );
      },
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegmentButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: selected ? kCare : Colors.transparent, borderRadius: BorderRadius.circular(11)),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : kMuted),
          ),
        ),
      ),
    );
  }
}

/// Doctor avatar + name, date/time chips and status — shared by the
/// appointments list here and the home screen's "See all" target.
class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onCancel;

  const AppointmentCard({super.key, required this.appointment, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final doctor = appointment.doctorName ?? 'Doctor';
    return CareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CareAvatar(name: doctor, radius: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: kInk)),
                    if ((appointment.doctorSpecialization ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(appointment.doctorSpecialization!, style: const TextStyle(fontSize: 12.5, color: kMuted)),
                    ],
                  ],
                ),
              ),
              CareChip.status(appointment.status),
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
              if (appointment.tokenNumber != null)
                CareChip(label: 'Token #${appointment.tokenNumber}', bg: kInfoBg, fg: kInfoFg, icon: Icons.confirmation_number_outlined),
            ],
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kCarePinkFg,
                  side: const BorderSide(color: kCarePinkBg, width: 1.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel appointment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

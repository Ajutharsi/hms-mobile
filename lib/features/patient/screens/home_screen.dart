import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/me/screens/inbox_screen.dart';
import 'package:hms_mobile/features/auth/screens/login_screen.dart';
import 'package:hms_mobile/features/patient/models/appointment.dart';
import 'package:hms_mobile/features/patient/models/time_slot.dart';
import 'package:hms_mobile/features/patient/screens/book_appointment_screen.dart';
import 'package:hms_mobile/features/patient/screens/dashboard_screen.dart';
import 'package:hms_mobile/features/patient/screens/health_records_screen.dart';
import 'package:hms_mobile/features/patient/screens/invoices_screen.dart';
import 'package:hms_mobile/features/patient/screens/lab_results_screen.dart';
import 'package:hms_mobile/features/patient/screens/prescriptions_screen.dart';
import 'package:hms_mobile/features/patient/screens/profile_screen.dart';
import 'package:hms_mobile/features/patient/viewmodels/home_view_model.dart';
import 'package:hms_mobile/features/patient/viewmodels/invoices_view_model.dart';
import 'package:hms_mobile/features/patient/viewmodels/lab_results_view_model.dart';
import 'package:hms_mobile/features/patient/viewmodels/prescriptions_view_model.dart';
import 'package:hms_mobile/features/patient/viewmodels/profile_view_model.dart';
import 'package:hms_mobile/features/settings/screens/app_settings_screen.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';

/// The patient's home shell — bottom nav (Home / Appointments / Lab /
/// Profile) around a center "Book" button, plus a drawer that mirrors the
/// web patient portal's sidebar. Prescriptions and Bills open as their own
/// pages from the home options list and the drawer.
class HomeScreen extends StatelessWidget {
  final AppUser user;
  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
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
    watchCarePalette(context);
    final homeViewModel = context.watch<HomeViewModel>();

    // This is the one shell that switches tabs in place -- an
    // IndexedStack and setState, no route pushed -- so the system back
    // button had nothing of its own to pop and closed the app instead.
    // Every other role pushes a route per destination and so behaves
    // the way a phone expects. Back now returns to Home, and only
    // leaves the app from Home, which is what the rest of Android does.
    return PopScope(
      canPop: _tabIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _tabIndex = 0);
      },
      child: Scaffold(
        backgroundColor: kCareBg,
        drawer: _PatientDrawer(
          user: homeViewModel.user,
          current: _tabs[_tabIndex],
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

  /// The tab the shell is showing, so the matching row reads as the one
  /// you are on. The rows that push a route of their own are never it.
  final PatientSection current;

  const _PatientDrawer({
    required this.user,
    required this.photoUrl,
    required this.isLoggingOut,
    required this.onOpen,
    required this.onLogout,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    void go(PatientSection section) {
      Navigator.of(context).pop();
      onOpen(section);
    }

    final topInset = MediaQuery.of(context).padding.top;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(CareRadius.drawer))),
      child: Column(
        children: [
          CareHeaderBackground(
            radius: 0,
            padding: EdgeInsets.fromLTRB(22, topInset + 24, 22, 22),
            child: Row(
              children: [
                CareSelfAvatar(name: user.name, fallbackUrl: photoUrl ?? user.profilePhotoUrl, radius: 30, ring: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: CareText.xxl, fontWeight: CareText.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: CareText.sm),
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
                _DrawerTile(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: current == PatientSection.home,
                    onTap: () => go(PatientSection.home)),
                _DrawerTile(
                    icon: Icons.calendar_month_rounded,
                    label: 'My Appointments',
                    selected: current == PatientSection.appointments,
                    onTap: () => go(PatientSection.appointments)),
                _DrawerTile(
                    icon: Icons.event_available_rounded,
                    label: 'Book Appointment',
                    onTap: () => go(PatientSection.book)),
                _DrawerTile(
                    icon: Icons.medication_rounded,
                    label: 'My Prescriptions',
                    onTap: () => go(PatientSection.prescriptions)),
                _DrawerTile(
                    icon: Icons.biotech_rounded,
                    label: 'My Lab Results',
                    selected: current == PatientSection.lab,
                    onTap: () => go(PatientSection.lab)),
                _DrawerTile(icon: Icons.receipt_long_rounded, label: 'My Bills', onTap: () => go(PatientSection.bills)),
                _DrawerTile(
                  icon: Icons.folder_shared_rounded,
                  label: 'My Health Records',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthRecordsScreen()));
                  },
                ),
                _DrawerTile(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InboxScreen()));
                  },
                ),
                _DrawerTile(
                    icon: Icons.person_rounded,
                    label: 'My Profile',
                    selected: current == PatientSection.profile,
                    onTap: () => go(PatientSection.profile)),
                _DrawerTile(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppSettingsScreen()));
                  },
                ),
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
  final bool selected;
  final VoidCallback onTap;
  const _DrawerTile({required this.icon, required this.label, required this.onTap, this.selected = false});

  @override
  Widget build(BuildContext context) => CareDrawerTile(icon: icon, label: label, selected: selected, onTap: onTap);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CareRadius.panel)),
        title: const Text('Cancel appointment?'),
        content: Text('Cancel your appointment with ${appointment.doctorName ?? 'the doctor'} on ${appointment.date}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No, keep it')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes, cancel', style: TextStyle(color: kCarePinkFg, fontWeight: CareText.bold)),
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

  /// Moving a booking: pick a day, then one of that doctor's free slots.
  ///
  /// Cancelling and booking again would lose the queue token and leave
  /// two rows in the patient's history for one visit.
  Future<void> _reschedule(HomeViewModel viewModel, Appointment appointment) async {
    final doctorId = appointment.doctorId;
    if (doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This booking has no doctor on it, so it cannot be moved.')),
      );
      return;
    }

    final day = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Move to which day?',
    );
    if (day == null || !mounted) return;

    final date = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

    final time = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SlotSheet(
        date: date,
        load: () => viewModel.slotsFor(doctorId: doctorId, date: date),
      ),
    );
    if (time == null || !mounted) return;

    final error = await viewModel.rescheduleAppointment(appointment.id, date: date, time: time);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error == null ? kCareDark : null,
        content: Text(error ?? 'Moved to $date at $time.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
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
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(CareRadius.field),
                border: Border.all(color: kCareBorder)),
            child: Row(
              children: [
                _SegmentButton(
                    label: 'Upcoming (${upcoming.length})',
                    selected: _showUpcoming,
                    onTap: () => setState(() => _showUpcoming = true)),
                _SegmentButton(
                    label: 'History (${history.length})',
                    selected: !_showUpcoming,
                    onTap: () => setState(() => _showUpcoming = false)),
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
        message: _showUpcoming
            ? 'Tap the + button below to book a visit.'
            : 'Completed and cancelled visits will show up here.',
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
          onReschedule: appointment.isScheduled ? () => _reschedule(viewModel, appointment) : null,
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
    watchCarePalette(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: selected ? kCare : Colors.transparent, borderRadius: BorderRadius.circular(CareRadius.control)),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontSize: CareText.sm, fontWeight: CareText.bold, color: selected ? Colors.white : kMuted),
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
  final VoidCallback? onReschedule;

  const AppointmentCard({super.key, required this.appointment, this.onCancel, this.onReschedule});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
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
                    Text(doctor, style: CareText.titleXl),
                    if ((appointment.doctorSpecialization ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(appointment.doctorSpecialization!, style: CareText.mutedSm),
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
                CareChip(
                    label: 'Token #${appointment.tokenNumber}',
                    bg: kInfoBg,
                    fg: kInfoFg,
                    icon: Icons.confirmation_number_outlined),
            ],
          ),
          if (onCancel != null || onReschedule != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onReschedule != null)
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: onReschedule,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kCareDark,
                          side: BorderSide(color: kCareSoft, width: 1.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CareRadius.control)),
                        ),
                        child: const Text('Move', style: TextStyle(fontSize: CareText.sm, fontWeight: CareText.bold)),
                      ),
                    ),
                  ),
                if (onReschedule != null && onCancel != null) const SizedBox(width: 10),
                if (onCancel != null)
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kCarePinkFg,
                          side: BorderSide(color: kCarePinkBg, width: 1.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CareRadius.control)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: CareText.sm, fontWeight: CareText.bold)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The free slots for one day, as a sheet over the appointments list.
///
/// Greyed-out slots are shown rather than hidden: seeing that 10:00 is
/// taken and 10:30 is free is the whole point of picking a time.
class _SlotSheet extends StatefulWidget {
  final String date;
  final Future<List<TimeSlot>> Function() load;

  const _SlotSheet({required this.date, required this.load});

  @override
  State<_SlotSheet> createState() => _SlotSheetState();
}

class _SlotSheetState extends State<_SlotSheet> {
  late Future<List<TimeSlot>> _slots;

  @override
  void initState() {
    super.initState();
    _slots = widget.load();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(CareRadius.sheet)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: kCareBorder, borderRadius: BorderRadius.circular(CareRadius.pill)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Pick a time', style: CareText.titleXl),
            Text(widget.date, style: CareText.mutedSm),
            const SizedBox(height: 16),
            FutureBuilder<List<TimeSlot>>(
              future: _slots,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('${snapshot.error}', style: CareText.danger),
                  );
                }

                final slots = snapshot.data ?? const <TimeSlot>[];
                if (slots.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('That doctor has no clinic on this day.', style: CareText.bodyMdMuted),
                  );
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final slot in slots)
                      CareChoicePill(
                        label: slot.time,
                        selected: false,
                        onTap: slot.available ? () => Navigator.of(context).pop(slot.time) : null,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

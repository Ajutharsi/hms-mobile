import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/auth/screens/login_screen.dart';
import 'package:hms_mobile/features/doctor/models/doctor_models.dart';
import 'package:hms_mobile/features/doctor/screens/doctor_appointment_detail_screen.dart';
import 'package:hms_mobile/features/doctor/screens/doctor_appointments_screen.dart';
import 'package:hms_mobile/features/doctor/screens/doctor_patient_detail_screen.dart';
import 'package:hms_mobile/features/doctor/screens/doctor_patients_screen.dart';
import 'package:hms_mobile/features/doctor/screens/doctor_profile_screen.dart';
import 'package:hms_mobile/features/doctor/viewmodels/doctor_view_models.dart';
import 'package:hms_mobile/features/settings/screens/appearance_screen.dart';

/// The doctor's home shell — today's clinic at the top, then shortcuts.
/// Appointments are the doctor's working list, so the centre button opens
/// today's visits rather than a create form.
class DoctorHomeScreen extends StatelessWidget {
  final AppUser user;
  const DoctorHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorDashboardViewModel(user: user),
      child: const CareTheme(child: _DoctorShell()),
    );
  }
}

enum DoctorSection { appointments, todayAppointments, patients, profile, appearance }

Widget _screenFor(DoctorSection section) => switch (section) {
      DoctorSection.appointments => const DoctorAppointmentsScreen(),
      DoctorSection.todayAppointments => const DoctorAppointmentsScreen(initialFilter: 'today'),
      DoctorSection.patients => const DoctorPatientsScreen(),
      DoctorSection.profile => const DoctorProfileScreen(),
      DoctorSection.appearance => const AppearanceScreen(),
    };

Future<void> openDoctorSection(BuildContext context, DoctorSection section) async {
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _screenFor(section)));
}

class _DoctorShell extends StatelessWidget {
  const _DoctorShell();

  Future<void> _logout(BuildContext context, DoctorDashboardViewModel viewModel) async {
    await viewModel.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<DoctorDashboardViewModel>();

    return Scaffold(
      backgroundColor: kCareBg,
      drawer: _DoctorDrawer(
        user: viewModel.user,
        isLoggingOut: viewModel.isLoggingOut,
        onLogout: () => _logout(context, viewModel),
      ),
      body: RefreshIndicator(
        color: kCare,
        edgeOffset: 120,
        onRefresh: viewModel.load,
        child: _DashboardBody(viewModel: viewModel),
      ),
      bottomNavigationBar: Builder(
        builder: (context) => CareBottomNav(
          selectedIndex: 0,
          centerIcon: Icons.today_rounded,
          onCenterTap: () async {
            await openDoctorSection(context, DoctorSection.todayAppointments);
            if (context.mounted) context.read<DoctorDashboardViewModel>().load();
          },
          onSelected: (i) async {
            final section = switch (i) {
              1 => DoctorSection.appointments,
              2 => DoctorSection.patients,
              3 => DoctorSection.profile,
              _ => null,
            };
            if (section == null) return;
            await openDoctorSection(context, section);
            if (context.mounted) context.read<DoctorDashboardViewModel>().load();
          },
          items: const [
            CareNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
            CareNavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Visits'),
            CareNavItem(icon: Icons.people_outline, activeIcon: Icons.people_rounded, label: 'Patients'),
            CareNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _DoctorDrawer extends StatelessWidget {
  final AppUser user;
  final bool isLoggingOut;
  final VoidCallback onLogout;

  const _DoctorDrawer({required this.user, required this.isLoggingOut, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final topInset = MediaQuery.of(context).padding.top;

    Widget tile(IconData icon, String label, DoctorSection? section) => ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: CareIconBox(icon: icon, size: 34, filled: false),
          title: Text(label, style: const TextStyle(fontSize: 14, color: kInk, fontWeight: FontWeight.w600)),
          onTap: () {
            Navigator.of(context).pop();
            if (section != null) openDoctorSection(context, section);
          },
        );

    Widget group(String label, List<Widget> children) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kCare, letterSpacing: 0.8)),
            ),
            ...children,
          ],
        );

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
                CareAvatar(name: user.name, imageUrl: user.profilePhotoUrl, radius: 28, ring: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              children: [
                group('MAIN', [tile(Icons.dashboard_rounded, 'Dashboard', null)]),
                group('CLINIC', [
                  tile(Icons.today_rounded, "Today's Visits", DoctorSection.todayAppointments),
                  tile(Icons.calendar_month_rounded, 'All Appointments', DoctorSection.appointments),
                  tile(Icons.people_rounded, 'Patients', DoctorSection.patients),
                ]),
                group('ACCOUNT', [
                  tile(Icons.person_rounded, 'My Profile', DoctorSection.profile),
                  tile(Icons.palette_rounded, 'Appearance', DoctorSection.appearance),
                ]),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: CarePrimaryButton(label: 'Log out', icon: Icons.logout_rounded, loading: isLoggingOut, onPressed: onLogout),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DoctorDashboardViewModel viewModel;
  const _DashboardBody({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    if (viewModel.isLoading && viewModel.stats == null) return const CareStateView.loading();
    if (viewModel.loadError != null && viewModel.stats == null) return CareStateView.error(viewModel.loadError!);

    final stats = viewModel.stats!;
    final topInset = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _DoctorHeader(user: viewModel.user, stats: stats),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: CareSectionTitle(
                title: "Today's Clinic",
                actionLabel: 'See all',
                onAction: () => openDoctorSection(context, DoctorSection.appointments),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: viewModel.todayAppointments.isEmpty
                  ? const CareCard(
                      child: Row(
                        children: [
                          CareIconBox(icon: Icons.event_available_rounded, filled: false, size: 48),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('No visits today', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk)),
                                SizedBox(height: 2),
                                Text('Your day is clear.', style: TextStyle(fontSize: 12.5, color: kMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        for (final appointment in viewModel.todayAppointments) ...[
                          DoctorAppointmentCard(
                            appointment: appointment,
                            onTap: () async {
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => DoctorAppointmentDetailScreen(appointmentId: appointment.id),
                              ));
                              if (context.mounted) viewModel.load();
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: CareSectionTitle(title: 'Overall statistics'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  CareStatCard(icon: Icons.calendar_month_rounded, label: 'My Appointments', value: '${stats.myAppointments}', trend: 'All time'),
                  CareStatCard(icon: Icons.today_rounded, label: "Today's Visits", value: '${stats.todayAppointments}', trend: 'Booked today'),
                  CareStatCard(icon: Icons.medication_rounded, label: 'Prescriptions', value: '${stats.prescriptions}', trend: 'Written by me'),
                  CareStatCard(icon: Icons.biotech_rounded, label: 'Lab Orders', value: '${stats.labOrders}', trend: 'Raised by me'),
                  CareStatCard(icon: Icons.medical_services_rounded, label: "Today's OT", value: '${stats.todayOt}', trend: 'Scheduled'),
                  CareStatCard(icon: Icons.camera_rounded, label: 'Pending Radiology', value: '${stats.pendingRadiology}', trend: 'Awaiting', alert: stats.pendingRadiology > 0),
                ],
              ),
            ),
            if (viewModel.recentPatients.isNotEmpty) ...[
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CareCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CareSectionTitle(
                        title: 'Recent Patients',
                        actionLabel: 'View All',
                        onAction: () => openDoctorSection(context, DoctorSection.patients),
                      ),
                      const SizedBox(height: 12),
                      for (final patient in viewModel.recentPatients) ...[
                        InkWell(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => DoctorPatientDetailScreen(patientId: patient.id, name: patient.name),
                          )),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                CareAvatar(name: patient.name, imageUrl: patient.photoUrl, radius: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(patient.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kInk)),
                                      Text(patient.mrn, style: const TextStyle(fontSize: 12, color: kMuted)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFFB5C2C0)),
                              ],
                            ),
                          ),
                        ),
                        if (patient != viewModel.recentPatients.last)
                          Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1, color: kCareBorder)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
          ],
        ),
        Positioned(top: 0, left: 0, right: 0, height: topInset, child: ColoredBox(color: kCare)),
      ],
    );
  }
}

class _DoctorHeader extends StatelessWidget {
  final AppUser user;
  final DoctorDashboardStats stats;

  const _DoctorHeader({required this.user, required this.stats});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final topInset = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 46),
          child: CareHeaderBackground(
            radius: 32,
            padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 24 + 62),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CareAvatar(name: user.name, imageUrl: user.profilePhotoUrl, radius: 25, ring: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello 👋', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                          Text('Doctor', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5)),
                        ],
                      ),
                    ),
                    Builder(
                      builder: (context) => Material(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Scaffold.of(context).openDrawer(),
                          child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.menu_rounded, color: Colors.white, size: 22)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: CareAlertPill(
                        icon: Icons.assignment_late_rounded,
                        label: 'To consult',
                        value: '${stats.pendingConsultations}',
                        urgent: stats.pendingConsultations > 0,
                        onTap: () => openDoctorSection(context, DoctorSection.todayAppointments),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CareAlertPill(
                        icon: Icons.confirmation_number_rounded,
                        label: 'OPD queue',
                        value: '${stats.opdQueue}',
                        urgent: stats.opdQueue > 0,
                        onTap: () => openDoctorSection(context, DoctorSection.todayAppointments),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 0,
          child: Container(
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x1A0E6B61), blurRadius: 24, offset: Offset(0, 10))],
            ),
            child: Row(
              children: [
                for (final item in [
                  (Icons.today_rounded, '${stats.todayAppointments}', 'Today'),
                  (Icons.calendar_month_rounded, '${stats.myAppointments}', 'Total'),
                  (Icons.medication_rounded, '${stats.prescriptions}', 'Scripts'),
                ]) ...[
                  if (item.$3 != 'Today') VerticalDivider(width: 1, indent: 20, endIndent: 20, color: kCareBorder),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(item.$1, size: 16, color: kCare),
                            const SizedBox(width: 5),
                            Text(item.$2, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: kInk)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(item.$3, style: const TextStyle(fontSize: 11.5, color: kMuted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One appointment row — used on the dashboard and the appointments list.
class DoctorAppointmentCard extends StatelessWidget {
  final DoctorAppointment appointment;
  final VoidCallback onTap;

  const DoctorAppointmentCard({super.key, required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final name = appointment.patientName ?? 'Patient';

    return CareCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CareAvatar(name: name, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
                    if ((appointment.patientMrn ?? '').isNotEmpty)
                      Text(appointment.patientMrn!, style: const TextStyle(fontSize: 12, color: kMuted)),
                  ],
                ),
              ),
              CareChip.status(appointment.status),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              CareChip(label: appointment.date, bg: kCarePinkBg, fg: kCarePinkFg, icon: Icons.calendar_today_rounded),
              if (appointment.time.isNotEmpty)
                CareChip(label: appointment.time, bg: kCareSoft, fg: kCareDark, icon: Icons.access_time_rounded),
              if (appointment.tokenNumber != null)
                CareChip(label: 'Token #${appointment.tokenNumber}', bg: kInfoBg, fg: kInfoFg, icon: Icons.confirmation_number_outlined),
              if (appointment.hasConsultation)
                const CareChip(label: 'Consulted', bg: kSuccessBg, fg: kSuccessFg, icon: Icons.check_rounded)
              else if (appointment.isScheduled)
                const CareChip(label: 'Needs consultation', bg: kWarningBg, fg: kWarningFg, icon: Icons.edit_note_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

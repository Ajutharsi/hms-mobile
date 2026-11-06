import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/rounds/screens/ward_rounds_screen.dart';
import 'package:hms_mobile/features/discharge/screens/discharge_summaries_screen.dart';
import 'package:hms_mobile/features/nurse/screens/assessments_screen.dart';
import 'package:hms_mobile/features/me/screens/inbox_screen.dart';
import 'package:hms_mobile/features/me/screens/my_work_screen.dart';
import 'package:hms_mobile/features/me/screens/search_screen.dart';
import 'package:hms_mobile/features/auth/screens/login_screen.dart';
import 'package:hms_mobile/features/nurse/models/dashboard_stats.dart';
import 'package:hms_mobile/features/nurse/screens/admissions_screen.dart';
import 'package:hms_mobile/features/nurse/screens/blood_bank_screen.dart';
import 'package:hms_mobile/features/nurse/screens/consent_forms_screen.dart';
import 'package:hms_mobile/features/nurse/screens/emar_screen.dart';
import 'package:hms_mobile/features/nurse/screens/er_screen.dart';
import 'package:hms_mobile/features/nurse/screens/fluid_intake_screen.dart';
import 'package:hms_mobile/features/nurse/screens/food_intake_screen.dart';
import 'package:hms_mobile/features/nurse/screens/icu_screen.dart';
import 'package:hms_mobile/features/nurse/screens/my_rounds_screen.dart';
import 'package:hms_mobile/features/nurse/screens/nurse_profile_screen.dart';
import 'package:hms_mobile/features/nurse/screens/nursing_notes_screen.dart';
import 'package:hms_mobile/features/nurse/screens/ot_screen.dart';
import 'package:hms_mobile/features/nurse/screens/patients_screen.dart';
import 'package:hms_mobile/features/nurse/screens/shift_handover_screen.dart';
import 'package:hms_mobile/features/nurse/screens/staff_rounds_screen.dart';
import 'package:hms_mobile/features/nurse/screens/vitals_screen.dart';
import 'package:hms_mobile/features/nurse/screens/ward_screen.dart';
import 'package:hms_mobile/features/nurse/viewmodels/nurse_dashboard_view_model.dart';
import 'package:hms_mobile/features/settings/screens/app_settings_screen.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';

/// The nurse's home shell — teal header + dashboard, with a drawer that
/// mirrors the web sidebar's MAIN/PATIENT/HOSPITAL/WARD/STAFF groups.
/// The bottom bar keeps the four most-used sections within reach; its
/// centre button opens the drawer, since 18 sections don't fit a nav bar.
class NurseHomeScreen extends StatelessWidget {
  final AppUser user;
  const NurseHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => NurseDashboardViewModel(user: user),
      child: const CareTheme(child: _NurseShell()),
    );
  }
}

class _NurseShell extends StatelessWidget {
  const _NurseShell();

  static void open(BuildContext context, WidgetBuilder builder) {
    Navigator.of(context).push(MaterialPageRoute(builder: builder));
  }

  Future<void> _logout(BuildContext context, NurseDashboardViewModel viewModel) async {
    await viewModel.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<NurseDashboardViewModel>();

    return Scaffold(
      backgroundColor: kCareBg,
      drawer: _NurseDrawer(
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
          centerIcon: Icons.grid_view_rounded,
          onCenterTap: () => Scaffold.of(context).openDrawer(),
          onSelected: (i) {
            switch (i) {
              case 1:
                open(context, (_) => const PatientsScreen());
              case 2:
                open(context, (_) => const MyRoundsScreen());
              case 3:
                open(context, (_) => const NurseProfileScreen());
            }
          },
          items: const [
            CareNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
            CareNavItem(icon: Icons.people_outline, activeIcon: Icons.people_rounded, label: 'Patients'),
            CareNavItem(icon: Icons.schedule_outlined, activeIcon: Icons.schedule_rounded, label: 'Rounds'),
            CareNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _NurseHeader extends StatelessWidget {
  final AppUser user;
  final NurseDashboardStats? stats;
  final Widget statsStrip;

  const _NurseHeader({required this.user, required this.stats, required this.statsStrip});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final topInset = MediaQuery.of(context).padding.top;
    const overlap = 46.0;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: overlap),
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
                          const Text('Hello 👋', style: CareText.onCareSoftSm),
                          const SizedBox(height: 2),
                          Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CareText.onCareDisplay,
                          ),
                          const Text('Nurse', style: CareText.onCareFaintXs),
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
                      child: _AlertPill(
                        icon: Icons.alarm_rounded,
                        label: 'Overdue rounds',
                        value: '${stats?.overdueRounds ?? 0}',
                        urgent: (stats?.overdueRounds ?? 0) > 0,
                        onTap: () => _NurseShell.open(context, (_) => const MyRoundsScreen()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AlertPill(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Handovers',
                        value: '${stats?.pendingHandovers ?? 0}',
                        urgent: (stats?.pendingHandovers ?? 0) > 0,
                        onTap: () => _NurseShell.open(context, (_) => const ShiftHandoverScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(left: 20, right: 20, bottom: 0, child: statsStrip),
      ],
    );
  }
}

/// Two "needs attention" counters inside the header — pink when non-zero.
class _AlertPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool urgent;
  final VoidCallback onTap;

  const _AlertPill({required this.icon, required this.label, required this.value, required this.urgent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: urgent ? kCarePinkBg : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(CareRadius.field),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: urgent ? kCarePinkFg : Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: CareText.sm, fontWeight: CareText.medium, color: urgent ? kCarePinkFg : Colors.white),
              ),
            ),
            Text(value, style: TextStyle(fontSize: CareText.lg, fontWeight: CareText.heavy, color: urgent ? kCarePinkFg : Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _NurseDrawer extends StatelessWidget {
  final AppUser user;
  final bool isLoggingOut;
  final VoidCallback onLogout;

  const _NurseDrawer({required this.user, required this.isLoggingOut, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final topInset = MediaQuery.of(context).padding.top;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(CareRadius.drawer))),
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
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CareText.onCareTitle,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CareText.onCareSoftXs,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              children: const [
                _DrawerGroup(label: 'MAIN', items: [
                  _DrawerItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
                ]),
                _DrawerGroup(label: 'PATIENT', items: [
                  _DrawerItem(icon: Icons.people_rounded, label: 'Patients', target: _Target.patients),
                ]),
                _DrawerGroup(label: 'HOSPITAL', items: [
                  _DrawerItem(icon: Icons.assignment_rounded, label: 'Consent Forms', target: _Target.consent),
                  _DrawerItem(icon: Icons.local_hospital_rounded, label: 'Emergency (ER)', target: _Target.er),
                ]),
                _DrawerGroup(label: 'WARD', items: [
                  _DrawerItem(icon: Icons.holiday_village_rounded, label: 'Ward', target: _Target.ward),
                  _DrawerItem(icon: Icons.bed_rounded, label: 'Admissions', target: _Target.admissions),
                  _DrawerItem(icon: Icons.medication_rounded, label: 'eMAR', target: _Target.emar),
                  _DrawerItem(icon: Icons.favorite_rounded, label: 'Vitals', target: _Target.vitals),
                  _DrawerItem(icon: Icons.description_rounded, label: 'Nursing Notes', target: _Target.notes),
                  _DrawerItem(icon: Icons.route_rounded, label: 'Ward Round', target: _Target.rounds),
                  _DrawerItem(icon: Icons.assignment_rounded, label: 'Assessments', target: _Target.assessments),
                  _DrawerItem(icon: Icons.assignment_turned_in_rounded, label: 'Discharge Summaries', target: _Target.discharge),
                  _DrawerItem(icon: Icons.swap_horiz_rounded, label: 'Shift Handover', target: _Target.handover),
                  _DrawerItem(icon: Icons.medical_services_rounded, label: 'Operation Theatre', target: _Target.ot),
                  _DrawerItem(icon: Icons.monitor_heart_rounded, label: 'ICU Charting', target: _Target.icu),
                  _DrawerItem(icon: Icons.water_drop_rounded, label: 'Blood Bank', target: _Target.bloodBank),
                ]),
                _DrawerGroup(label: 'STAFF', items: [
                  _DrawerItem(icon: Icons.restaurant_rounded, label: 'Food Intake', target: _Target.food),
                  _DrawerItem(icon: Icons.opacity_rounded, label: 'Fluid Intake', target: _Target.fluid),
                  _DrawerItem(icon: Icons.groups_rounded, label: 'Staff Rounds', target: _Target.staffRounds),
                  _DrawerItem(icon: Icons.schedule_rounded, label: 'My Rounds', target: _Target.myRounds),
                  _DrawerItem(icon: Icons.search_rounded, label: 'Search', target: _Target.search),
                  _DrawerItem(icon: Icons.notifications_rounded, label: 'Notifications', target: _Target.inbox),
                  _DrawerItem(icon: Icons.fact_check_rounded, label: 'My Attendance & Leave', target: _Target.myWork),
                  _DrawerItem(icon: Icons.person_rounded, label: 'My Profile', target: _Target.profile),
                  _DrawerItem(icon: Icons.settings_rounded, label: 'Settings', target: _Target.settings),
                ]),
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

enum _Target {
  patients, consent, er, ward, admissions, emar, vitals, notes, handover,
  ot, icu, bloodBank, food, fluid, staffRounds, myRounds, profile, settings, inbox, myWork, search, assessments, discharge, rounds,
}

Widget _screenFor(_Target target) => switch (target) {
      _Target.patients => const PatientsScreen(),
      _Target.consent => const ConsentFormsScreen(),
      _Target.er => const ErScreen(),
      _Target.ward => const WardScreen(),
      _Target.admissions => const AdmissionsScreen(),
      _Target.emar => const EmarScreen(),
      _Target.vitals => const VitalsScreen(),
      _Target.notes => const NursingNotesScreen(),
      _Target.handover => const ShiftHandoverScreen(),
      _Target.ot => const OtScreen(),
      _Target.icu => const IcuScreen(),
      _Target.bloodBank => const BloodBankScreen(),
      _Target.food => const FoodIntakeScreen(),
      _Target.fluid => const FluidIntakeScreen(),
      _Target.staffRounds => const StaffRoundsScreen(),
      _Target.myRounds => const MyRoundsScreen(),
      _Target.rounds => const WardRoundsScreen(),
      _Target.discharge => const DischargeSummariesScreen(),
      _Target.assessments => const AssessmentsScreen(),
      _Target.inbox => const InboxScreen(),
      _Target.myWork => const MyWorkScreen(),
      _Target.search => const GlobalSearchScreen(),
      _Target.profile => const NurseProfileScreen(),
      _Target.settings => const AppSettingsScreen(),
    };

class _DrawerGroup extends StatelessWidget {
  final String label;
  final List<_DrawerItem> items;
  const _DrawerGroup({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: Text(
            label,
            style: CareText.overline,
          ),
        ),
        ...items,
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final _Target? target;
  const _DrawerItem({required this.icon, required this.label, this.target});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CareRadius.field)),
      leading: CareIconBox(icon: icon, size: 34, filled: false),
      title: Text(label, style: CareText.titleMdMedium),
      onTap: () {
        Navigator.of(context).pop();
        if (target != null) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => _screenFor(target!)));
        }
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final NurseDashboardViewModel viewModel;
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
            _NurseHeader(
              user: viewModel.user,
              stats: stats,
              statsStrip: _StatsStrip(stats: stats),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: CareSectionTitle(title: 'Quick actions'),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: _QuickActionsGrid()),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
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
                  _StatCard(icon: Icons.bed_rounded, label: 'IP Patients', value: '${stats.ipPatients}', trend: 'Currently admitted'),
                  _StatCard(icon: Icons.alarm_rounded, label: 'Overdue Rounds', value: '${stats.overdueRounds}', trend: stats.overdueRounds > 0 ? 'Need attention!' : 'All on track', alert: stats.overdueRounds > 0),
                  _StatCard(icon: Icons.restaurant_rounded, label: 'Food Logs Today', value: '${stats.foodLogsToday}', trend: 'Meals logged'),
                  _StatCard(icon: Icons.water_drop_rounded, label: 'Fluid Logs Today', value: '${stats.fluidLogsToday}', trend: 'Fluid entries'),
                  _StatCard(icon: Icons.medication_rounded, label: 'Pending Medications', value: '${stats.pendingMedications}', trend: 'eMAR scheduled', alert: stats.pendingMedications > 0),
                  _StatCard(icon: Icons.favorite_rounded, label: 'Needs Vitals Check', value: '${stats.needsVitalsCheck}', trend: 'No reading in 4h', alert: stats.needsVitalsCheck > 0),
                  _StatCard(icon: Icons.description_rounded, label: 'Nursing Notes Today', value: '${stats.nursingNotesToday}', trend: 'Written today'),
                  _StatCard(icon: Icons.assignment_turned_in_rounded, label: "Today's Handovers", value: '${stats.todaysHandovers}', trend: 'Handed over today'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CareSectionTitle(title: "Today's Appointments"),
                    const SizedBox(height: 12),
                    if (viewModel.todayAppointments.isEmpty)
                      const Text('No appointments today.', style: CareText.mutedSm)
                    else
                      for (final a in viewModel.todayAppointments) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.patientName ?? 'Patient', style: CareText.titleMd),
                                  const SizedBox(height: 2),
                                  Text('${a.doctorName ?? ''} · ${a.time}', style: CareText.mutedXs),
                                ],
                              ),
                            ),
                            CareChip(label: a.type.toUpperCase(), bg: kCareSoft, fg: kCareDark),
                          ],
                        ),
                        if (a != viewModel.todayAppointments.last)
                          Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: kCareBorder)),
                      ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CareSectionTitle(
                      title: 'Recent Patients',
                      actionLabel: 'View All',
                      onAction: () => _NurseShell.open(context, (_) => const PatientsScreen()),
                    ),
                    const SizedBox(height: 12),
                    if (viewModel.recentPatients.isEmpty)
                      const Text('No recent patients.', style: CareText.mutedSm)
                    else
                      for (final p in viewModel.recentPatients) ...[
                        Row(
                          children: [
                            CareAvatar(name: p.name, imageUrl: p.photoUrl, radius: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: CareText.titleMd),
                                  Text(p.mrn, style: CareText.mutedXs),
                                ],
                              ),
                            ),
                            CareChip(label: p.status, bg: kSuccessBg, fg: kSuccessFg),
                          ],
                        ),
                        if (p != viewModel.recentPatients.last)
                          Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: kCareBorder)),
                      ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
        // Keeps the status bar readable once the header scrolls away.
        Positioned(top: 0, left: 0, right: 0, height: topInset, child: ColoredBox(color: kCare)),
      ],
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final NurseDashboardStats stats;
  const _StatsStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final items = [
      (Icons.bed_rounded, '${stats.ipPatients}', 'IP Patients'),
      (Icons.medication_rounded, '${stats.pendingMedications}', 'Pending meds'),
      (Icons.favorite_rounded, '${stats.needsVitalsCheck}', 'Need vitals'),
    ];

    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CareRadius.panel),
        boxShadow: careShadow(blur: 24, dy: 10, alpha: 0.1),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) VerticalDivider(width: 1, indent: 20, endIndent: 20, color: kCareBorder),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].$1, size: 16, color: kCare),
                      const SizedBox(width: 5),
                      Text(items[i].$2, style: CareText.display),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(items[i].$3, style: CareText.mutedXsMedium),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    const actions = [
      (Icons.people_rounded, 'Patients', 'Search records', _Target.patients),
      (Icons.holiday_village_rounded, 'Ward', 'Beds & wards', _Target.ward),
      (Icons.favorite_rounded, 'Vitals', 'Record vitals', _Target.vitals),
      (Icons.medication_rounded, 'eMAR', 'Medications', _Target.emar),
      (Icons.restaurant_rounded, 'Food Intake', 'Log meals', _Target.food),
      (Icons.water_drop_rounded, 'Fluid Intake', 'Log fluids', _Target.fluid),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.92,
      children: [
        for (final a in actions)
          CareCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            onTap: () => _NurseShell.open(context, (_) => _screenFor(a.$4)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CareIconBox(icon: a.$1, size: 38),
                const SizedBox(height: 7),
                Text(a.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: CareText.xs, fontWeight: CareText.bold, color: kInk)),
                Text(a.$3, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.mutedXxs),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final bool alert;

  const _StatCard({required this.icon, required this.label, required this.value, required this.trend, this.alert = false});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return CareCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: alert ? kCarePinkBg : kCareSoft, borderRadius: BorderRadius.circular(CareRadius.chip)),
                child: Icon(icon, color: alert ? kCarePinkFg : kCareDark, size: 16),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  trend,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: CareText.xxs, color: alert ? kCarePinkFg : kMuted, fontWeight: alert ? CareText.bold : CareText.regular),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: CareText.h2, fontWeight: CareText.heavy, color: kInk)),
          Text(label, style: CareText.mutedXxsMedium),
        ],
      ),
    );
  }
}

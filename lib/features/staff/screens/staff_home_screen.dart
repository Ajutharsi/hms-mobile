import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/auth/screens/login_screen.dart';
import 'package:hms_mobile/features/nurse/screens/fluid_intake_screen.dart';
import 'package:hms_mobile/features/nurse/screens/food_intake_screen.dart';
import 'package:hms_mobile/features/nurse/screens/my_rounds_screen.dart';
import 'package:hms_mobile/features/nurse/screens/nurse_profile_screen.dart';
import 'package:hms_mobile/features/nurse/screens/patients_screen.dart';
import 'package:hms_mobile/features/settings/screens/appearance_screen.dart';
import 'package:hms_mobile/features/staff/models/staff_dashboard_stats.dart';
import 'package:hms_mobile/features/staff/viewmodels/staff_dashboard_view_model.dart';

/// The support staff's home shell — rounds, food and fluid logging. Every
/// section reuses the nurse feature screens, since the backend serves both
/// roles from the same /nurse/* routes.
class StaffHomeScreen extends StatelessWidget {
  final AppUser user;
  const StaffHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StaffDashboardViewModel(user: user),
      child: const CareTheme(child: _StaffShell()),
    );
  }
}

enum _Target { patients, food, fluid, rounds, profile, appearance }

Widget _screenFor(_Target target) => switch (target) {
      _Target.patients => const PatientsScreen(),
      _Target.food => const FoodIntakeScreen(),
      _Target.fluid => const FluidIntakeScreen(),
      _Target.rounds => const MyRoundsScreen(),
      _Target.profile => const NurseProfileScreen(),
      _Target.appearance => const AppearanceScreen(),
    };

void _open(BuildContext context, _Target target) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => _screenFor(target)));
}

class _StaffShell extends StatelessWidget {
  const _StaffShell();

  Future<void> _logout(BuildContext context, StaffDashboardViewModel viewModel) async {
    await viewModel.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<StaffDashboardViewModel>();

    return Scaffold(
      backgroundColor: kCareBg,
      drawer: _StaffDrawer(
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
          centerIcon: Icons.schedule_rounded,
          onCenterTap: () => _open(context, _Target.rounds),
          onSelected: (i) {
            switch (i) {
              case 1:
                _open(context, _Target.patients);
              case 2:
                _open(context, _Target.food);
              case 3:
                _open(context, _Target.profile);
            }
          },
          items: const [
            CareNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
            CareNavItem(icon: Icons.people_outline, activeIcon: Icons.people_rounded, label: 'Patients'),
            CareNavItem(icon: Icons.restaurant_outlined, activeIcon: Icons.restaurant_rounded, label: 'Food'),
            CareNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _StaffDrawer extends StatelessWidget {
  final AppUser user;
  final bool isLoggingOut;
  final VoidCallback onLogout;

  const _StaffDrawer({required this.user, required this.isLoggingOut, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final topInset = MediaQuery.of(context).padding.top;

    Widget tile(IconData icon, String label, _Target? target) => ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: CareIconBox(icon: icon, size: 34, filled: false),
          title: Text(label, style: const TextStyle(fontSize: 14, color: kInk, fontWeight: FontWeight.w600)),
          onTap: () {
            Navigator.of(context).pop();
            if (target != null) _open(context, target);
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
                group('PATIENT', [tile(Icons.people_rounded, 'Patients', _Target.patients)]),
                group('MY WORK', [
                  tile(Icons.schedule_rounded, 'My Rounds', _Target.rounds),
                  tile(Icons.restaurant_rounded, 'Food Intake', _Target.food),
                  tile(Icons.water_drop_rounded, 'Fluid Intake', _Target.fluid),
                ]),
                group('ACCOUNT', [
                  tile(Icons.person_rounded, 'My Profile', _Target.profile),
                  tile(Icons.palette_rounded, 'Appearance', _Target.appearance),
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
  final StaffDashboardViewModel viewModel;
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
            _StaffHeader(user: viewModel.user, stats: stats),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: CareSectionTitle(title: 'Quick actions'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.92,
                children: [
                  for (final action in const [
                    (Icons.schedule_rounded, 'My Rounds', 'Your rounds', _Target.rounds),
                    (Icons.restaurant_rounded, 'Food Intake', 'Log meals', _Target.food),
                    (Icons.water_drop_rounded, 'Fluid Intake', 'Log fluids', _Target.fluid),
                    (Icons.people_rounded, 'Patients', 'Search records', _Target.patients),
                    (Icons.person_rounded, 'My Profile', 'Account', _Target.profile),
                    (Icons.palette_rounded, 'Appearance', 'Theme colour', _Target.appearance),
                  ])
                    CareCard(
                      radius: 16,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      onTap: () => _open(context, action.$4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CareIconBox(icon: action.$1, size: 38),
                          const SizedBox(height: 7),
                          Text(action.$2, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: kInk)),
                          Text(action.$3, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: kMuted)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
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
                  CareStatCard(icon: Icons.local_hospital_rounded, label: 'My Assigned Wards', value: '${stats.myAssignedWards}', trend: 'Assigned to me'),
                  CareStatCard(icon: Icons.alarm_rounded, label: 'Overdue Rounds', value: '${stats.overdueRounds}', trend: stats.overdueRounds > 0 ? 'Need attention!' : 'All on track', alert: stats.overdueRounds > 0),
                  CareStatCard(icon: Icons.restaurant_rounded, label: 'My Food Logs Today', value: '${stats.myFoodLogsToday}', trend: 'Meals logged'),
                  CareStatCard(icon: Icons.water_drop_rounded, label: 'My Fluid Logs Today', value: '${stats.myFluidLogsToday}', trend: 'Fluid entries'),
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
                        onAction: () => _open(context, _Target.patients),
                      ),
                      const SizedBox(height: 12),
                      for (final patient in viewModel.recentPatients) ...[
                        Row(
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
                            CareChip(label: patient.status, bg: kSuccessBg, fg: kSuccessFg),
                          ],
                        ),
                        if (patient != viewModel.recentPatients.last)
                          Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: kCareBorder)),
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

class _StaffHeader extends StatelessWidget {
  final AppUser user;
  final StaffDashboardStats stats;

  const _StaffHeader({required this.user, required this.stats});

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
                          Text('Support Staff', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5)),
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
                        icon: Icons.alarm_rounded,
                        label: 'Overdue rounds',
                        value: '${stats.overdueRounds}',
                        urgent: stats.overdueRounds > 0,
                        onTap: () => _open(context, _Target.rounds),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CareAlertPill(
                        icon: Icons.local_hospital_rounded,
                        label: 'My wards',
                        value: '${stats.myAssignedWards}',
                        urgent: false,
                        onTap: () => _open(context, _Target.rounds),
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
                  (Icons.local_hospital_rounded, '${stats.myAssignedWards}', 'Wards'),
                  (Icons.restaurant_rounded, '${stats.myFoodLogsToday}', 'Meals'),
                  (Icons.water_drop_rounded, '${stats.myFluidLogsToday}', 'Fluids'),
                ]) ...[
                  if (item.$3 != 'Wards') VerticalDivider(width: 1, indent: 20, endIndent: 20, color: kCareBorder),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/widgets/role_home_header.dart';
import 'package:hms_mobile/features/auth/screens/login_screen.dart';
import 'package:hms_mobile/features/nurse/screens/fluid_intake_screen.dart';
import 'package:hms_mobile/features/nurse/screens/food_intake_screen.dart';
import 'package:hms_mobile/features/nurse/screens/my_rounds_screen.dart';
import 'package:hms_mobile/features/nurse/screens/nurse_profile_screen.dart';
import 'package:hms_mobile/features/nurse/screens/patients_screen.dart';
import 'package:hms_mobile/features/staff/viewmodels/staff_dashboard_view_model.dart';

/// The staff role's home shell — narrower than the nurse's: only
/// Food Intake, Fluid Intake, My Rounds, and My Profile (mirrors the web's
/// `role:...|nurse|staff` shared routes). Reuses those same screens from
/// the nurse feature since the underlying data/actions are identical.
class StaffHomeScreen extends StatelessWidget {
  final AppUser user;
  const StaffHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StaffDashboardViewModel(user: user),
      child: const _StaffShell(),
    );
  }
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
    final viewModel = context.watch<StaffDashboardViewModel>();

    return Scaffold(
      backgroundColor: kBg,
      appBar: RoleHomeHeader(
        firstName: viewModel.user.firstName,
        isLoggingOut: viewModel.isLoggingOut,
        onLogout: () => _logout(context, viewModel),
      ),
      drawer: const _StaffDrawer(),
      body: SafeArea(
        child: RefreshIndicator(color: kTeal, onRefresh: viewModel.load, child: _DashboardBody(viewModel: viewModel)),
      ),
    );
  }
}

class _StaffDrawer extends StatelessWidget {
  const _StaffDrawer();

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
              onTap: () => Navigator.of(context).pop(),
            ),
            const _DrawerGroupLabel('STAFF'),
            _DrawerTile(
              icon: Icons.restaurant_outlined,
              label: 'Food Intake',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FoodIntakeScreen()));
              },
            ),
            _DrawerTile(
              icon: Icons.opacity_outlined,
              label: 'Fluid Intake',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FluidIntakeScreen()));
              },
            ),
            _DrawerTile(
              icon: Icons.schedule_outlined,
              label: 'My Rounds',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyRoundsScreen()));
              },
            ),
            _DrawerTile(
              icon: Icons.person_outline,
              label: 'My Profile',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NurseProfileScreen()));
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

class _DashboardBody extends StatelessWidget {
  final StaffDashboardViewModel viewModel;
  const _DashboardBody({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading && viewModel.stats == null) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }

    if (viewModel.loadError != null && viewModel.stats == null) {
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

    final stats = viewModel.stats!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const Text('Quick actions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.3)),
        const SizedBox(height: 10),
        _QuickActionsGrid(),
        const SizedBox(height: 24),
        const Text('Overall statistics', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.3)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _StatCard(icon: Icons.local_hospital_outlined, color: kTealDark, bg: kMint, label: 'My Assigned Wards', value: '${stats.myAssignedWards}', trend: 'Active assignments'),
            _StatCard(
              icon: Icons.alarm_outlined,
              color: stats.overdueRounds > 0 ? kDangerFg : kSuccessFg,
              bg: stats.overdueRounds > 0 ? kDangerBg : kSuccessBg,
              label: 'Overdue Rounds',
              value: '${stats.overdueRounds}',
              trend: stats.overdueRounds > 0 ? 'Need attention!' : 'All on track',
            ),
            _StatCard(icon: Icons.restaurant_outlined, color: kWarningFg, bg: kWarningBg, label: 'My Food Logs Today', value: '${stats.myFoodLogsToday}', trend: 'Logged by me'),
            _StatCard(icon: Icons.water_drop_outlined, color: kInfoFg, bg: kInfoBg, label: 'My Fluid Logs Today', value: '${stats.myFluidLogsToday}', trend: 'Logged by me'),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionCard(
          title: "Today's Appointments",
          child: Text('No appointments today.', style: TextStyle(color: kMuted, fontSize: 13)),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Recent Patients',
          actionLabel: 'View All',
          onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PatientsScreen())),
          child: viewModel.recentPatients.isEmpty
              ? const Text('No recent patients.', style: TextStyle(color: kMuted, fontSize: 13))
              : Column(
                  children: [
                    for (final p in viewModel.recentPatients) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: kMint,
                            backgroundImage: p.photoUrl != null ? NetworkImage(p.photoUrl!) : null,
                            child: p.photoUrl == null
                                ? Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12, color: kTealDark, fontWeight: FontWeight.w700))
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kInk)),
                                Text(p.mrn, style: const TextStyle(fontSize: 12, color: kMuted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(color: kSuccessBg, borderRadius: BorderRadius.circular(8)),
                            child: Text(p.status, style: const TextStyle(color: kSuccessFg, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      if (p != viewModel.recentPatients.last)
                        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: kFieldFill)),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.people_outline, 'Patients', 'Search records', kTealDark, kMint, (BuildContext c) => const PatientsScreen()),
      (Icons.restaurant_outlined, 'Food Intake', 'Log meals', kWarningFg, kWarningBg, (BuildContext c) => const FoodIntakeScreen()),
      (Icons.water_drop_outlined, 'Fluid Intake', 'Log fluids', kInfoFg, kInfoBg, (BuildContext c) => const FluidIntakeScreen()),
      (Icons.schedule_outlined, 'My Rounds', 'Your rounds', kTealDark, kMint, (BuildContext c) => const MyRoundsScreen()),
      (Icons.person_outline, 'My Profile', 'Account', kSuccessFg, kSuccessBg, (BuildContext c) => const NurseProfileScreen()),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        for (final a in actions)
          Builder(builder: (context) {
            return InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: a.$6)),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kFieldFill)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: a.$5, borderRadius: BorderRadius.circular(10)),
                      child: Icon(a.$1, color: a.$4, size: 17),
                    ),
                    const SizedBox(height: 6),
                    Text(a.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kInk)),
                    Text(a.$3, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: kMuted)),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  final String value;
  final String trend;
  const _StatCard({required this.icon, required this.color, required this.bg, required this.label, required this.value, required this.trend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: kFieldFill)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Flexible(child: Text(trend, textAlign: TextAlign.right, style: const TextStyle(fontSize: 9.5, color: kMuted))),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kInk)),
          Text(label, style: const TextStyle(fontSize: 10.5, color: kMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;
  const _SectionCard({required this.title, this.actionLabel, this.onAction, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: kFieldFill)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk))),
              if (actionLabel != null)
                InkWell(onTap: onAction, child: Text(actionLabel!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kTealDark))),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/widgets/role_home_header.dart';
import 'package:hms_mobile/features/auth/screens/login_screen.dart';
import 'package:hms_mobile/features/lab/screens/lab_orders_screen.dart';
import 'package:hms_mobile/features/lab/screens/lab_profile_screen.dart';
import 'package:hms_mobile/features/lab/screens/lab_tests_screen.dart';
import 'package:hms_mobile/features/lab/viewmodels/lab_dashboard_view_model.dart';

/// The lab-assistant role's home shell — mirrors the web's LABORATORY
/// sidebar group (Lab Tests, Lab Orders, My Profile) as a drawer.
class LabHomeScreen extends StatelessWidget {
  final AppUser user;
  const LabHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LabDashboardViewModel(user: user),
      child: const _LabShell(),
    );
  }
}

class _LabShell extends StatelessWidget {
  const _LabShell();

  Future<void> _logout(BuildContext context, LabDashboardViewModel viewModel) async {
    await viewModel.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LabDashboardViewModel>();

    return Scaffold(
      backgroundColor: kBg,
      appBar: RoleHomeHeader(
        firstName: viewModel.user.firstName,
        isLoggingOut: viewModel.isLoggingOut,
        onLogout: () => _logout(context, viewModel),
      ),
      drawer: const _LabDrawer(),
      body: SafeArea(
        child: RefreshIndicator(color: kTeal, onRefresh: viewModel.load, child: _DashboardBody(viewModel: viewModel)),
      ),
    );
  }
}

class _LabDrawer extends StatelessWidget {
  const _LabDrawer();

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
            const _DrawerGroupLabel('LABORATORY'),
            _DrawerTile(
              icon: Icons.science_outlined,
              label: 'Lab Tests',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LabTestsScreen()));
              },
            ),
            _DrawerTile(
              icon: Icons.assignment_outlined,
              label: 'Lab Orders',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LabOrdersScreen()));
              },
            ),
            _DrawerTile(
              icon: Icons.person_outline,
              label: 'My Profile',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LabProfileScreen()));
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
  final LabDashboardViewModel viewModel;
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
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.assignment_outlined,
                color: kTealDark,
                bg: kMint,
                label: 'Lab Orders',
                sublabel: 'Pending orders',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LabOrdersScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.science_outlined,
                color: kInfoFg,
                bg: kInfoBg,
                label: 'Lab Tests',
                sublabel: 'Test catalog',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LabTestsScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.person_outline,
                color: kSuccessFg,
                bg: kSuccessBg,
                label: 'My Profile',
                sublabel: 'Account',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LabProfileScreen())),
              ),
            ),
          ],
        ),
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
            _StatCard(icon: Icons.access_time_rounded, color: kWarningFg, bg: kWarningBg, label: 'Pending Orders', value: '${stats.pendingOrders}', trend: 'Awaiting'),
            _StatCard(icon: Icons.check_circle_outline, color: kSuccessFg, bg: kSuccessBg, label: 'Completed Today', value: '${stats.completedToday}', trend: 'Today'),
            _StatCard(icon: Icons.science_outlined, color: kTealDark, bg: kMint, label: 'Total Orders', value: '${stats.totalOrders}', trend: 'All time'),
            _StatCard(icon: Icons.biotech_outlined, color: kInfoFg, bg: kInfoBg, label: 'Lab Tests', value: '${stats.labTests}', trend: 'Available'),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionCard(
          title: "Today's Appointments",
          child: Text('No appointments today.', style: TextStyle(color: kMuted, fontSize: 13)),
        ),
        const SizedBox(height: 16),
        const _SectionCard(
          title: 'Recent Patients',
          child: Text('No patients found.', style: TextStyle(color: kMuted, fontSize: 13)),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.color,
    required this.bg,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kFieldFill)),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 1),
            Text(sublabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: kMuted)),
          ],
        ),
      ),
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
              Text(trend, style: const TextStyle(fontSize: 10, color: kMuted)),
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
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: kFieldFill)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/auth/screens/login_screen.dart';
import 'package:hms_mobile/features/pharmacy/models/pharmacy_dashboard_stats.dart';
import 'package:hms_mobile/features/pharmacy/screens/dispensing_create_screen.dart';
import 'package:hms_mobile/features/pharmacy/screens/dispensing_screen.dart';
import 'package:hms_mobile/features/pharmacy/screens/drug_master_screen.dart';
import 'package:hms_mobile/features/pharmacy/screens/pharmacy_profile_screen.dart';
import 'package:hms_mobile/features/pharmacy/viewmodels/pharmacy_dashboard_view_model.dart';
import 'package:hms_mobile/features/settings/screens/appearance_screen.dart';

/// The pharmacist's home shell — dispensing, the drug master and the
/// profile, with the centre button starting a new dispensing.
class PharmacistHomeScreen extends StatelessWidget {
  final AppUser user;
  const PharmacistHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PharmacyDashboardViewModel(user: user),
      child: const CareTheme(child: _PharmacyShell()),
    );
  }
}

enum _Target { dispensing, drugs, profile, appearance }

Widget _screenFor(_Target target) => switch (target) {
      _Target.dispensing => const DispensingScreen(),
      _Target.drugs => const DrugMasterScreen(),
      _Target.profile => const PharmacyProfileScreen(),
      _Target.appearance => const AppearanceScreen(),
    };

void _open(BuildContext context, _Target target) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => _screenFor(target)));
}

class _PharmacyShell extends StatelessWidget {
  const _PharmacyShell();

  Future<void> _logout(BuildContext context, PharmacyDashboardViewModel viewModel) async {
    await viewModel.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _newDispensing(BuildContext context, PharmacyDashboardViewModel viewModel) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DispensingCreateScreen()),
    );
    if (created == true) viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<PharmacyDashboardViewModel>();

    return Scaffold(
      backgroundColor: kCareBg,
      drawer: _PharmacyDrawer(
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
          centerIcon: Icons.add_rounded,
          onCenterTap: () => _newDispensing(context, viewModel),
          onSelected: (i) {
            switch (i) {
              case 1:
                _open(context, _Target.dispensing);
              case 2:
                _open(context, _Target.drugs);
              case 3:
                _open(context, _Target.profile);
            }
          },
          items: const [
            CareNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
            CareNavItem(icon: Icons.local_pharmacy_outlined, activeIcon: Icons.local_pharmacy_rounded, label: 'Dispense'),
            CareNavItem(icon: Icons.medication_outlined, activeIcon: Icons.medication_rounded, label: 'Drugs'),
            CareNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _PharmacyDrawer extends StatelessWidget {
  final AppUser user;
  final bool isLoggingOut;
  final VoidCallback onLogout;

  const _PharmacyDrawer({required this.user, required this.isLoggingOut, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
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
              children: const [
                _DrawerGroup(label: 'MAIN', items: [
                  _DrawerItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
                ]),
                _DrawerGroup(label: 'PHARMACY', items: [
                  _DrawerItem(icon: Icons.local_pharmacy_rounded, label: 'Dispensing', target: _Target.dispensing),
                  _DrawerItem(icon: Icons.medication_rounded, label: 'Drug Master', target: _Target.drugs),
                ]),
                _DrawerGroup(label: 'ACCOUNT', items: [
                  _DrawerItem(icon: Icons.person_rounded, label: 'My Profile', target: _Target.profile),
                  _DrawerItem(icon: Icons.palette_rounded, label: 'Appearance', target: _Target.appearance),
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
          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kCare, letterSpacing: 0.8)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: CareIconBox(icon: icon, size: 34, filled: false),
      title: Text(label, style: const TextStyle(fontSize: 14, color: kInk, fontWeight: FontWeight.w600)),
      onTap: () {
        Navigator.of(context).pop();
        if (target != null) _open(context, target!);
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final PharmacyDashboardViewModel viewModel;
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
            _PharmacyHeader(user: viewModel.user, stats: stats),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: CareSectionTitle(title: 'Quick actions'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  CareOptionTile(
                    icon: Icons.local_pharmacy_rounded,
                    title: 'Dispensing',
                    subtitle: 'Hand out medicines, see history',
                    onTap: () => _open(context, _Target.dispensing),
                  ),
                  const SizedBox(height: 10),
                  CareOptionTile(
                    icon: Icons.medication_rounded,
                    title: 'Drug Master',
                    subtitle: 'Stock, prices and expiry',
                    onTap: () => _open(context, _Target.drugs),
                  ),
                  const SizedBox(height: 10),
                  CareOptionTile(
                    icon: Icons.person_rounded,
                    title: 'My Profile',
                    subtitle: 'Account details and password',
                    onTap: () => _open(context, _Target.profile),
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
                  CareStatCard(icon: Icons.medication_rounded, label: 'Total Drugs', value: '${stats.totalDrugs}', trend: 'In the master'),
                  CareStatCard(icon: Icons.warning_amber_rounded, label: 'Low Stock', value: '${stats.lowStock}', trend: 'Reorder soon', alert: stats.lowStock > 0),
                  CareStatCard(icon: Icons.local_pharmacy_rounded, label: 'Dispensed Today', value: '${stats.dispensedToday}', trend: 'Handed out'),
                  CareStatCard(icon: Icons.event_busy_rounded, label: 'Near Expiry', value: '${stats.nearExpiry}', trend: 'Check batches', alert: stats.nearExpiry > 0),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
        Positioned(top: 0, left: 0, right: 0, height: topInset, child: ColoredBox(color: kCare)),
      ],
    );
  }
}

class _PharmacyHeader extends StatelessWidget {
  final AppUser user;
  final PharmacyDashboardStats stats;

  const _PharmacyHeader({required this.user, required this.stats});

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
                          Text('Pharmacist', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5)),
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
                        icon: Icons.warning_amber_rounded,
                        label: 'Low stock',
                        value: '${stats.lowStock}',
                        urgent: stats.lowStock > 0,
                        onTap: () => _open(context, _Target.drugs),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CareAlertPill(
                        icon: Icons.event_busy_rounded,
                        label: 'Near expiry',
                        value: '${stats.nearExpiry}',
                        urgent: stats.nearExpiry > 0,
                        onTap: () => _open(context, _Target.drugs),
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
                  (Icons.medication_rounded, '${stats.totalDrugs}', 'Drugs'),
                  (Icons.local_pharmacy_rounded, '${stats.dispensedToday}', 'Today'),
                  (Icons.warning_amber_rounded, '${stats.lowStock}', 'Low stock'),
                ]) ...[
                  if (item.$3 != 'Drugs') VerticalDivider(width: 1, indent: 20, endIndent: 20, color: kCareBorder),
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

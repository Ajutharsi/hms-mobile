import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/auth/screens/login_screen.dart';
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

/// The nurse's home shell — an AppBar + Drawer (mirrors the web sidebar's
/// MAIN/PATIENT/HOSPITAL/WARD/STAFF groups) around the Dashboard body.
/// Unlike the patient app's 5-tab bottom nav, the nurse portal has 18
/// sections — too many for a bottom nav, so it follows the web's own
/// persistent-sidebar structure instead, as a drawer.
class NurseHomeScreen extends StatelessWidget {
  final AppUser user;
  const NurseHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NurseDashboardViewModel(user: user),
      child: const _NurseShell(),
    );
  }
}

class _NurseShell extends StatelessWidget {
  const _NurseShell();

  Future<void> _logout(BuildContext context, NurseDashboardViewModel viewModel) async {
    await viewModel.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NurseDashboardViewModel>();

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
            Text(viewModel.user.firstName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: viewModel.isLoggingOut
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kTeal))
                : const Icon(Icons.logout_rounded, color: kMuted),
            onPressed: viewModel.isLoggingOut ? null : () => _logout(context, viewModel),
          ),
        ],
      ),
      drawer: const _NurseDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          color: kTeal,
          onRefresh: viewModel.load,
          child: _DashboardBody(viewModel: viewModel),
        ),
      ),
    );
  }
}

class _NurseDrawer extends StatelessWidget {
  const _NurseDrawer();

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
            _DrawerGroup(label: 'MAIN', items: [
              _DrawerItem(icon: Icons.dashboard_outlined, label: 'Dashboard', onTap: (ctx) => Navigator.of(ctx).pop()),
            ]),
            _DrawerGroup(label: 'PATIENT', items: [
              _DrawerItem(icon: Icons.people_outline, label: 'Patients', builder: (_) => const PatientsScreen()),
            ]),
            _DrawerGroup(label: 'HOSPITAL', items: [
              _DrawerItem(icon: Icons.assignment_outlined, label: 'Consent Forms', builder: (_) => const ConsentFormsScreen()),
              _DrawerItem(icon: Icons.local_hospital_outlined, label: 'Emergency (ER)', builder: (_) => const ErScreen()),
            ]),
            _DrawerGroup(label: 'WARD', items: [
              _DrawerItem(icon: Icons.holiday_village_outlined, label: 'Ward', builder: (_) => const WardScreen()),
              _DrawerItem(icon: Icons.bed_outlined, label: 'Admissions', builder: (_) => const AdmissionsScreen()),
              _DrawerItem(icon: Icons.medication_outlined, label: 'eMAR', builder: (_) => const EmarScreen()),
              _DrawerItem(icon: Icons.favorite_border, label: 'Vitals', builder: (_) => const VitalsScreen()),
              _DrawerItem(icon: Icons.description_outlined, label: 'Nursing Notes', builder: (_) => const NursingNotesScreen()),
              _DrawerItem(icon: Icons.swap_horiz_rounded, label: 'Shift Handover', builder: (_) => const ShiftHandoverScreen()),
              _DrawerItem(icon: Icons.medical_services_outlined, label: 'Operation Theatre', builder: (_) => const OtScreen()),
              _DrawerItem(icon: Icons.monitor_heart_outlined, label: 'ICU Charting', builder: (_) => const IcuScreen()),
              _DrawerItem(icon: Icons.water_drop_outlined, label: 'Blood Bank', builder: (_) => const BloodBankScreen()),
            ]),
            _DrawerGroup(label: 'STAFF', items: [
              _DrawerItem(icon: Icons.restaurant_outlined, label: 'Food Intake', builder: (_) => const FoodIntakeScreen()),
              _DrawerItem(icon: Icons.opacity_outlined, label: 'Fluid Intake', builder: (_) => const FluidIntakeScreen()),
              _DrawerItem(icon: Icons.groups_outlined, label: 'Staff Rounds', builder: (_) => const StaffRoundsScreen()),
              _DrawerItem(icon: Icons.schedule_outlined, label: 'My Rounds', builder: (_) => const MyRoundsScreen()),
              _DrawerItem(icon: Icons.person_outline, label: 'My Profile', builder: (_) => const NurseProfileScreen()),
            ]),
            const SizedBox(height: 16),
          ],
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.6),
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
  final WidgetBuilder? builder;
  final void Function(BuildContext)? onTap;
  const _DrawerItem({required this.icon, required this.label, this.builder, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      leading: Icon(icon, size: 20, color: kMuted),
      title: Text(label, style: const TextStyle(fontSize: 14, color: kInk, fontWeight: FontWeight.w500)),
      onTap: () {
        if (onTap != null) {
          onTap!(context);
          return;
        }
        Navigator.of(context).pop();
        if (builder != null) {
          Navigator.of(context).push(MaterialPageRoute(builder: builder!));
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
            _StatCard(icon: Icons.bed_outlined, color: kTealDark, bg: kMint, label: 'IP Patients', value: '${stats.ipPatients}', trend: 'Currently admitted'),
            _StatCard(
              icon: Icons.alarm_outlined,
              color: stats.overdueRounds > 0 ? kDangerFg : kSuccessFg,
              bg: stats.overdueRounds > 0 ? kDangerBg : kSuccessBg,
              label: 'Overdue Rounds',
              value: '${stats.overdueRounds}',
              trend: stats.overdueRounds > 0 ? 'Need attention!' : 'All on track',
            ),
            _StatCard(icon: Icons.restaurant_outlined, color: kWarningFg, bg: kWarningBg, label: 'Food Logs Today', value: '${stats.foodLogsToday}', trend: 'Meals logged'),
            _StatCard(icon: Icons.water_drop_outlined, color: kInfoFg, bg: kInfoBg, label: 'Fluid Logs Today', value: '${stats.fluidLogsToday}', trend: 'Fluid entries'),
            _StatCard(
              icon: Icons.medication_outlined,
              color: stats.pendingMedications > 0 ? kWarningFg : kSuccessFg,
              bg: stats.pendingMedications > 0 ? kWarningBg : kSuccessBg,
              label: 'Pending Medications',
              value: '${stats.pendingMedications}',
              trend: 'eMAR scheduled',
            ),
            _StatCard(
              icon: Icons.favorite_border,
              color: stats.needsVitalsCheck > 0 ? kDangerFg : kSuccessFg,
              bg: stats.needsVitalsCheck > 0 ? kDangerBg : kSuccessBg,
              label: 'Needs Vitals Check',
              value: '${stats.needsVitalsCheck}',
              trend: 'No reading in 4h',
            ),
            _StatCard(icon: Icons.description_outlined, color: kInfoFg, bg: kInfoBg, label: 'Nursing Notes Today', value: '${stats.nursingNotesToday}', trend: 'Written today'),
            _StatCard(
              icon: Icons.swap_horiz_rounded,
              color: stats.pendingHandovers > 0 ? kWarningFg : kSuccessFg,
              bg: stats.pendingHandovers > 0 ? kWarningBg : kSuccessBg,
              label: 'Pending Handovers',
              value: '${stats.pendingHandovers}',
              trend: 'Awaiting your acceptance',
            ),
            _StatCard(icon: Icons.assignment_turned_in_outlined, color: kInfoFg, bg: kInfoBg, label: "Today's Handovers", value: '${stats.todaysHandovers}', trend: 'Handed over today'),
          ],
        ),
        const SizedBox(height: 24),
        _SectionCard(
          title: "Today's Appointments",
          child: viewModel.todayAppointments.isEmpty
              ? const Text('No appointments today.', style: TextStyle(color: kMuted, fontSize: 13))
              : Column(
                  children: [
                    for (final a in viewModel.todayAppointments) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.patientName ?? 'Patient', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kInk)),
                                const SizedBox(height: 2),
                                Text('${a.doctorName ?? ''} · ${a.time}', style: const TextStyle(fontSize: 12, color: kMuted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(color: kMint, borderRadius: BorderRadius.circular(8)),
                            child: Text(a.type.toUpperCase(), style: const TextStyle(color: kTealDark, fontSize: 10.5, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      if (a != viewModel.todayAppointments.last)
                        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: kFieldFill)),
                    ],
                  ],
                ),
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
      (Icons.holiday_village_outlined, 'Ward', 'Beds & wards', kInfoFg, kInfoBg, (BuildContext c) => const WardScreen()),
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

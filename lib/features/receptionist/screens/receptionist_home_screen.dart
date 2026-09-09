import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/widgets/role_home_header.dart';
import 'package:hms_mobile/features/auth/screens/login_screen.dart';
import 'package:hms_mobile/features/nurse/screens/admissions_screen.dart';
import 'package:hms_mobile/features/nurse/screens/consent_forms_screen.dart';
import 'package:hms_mobile/features/nurse/screens/er_screen.dart';
import 'package:hms_mobile/features/nurse/screens/ward_screen.dart';
import 'package:hms_mobile/features/lab/screens/lab_orders_screen.dart';
import 'package:hms_mobile/features/lab/screens/lab_tests_screen.dart';
import 'package:hms_mobile/features/pharmacy/screens/dispensing_screen.dart';
import 'package:hms_mobile/features/receptionist/screens/insurance_claims_screen.dart';
import 'package:hms_mobile/features/receptionist/screens/invoices_screen.dart';
import 'package:hms_mobile/features/receptionist/screens/ipd_deposits_screen.dart';
import 'package:hms_mobile/features/receptionist/screens/opd_queue_screen.dart';
import 'package:hms_mobile/features/receptionist/screens/radiology_screen.dart';
import 'package:hms_mobile/features/receptionist/screens/reception_appointments_screen.dart';
import 'package:hms_mobile/features/receptionist/screens/reception_patients_screen.dart';
import 'package:hms_mobile/features/receptionist/screens/reception_profile_screen.dart';
import 'package:hms_mobile/features/receptionist/screens/referrals_screen.dart';
import 'package:hms_mobile/features/receptionist/screens/scheme_billing_screen.dart';
import 'package:hms_mobile/features/receptionist/viewmodels/reception_dashboard_view_model.dart';

/// The receptionist role's home shell — the largest sidebar in this app.
/// Ward/Admissions/Consent Forms/Emergency/Lab Tests/Lab Orders reuse the
/// nurse and lab feature screens directly (same shared backend routes —
/// see NurseController's authNurseOrReceptionist() and
/// LabAssistantController's authLabAssistantOrReceptionist()); everything
/// else here is receptionist-specific.
class ReceptionistHomeScreen extends StatelessWidget {
  final AppUser user;
  const ReceptionistHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReceptionDashboardViewModel(user: user),
      child: const _ReceptionistShell(),
    );
  }
}

class _ReceptionistShell extends StatelessWidget {
  const _ReceptionistShell();

  Future<void> _logout(BuildContext context, ReceptionDashboardViewModel viewModel) async {
    await viewModel.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReceptionDashboardViewModel>();

    return Scaffold(
      backgroundColor: kBg,
      appBar: RoleHomeHeader(
        firstName: viewModel.user.firstName,
        isLoggingOut: viewModel.isLoggingOut,
        onLogout: () => _logout(context, viewModel),
      ),
      drawer: const _ReceptionistDrawer(),
      body: SafeArea(
        child: RefreshIndicator(color: kTeal, onRefresh: viewModel.load, child: _DashboardBody(viewModel: viewModel)),
      ),
    );
  }
}

class _ReceptionistDrawer extends StatelessWidget {
  const _ReceptionistDrawer();

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
            _DrawerTile(icon: Icons.dashboard_outlined, label: 'Dashboard', onTap: () => Navigator.of(context).pop()),
            const _DrawerGroupLabel('PATIENT'),
            _DrawerTile(icon: Icons.people_outline, label: 'Patients', builder: (_) => const ReceptionPatientsScreen()),
            const _DrawerGroupLabel('HOSPITAL'),
            _DrawerTile(icon: Icons.event_outlined, label: 'Appointments', builder: (_) => const ReceptionAppointmentsScreen()),
            _DrawerTile(icon: Icons.compare_arrows_outlined, label: 'Referrals', builder: (_) => const ReferralsScreen()),
            _DrawerTile(icon: Icons.assignment_outlined, label: 'Consent Forms', builder: (_) => const ConsentFormsScreen()),
            _DrawerTile(icon: Icons.confirmation_number_outlined, label: 'OPD Queue', builder: (_) => const OpdQueueScreen()),
            _DrawerTile(icon: Icons.local_hospital_outlined, label: 'Emergency (ER)', builder: (_) => const ErScreen()),
            const _DrawerGroupLabel('WARD'),
            _DrawerTile(icon: Icons.holiday_village_outlined, label: 'Ward', builder: (_) => const WardScreen()),
            _DrawerTile(icon: Icons.bed_outlined, label: 'Admissions', builder: (_) => const AdmissionsScreen()),
            const _DrawerGroupLabel('PHARMACY'),
            _DrawerTile(icon: Icons.local_pharmacy_outlined, label: 'Dispensing', builder: (_) => const DispensingScreen(canCreate: false)),
            const _DrawerGroupLabel('LABORATORY'),
            _DrawerTile(icon: Icons.science_outlined, label: 'Lab Tests', builder: (_) => const LabTestsScreen()),
            _DrawerTile(icon: Icons.assignment_outlined, label: 'Lab Orders', builder: (_) => const LabOrdersScreen()),
            _DrawerTile(icon: Icons.camera_outlined, label: 'Radiology', builder: (_) => const RadiologyScreen()),
            const _DrawerGroupLabel('BILLING'),
            _DrawerTile(icon: Icons.receipt_long_outlined, label: 'Invoices', builder: (_) => const InvoicesScreen()),
            _DrawerTile(icon: Icons.shield_outlined, label: 'Insurance Claims', builder: (_) => const InsuranceClaimsScreen()),
            _DrawerTile(icon: Icons.account_balance_wallet_outlined, label: 'IPD Deposits', builder: (_) => const IpdDepositsScreen()),
            _DrawerTile(icon: Icons.request_quote_outlined, label: 'Scheme Billing', builder: (_) => const SchemeBillingScreen()),
            const _DrawerGroupLabel('MAIN'),
            _DrawerTile(icon: Icons.person_outline, label: 'My Profile', builder: (_) => const ReceptionProfileScreen()),
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
  final WidgetBuilder? builder;
  final VoidCallback? onTap;
  const _DrawerTile({required this.icon, required this.label, this.builder, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      leading: Icon(icon, size: 20, color: kMuted),
      title: Text(label, style: const TextStyle(fontSize: 14, color: kInk, fontWeight: FontWeight.w500)),
      onTap: () {
        if (onTap != null) {
          onTap!();
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
  final ReceptionDashboardViewModel viewModel;
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
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [
            _QuickActionTile(icon: Icons.people_outline, color: kTealDark, bg: kMint, label: 'Patients', sublabel: 'Search records', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReceptionPatientsScreen()))),
            _QuickActionTile(icon: Icons.event_outlined, color: kInfoFg, bg: kInfoBg, label: 'Appointments', sublabel: 'Book a visit', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReceptionAppointmentsScreen()))),
            _QuickActionTile(icon: Icons.confirmation_number_outlined, color: kWarningFg, bg: kWarningBg, label: 'OPD Queue', sublabel: 'Manage queue', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OpdQueueScreen()))),
            _QuickActionTile(icon: Icons.receipt_long_outlined, color: kSuccessFg, bg: kSuccessBg, label: 'Invoices', sublabel: 'Billing', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InvoicesScreen()))),
            _QuickActionTile(icon: Icons.bed_outlined, color: kTealDark, bg: kMint, label: 'Ward', sublabel: 'Beds & wards', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WardScreen()))),
            _QuickActionTile(icon: Icons.person_outline, color: kSuccessFg, bg: kSuccessBg, label: 'My Profile', sublabel: 'Account', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReceptionProfileScreen()))),
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
            _StatCard(icon: Icons.event_outlined, color: kTealDark, bg: kMint, label: "Today's Appointments", value: '${stats.todayAppointments}', trend: 'Today'),
            _StatCard(icon: Icons.people_outline, color: kSuccessFg, bg: kSuccessBg, label: 'Total Patients', value: '${stats.totalPatients}', trend: 'All registered'),
            _StatCard(icon: Icons.receipt_long_outlined, color: kWarningFg, bg: kWarningBg, label: 'Pending Invoices', value: '${stats.pendingInvoices}', trend: 'Unpaid'),
            _StatCard(icon: Icons.bed_outlined, color: kInfoFg, bg: kInfoBg, label: 'Available Beds', value: '${stats.availableBeds}', trend: 'Ready'),
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
                      if (a != viewModel.todayAppointments.last) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: kFieldFill)),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Recent Patients',
          actionLabel: 'View All',
          onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReceptionPatientsScreen())),
          child: viewModel.recentPatients.isEmpty
              ? const Text('No patients found.', style: TextStyle(color: kMuted, fontSize: 13))
              : Column(
                  children: [
                    for (final p in viewModel.recentPatients) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: kMint,
                            backgroundImage: p.photoUrl != null ? NetworkImage(p.photoUrl!) : null,
                            child: p.photoUrl == null ? Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12, color: kTealDark, fontWeight: FontWeight.w700)) : null,
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
                      if (p != viewModel.recentPatients.last) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: kFieldFill)),
                    ],
                  ],
                ),
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

  const _QuickActionTile({required this.icon, required this.color, required this.bg, required this.label, required this.sublabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kInk)),
            Text(sublabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: kMuted)),
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
              Container(width: 30, height: 30, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: color, size: 16)),
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
              if (actionLabel != null) InkWell(onTap: onAction, child: Text(actionLabel!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kTealDark))),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

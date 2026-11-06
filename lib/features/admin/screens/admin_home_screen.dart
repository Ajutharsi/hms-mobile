import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/admin/screens/admin_attendance_screen.dart';
import 'package:hms_mobile/features/admin/screens/admin_doctors_screen.dart';
import 'package:hms_mobile/features/admin/screens/admin_inventory_screen.dart';
import 'package:hms_mobile/features/admin/screens/admin_leaves_screen.dart';
import 'package:hms_mobile/features/admin/screens/admin_purchase_orders_screen.dart';
import 'package:hms_mobile/features/admin/screens/admin_reports_screen.dart';
import 'package:hms_mobile/features/admin/screens/admin_settings_screen.dart';
import 'package:hms_mobile/features/admin/screens/admin_simple_screens.dart';
import 'package:hms_mobile/features/admin/screens/admin_users_screen.dart';
import 'package:hms_mobile/features/auth/screens/login_screen.dart';
import 'package:hms_mobile/features/lab/screens/lab_orders_screen.dart';
import 'package:hms_mobile/features/lab/screens/lab_tests_screen.dart';
import 'package:hms_mobile/features/nurse/screens/admissions_screen.dart';
import 'package:hms_mobile/features/nurse/screens/blood_bank_screen.dart';
import 'package:hms_mobile/features/nurse/screens/consent_forms_screen.dart';
import 'package:hms_mobile/features/nurse/screens/emar_screen.dart';
import 'package:hms_mobile/features/nurse/screens/er_screen.dart';
import 'package:hms_mobile/features/nurse/screens/fluid_intake_screen.dart';
import 'package:hms_mobile/features/nurse/screens/food_intake_screen.dart';
import 'package:hms_mobile/features/nurse/screens/icu_screen.dart';
import 'package:hms_mobile/features/nurse/screens/nursing_notes_screen.dart';
import 'package:hms_mobile/features/nurse/screens/ot_screen.dart';
import 'package:hms_mobile/features/nurse/screens/shift_handover_screen.dart';
import 'package:hms_mobile/features/nurse/screens/staff_rounds_screen.dart';
import 'package:hms_mobile/features/nurse/screens/vitals_screen.dart';
import 'package:hms_mobile/features/nurse/screens/ward_screen.dart';
import 'package:hms_mobile/features/pharmacy/screens/dispensing_screen.dart';
import 'package:hms_mobile/features/pharmacy/screens/drug_master_screen.dart';
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
import 'package:hms_mobile/features/settings/screens/appearance_screen.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';

/// The administrator's home.
///
/// An admin's web sidebar is every other role's sidebar put together, and
/// the screens for all of it already exist here — built for the nurse, the
/// front desk, the lab and the pharmacy. This shell is the way in; nothing
/// below is a new screen.
///
/// The modules an admin has on the web but the app has not got yet —
/// Inventory, HR, Reports, User and Staff Management, Settings — are not
/// listed, rather than listed and dead.
///
/// The header numbers come from the front desk's dashboard endpoint, which
/// an admin may now call. They are hospital-wide counts, so they are the
/// right numbers; when the admin analytics endpoint exists this should
/// move onto it.
class AdminHomeScreen extends StatelessWidget {
  final AppUser user;
  const AdminHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReceptionDashboardViewModel(user: user),
      child: const CareTheme(child: _AdminShell()),
    );
  }
}

enum AdminSection {
  patients, appointments, referrals, consent, opdQueue, er,
  ward, admissions, emar, vitals, nursingNotes, handover, ot, icu, bloodBank,
  drugs, dispensing, labTests, labOrders, radiology,
  invoices, insurance, deposits, schemeBilling,
  foodIntake, fluidIntake, staffRounds,
  // Admin-only: these have no clinical owner, so they run on api/admin.
  reports, doctorsAdmin, users, staffAdmin,
  inventory, purchaseOrders, services,
  attendance, leaves, notifications, activityLog, settings,
  profile, appearance,
}

Widget _screenFor(AdminSection section) => switch (section) {
      AdminSection.patients => const ReceptionPatientsScreen(),
      AdminSection.appointments => const ReceptionAppointmentsScreen(canOpenConsultation: true),
      AdminSection.referrals => const ReferralsScreen(),
      AdminSection.consent => const ConsentFormsScreen(),
      AdminSection.opdQueue => const OpdQueueScreen(),
      AdminSection.er => const ErScreen(),
      AdminSection.ward => const WardScreen(),
      AdminSection.admissions => const AdmissionsScreen(),
      AdminSection.emar => const EmarScreen(),
      AdminSection.vitals => const VitalsScreen(),
      AdminSection.nursingNotes => const NursingNotesScreen(),
      AdminSection.handover => const ShiftHandoverScreen(),
      AdminSection.ot => const OtScreen(),
      AdminSection.icu => const IcuScreen(),
      AdminSection.bloodBank => const BloodBankScreen(),
      AdminSection.drugs => const DrugMasterScreen(),
      AdminSection.dispensing => const DispensingScreen(),
      AdminSection.labTests => const LabTestsScreen(),
      AdminSection.labOrders => const LabOrdersScreen(),
      AdminSection.radiology => const RadiologyScreen(),
      AdminSection.invoices => const InvoicesScreen(),
      AdminSection.insurance => const InsuranceClaimsScreen(),
      AdminSection.deposits => const IpdDepositsScreen(),
      AdminSection.schemeBilling => const SchemeBillingScreen(),
      AdminSection.foodIntake => const FoodIntakeScreen(),
      AdminSection.fluidIntake => const FluidIntakeScreen(),
      AdminSection.staffRounds => const StaffRoundsScreen(),
      AdminSection.reports => const AdminReportsScreen(),
      AdminSection.doctorsAdmin => const AdminDoctorsScreen(),
      AdminSection.users => const AdminUsersScreen(),
      AdminSection.staffAdmin => const AdminStaffScreen(),
      AdminSection.inventory => const AdminInventoryScreen(),
      AdminSection.purchaseOrders => const AdminPurchaseOrdersScreen(),
      AdminSection.services => const AdminServicesScreen(),
      AdminSection.attendance => const AdminAttendanceScreen(),
      AdminSection.leaves => const AdminLeavesScreen(),
      AdminSection.notifications => const AdminNotificationsScreen(),
      AdminSection.activityLog => const AdminActivityLogScreen(),
      AdminSection.settings => const AdminSettingsScreen(),
      AdminSection.profile => const ReceptionProfileScreen(),
      AdminSection.appearance => const AppearanceScreen(),
    };

void _open(BuildContext context, AdminSection section) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => _screenFor(section)));
}

class _AdminShell extends StatelessWidget {
  const _AdminShell();

  Future<void> _logout(BuildContext context, ReceptionDashboardViewModel viewModel) async {
    await viewModel.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<ReceptionDashboardViewModel>();

    return Scaffold(
      backgroundColor: kCareBg,
      drawer: _AdminDrawer(
        user: viewModel.user,
        isLoggingOut: viewModel.isLoggingOut,
        onLogout: () => _logout(context, viewModel),
      ),
      body: RefreshIndicator(
        color: kCare,
        onRefresh: viewModel.load,
        child: _AdminBody(viewModel: viewModel),
      ),
    );
  }
}

class _AdminBody extends StatelessWidget {
  final ReceptionDashboardViewModel viewModel;
  const _AdminBody({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    if (viewModel.isLoading && viewModel.stats == null) return const CareStateView.loading();
    if (viewModel.loadError != null && viewModel.stats == null) return CareStateView.error(viewModel.loadError!);

    final stats = viewModel.stats;
    final topInset = MediaQuery.of(context).padding.top;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        CareHeaderBackground(
          padding: EdgeInsets.fromLTRB(20, topInset + 18, 20, 70),
          child: Row(
            children: [
              CareAvatar(name: viewModel.user.name, imageUrl: viewModel.user.profilePhotoUrl, radius: 28, ring: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hello 👋', style: CareText.onCareSoftSm),
                    Text(viewModel.user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.onCareTitle),
                    Text(viewModel.user.primaryRole, style: CareText.onCareSoftXs),
                  ],
                ),
              ),
              Builder(
                builder: (context) => InkWell(
                  borderRadius: BorderRadius.circular(CareRadius.panel),
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(color: kOnCareFaint.withValues(alpha: 0.18), shape: BoxShape.circle),
                    child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CareCard(
              child: Row(
                children: [
                  _Stat(icon: Icons.people_rounded, value: '${stats?.totalPatients ?? 0}', label: 'Patients'),
                  const _StatDivider(),
                  _Stat(icon: Icons.event_rounded, value: '${stats?.todayAppointments ?? 0}', label: 'Today'),
                  const _StatDivider(),
                  _Stat(icon: Icons.bed_rounded, value: '${stats?.availableBeds ?? 0}', label: 'Free beds'),
                ],
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -34),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick actions', style: CareText.titleH3),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                  children: const [
                    _Shortcut(icon: Icons.people_rounded, label: 'Patients', hint: 'All records', target: AdminSection.patients),
                    _Shortcut(icon: Icons.calendar_month_rounded, label: 'Appointments', hint: 'Whole day', target: AdminSection.appointments),
                    _Shortcut(icon: Icons.receipt_long_rounded, label: 'Invoices', hint: 'Billing', target: AdminSection.invoices),
                    _Shortcut(icon: Icons.holiday_village_rounded, label: 'Ward', hint: 'Beds', target: AdminSection.ward),
                    _Shortcut(icon: Icons.local_pharmacy_rounded, label: 'Pharmacy', hint: 'Drug master', target: AdminSection.drugs),
                    _Shortcut(icon: Icons.science_rounded, label: 'Lab', hint: 'Orders', target: AdminSection.labOrders),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: kCare),
              const SizedBox(width: 6),
              Text(value, style: CareText.titleH3),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.mutedSm),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Container(width: 1, height: 36, color: kCareBorder);
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final AdminSection target;
  const _Shortcut({required this.icon, required this.label, required this.hint, required this.target});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return InkWell(
      borderRadius: BorderRadius.circular(CareRadius.card),
      onTap: () => _open(context, target),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(CareRadius.card),
          border: Border.all(color: kCareBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CareIconBox(icon: icon, size: 42),
            const SizedBox(height: 10),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.titleSm),
            Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.mutedXs),
          ],
        ),
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  final AppUser user;
  final bool isLoggingOut;
  final VoidCallback onLogout;

  const _AdminDrawer({required this.user, required this.isLoggingOut, required this.onLogout});

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
                      Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.onCareTitle),
                      const SizedBox(height: 3),
                      Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.onCareSoftXs),
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
                  _DrawerItem(icon: Icons.people_rounded, label: 'Patients', target: AdminSection.patients),
                  _DrawerItem(icon: Icons.calendar_month_rounded, label: 'Appointments', target: AdminSection.appointments),
                  _DrawerItem(icon: Icons.compare_arrows_rounded, label: 'Referrals', target: AdminSection.referrals),
                  _DrawerItem(icon: Icons.assignment_rounded, label: 'Consent Forms', target: AdminSection.consent),
                  _DrawerItem(icon: Icons.confirmation_number_rounded, label: 'OPD Queue', target: AdminSection.opdQueue),
                  _DrawerItem(icon: Icons.local_hospital_rounded, label: 'Emergency (ER)', target: AdminSection.er),
                ]),
                _DrawerGroup(label: 'WARD', items: [
                  _DrawerItem(icon: Icons.holiday_village_rounded, label: 'Ward', target: AdminSection.ward),
                  _DrawerItem(icon: Icons.bed_rounded, label: 'Admissions', target: AdminSection.admissions),
                  _DrawerItem(icon: Icons.medication_rounded, label: 'eMAR', target: AdminSection.emar),
                  _DrawerItem(icon: Icons.favorite_rounded, label: 'Vitals', target: AdminSection.vitals),
                  _DrawerItem(icon: Icons.description_rounded, label: 'Nursing Notes', target: AdminSection.nursingNotes),
                  _DrawerItem(icon: Icons.swap_horiz_rounded, label: 'Shift Handover', target: AdminSection.handover),
                  _DrawerItem(icon: Icons.medical_services_rounded, label: 'Operation Theatre', target: AdminSection.ot),
                  _DrawerItem(icon: Icons.monitor_heart_rounded, label: 'ICU Charting', target: AdminSection.icu),
                  _DrawerItem(icon: Icons.water_drop_rounded, label: 'Blood Bank', target: AdminSection.bloodBank),
                ]),
                _DrawerGroup(label: 'PHARMACY', items: [
                  _DrawerItem(icon: Icons.inventory_2_rounded, label: 'Drug Master', target: AdminSection.drugs),
                  _DrawerItem(icon: Icons.local_pharmacy_rounded, label: 'Dispensing', target: AdminSection.dispensing),
                ]),
                _DrawerGroup(label: 'DIAGNOSTICS', items: [
                  _DrawerItem(icon: Icons.science_rounded, label: 'Lab Tests', target: AdminSection.labTests),
                  _DrawerItem(icon: Icons.assignment_turned_in_rounded, label: 'Lab Orders', target: AdminSection.labOrders),
                  _DrawerItem(icon: Icons.camera_rounded, label: 'Radiology', target: AdminSection.radiology),
                ]),
                _DrawerGroup(label: 'BILLING', items: [
                  _DrawerItem(icon: Icons.receipt_long_rounded, label: 'Invoices', target: AdminSection.invoices),
                  _DrawerItem(icon: Icons.verified_user_rounded, label: 'Insurance Claims', target: AdminSection.insurance),
                  _DrawerItem(icon: Icons.savings_rounded, label: 'IPD Deposits', target: AdminSection.deposits),
                  _DrawerItem(icon: Icons.local_offer_rounded, label: 'Scheme Billing', target: AdminSection.schemeBilling),
                ]),
                _DrawerGroup(label: 'STAFF', items: [
                  _DrawerItem(icon: Icons.restaurant_rounded, label: 'Food Intake', target: AdminSection.foodIntake),
                  _DrawerItem(icon: Icons.water_drop_outlined, label: 'Fluid Intake', target: AdminSection.fluidIntake),
                  _DrawerItem(icon: Icons.groups_rounded, label: 'Staff Rounds', target: AdminSection.staffRounds),
                ]),
                _DrawerGroup(label: 'MANAGE', items: [
                  _DrawerItem(icon: Icons.insert_chart_outlined_rounded, label: 'Reports', target: AdminSection.reports),
                  _DrawerItem(icon: Icons.medical_information_rounded, label: 'Doctors', target: AdminSection.doctorsAdmin),
                  _DrawerItem(icon: Icons.manage_accounts_rounded, label: 'User Management', target: AdminSection.users),
                  _DrawerItem(icon: Icons.groups_2_rounded, label: 'Staff', target: AdminSection.staffAdmin),
                  _DrawerItem(icon: Icons.local_offer_rounded, label: 'Billing Services', target: AdminSection.services),
                ]),
                _DrawerGroup(label: 'STORES', items: [
                  _DrawerItem(icon: Icons.inventory_2_rounded, label: 'Inventory', target: AdminSection.inventory),
                  _DrawerItem(icon: Icons.local_shipping_rounded, label: 'Purchase Orders', target: AdminSection.purchaseOrders),
                ]),
                _DrawerGroup(label: 'HR', items: [
                  _DrawerItem(icon: Icons.how_to_reg_rounded, label: 'Attendance', target: AdminSection.attendance),
                  _DrawerItem(icon: Icons.event_available_rounded, label: 'Leave Requests', target: AdminSection.leaves),
                ]),
                _DrawerGroup(label: 'SYSTEM', items: [
                  _DrawerItem(icon: Icons.tune_rounded, label: 'Settings', target: AdminSection.settings),
                  _DrawerItem(icon: Icons.history_rounded, label: 'Activity Log', target: AdminSection.activityLog),
                  _DrawerItem(icon: Icons.notifications_rounded, label: 'Notifications', target: AdminSection.notifications),
                ]),
                _DrawerGroup(label: 'ACCOUNT', items: [
                  _DrawerItem(icon: Icons.person_rounded, label: 'My Profile', target: AdminSection.profile),
                  _DrawerItem(icon: Icons.palette_rounded, label: 'Appearance', target: AdminSection.appearance),
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
          child: Text(label, style: CareText.overline),
        ),
        ...items,
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final AdminSection? target;
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
        if (target != null) _open(context, target!);
      },
    );
  }
}

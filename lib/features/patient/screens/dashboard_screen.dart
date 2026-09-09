import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/widgets/app_card.dart';
import 'package:hms_mobile/features/patient/models/appointment.dart';
import 'package:hms_mobile/features/patient/viewmodels/home_view_model.dart';
import 'package:hms_mobile/features/patient/viewmodels/profile_view_model.dart';

/// The Dashboard tab — the patient's landing page. Mirrors the web's
/// PatientDashboardController: a quick-actions row, the four "Overall
/// Statistics" cards (appointments/today/lab orders/MRN), a recent-
/// appointments preview and an account-info summary.
class DashboardTabBody extends StatelessWidget {
  final VoidCallback onBookAppointment;
  final void Function(int tabIndex) onNavigateTab;

  const DashboardTabBody({
    super.key,
    required this.onBookAppointment,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final homeViewModel = context.watch<HomeViewModel>();
    final profileViewModel = context.watch<ProfileViewModel>();
    final profile = profileViewModel.profile;
    final nextAppointment = homeViewModel.appointments.where((a) => a.isScheduled).toList();

    return RefreshIndicator(
      color: kTeal,
      onRefresh: () => Future.wait([
        homeViewModel.loadAppointments(),
        profileViewModel.load(),
      ]),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (nextAppointment.isNotEmpty) ...[
            _NextAppointmentHero(appointment: nextAppointment.first, onTap: () => onNavigateTab(1)),
            const SizedBox(height: 22),
          ],
          const Text('Quick actions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.3)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.event_outlined,
                  color: kTealDark,
                  bg: kMint,
                  label: 'Appointments',
                  sublabel: 'Book a visit',
                  onTap: onBookAppointment,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.biotech_outlined,
                  color: kInfoFg,
                  bg: kInfoBg,
                  label: 'Lab Results',
                  sublabel: 'Your results',
                  onTap: () => onNavigateTab(3),
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
                  onTap: () => onNavigateTab(5),
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
              _StatCard(
                icon: Icons.event_outlined,
                color: kTealDark,
                bg: kMint,
                label: 'My Appointments',
                value: '${profile?.stats.totalAppointments ?? homeViewModel.appointments.length}',
                trend: 'Total booked',
                onTap: () => onNavigateTab(1),
              ),
              _StatCard(
                icon: Icons.access_time_rounded,
                color: kWarningFg,
                bg: kWarningBg,
                label: "Today's Appts",
                value: '${profile?.stats.todayAppointments ?? 0}',
                trend: 'Today',
                onTap: () => onNavigateTab(1),
              ),
              _StatCard(
                icon: Icons.biotech_outlined,
                color: kInfoFg,
                bg: kInfoBg,
                label: 'Lab Orders',
                value: '${profile?.stats.labOrders ?? 0}',
                trend: 'Total',
                onTap: () => onNavigateTab(3),
              ),
              _StatCard(
                icon: Icons.badge_outlined,
                color: kSuccessFg,
                bg: kSuccessBg,
                label: 'MRN',
                value: profile?.mrn ?? '—',
                trend: 'Patient ID',
                valueFontSize: 15,
                onTap: () => onNavigateTab(5),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'My Appointments',
            actionLabel: 'View All',
            onAction: () => onNavigateTab(1),
            child: _RecentAppointments(
              appointments: homeViewModel.appointments.take(3).toList(),
              isLoading: homeViewModel.isLoading && homeViewModel.appointments.isEmpty,
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'My Information',
            actionLabel: 'Edit',
            onAction: () => onNavigateTab(5),
            child: _InfoSummary(
              name: profile?.name,
              email: profile?.email,
              phone: profile?.phone,
              mrn: profile?.mrn,
              isLoading: profileViewModel.isLoading && profile == null,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextAppointmentHero extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;

  const _NextAppointmentHero({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [kTeal, kTealDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: kTealDark.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEXT APPOINTMENT',
                style: kMonoStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8), letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Text(
                appointment.doctorName ?? 'Doctor',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              if ((appointment.doctorSpecialization ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(appointment.doctorSpecialization!, style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.85))),
                ),
              const SizedBox(height: 12),
              Text(
                [
                  appointment.date,
                  appointment.time,
                  if (appointment.tokenNumber != null) 'Token #${appointment.tokenNumber}',
                ].join('   ·   '),
                style: kMonoStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: kCoral, borderRadius: BorderRadius.circular(999)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View details', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
    return AppCard(
      radius: 16,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
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
  final double? valueFontSize;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.bg,
    required this.label,
    required this.value,
    required this.trend,
    required this.onTap,
    this.valueFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 18,
      onTap: onTap,
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
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.ibmPlexMono(fontSize: valueFontSize ?? 20, fontWeight: FontWeight.w700, color: kInk),
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk))),
              InkWell(
                onTap: onAction,
                child: Text(actionLabel, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kTealDark)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RecentAppointments extends StatelessWidget {
  final List<Appointment> appointments;
  final bool isLoading;

  const _RecentAppointments({required this.appointments, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: kTeal)),
      );
    }

    if (appointments.isEmpty) {
      return const Text('No appointments yet.', style: TextStyle(color: kMuted, fontSize: 13));
    }

    return Column(
      children: [
        for (final appointment in appointments) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName ?? 'Doctor',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kInk),
                    ),
                    const SizedBox(height: 2),
                    Text('${appointment.date} · ${appointment.time}', style: const TextStyle(fontSize: 12, color: kMuted)),
                  ],
                ),
              ),
              _StatusChip(status: appointment.status),
            ],
          ),
          if (appointment != appointments.last) const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: kFieldFill),
          ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      'scheduled' => (kMint, kTealDark, 'Scheduled'),
      'completed' => (kSuccessBg, kSuccessFg, 'Completed'),
      'cancelled' => (kFieldFill, kMuted, 'Cancelled'),
      'no_show' => (kDangerBg, kDangerFg, 'No-show'),
      _ => (kFieldFill, kMuted, status),
    };

    return StatusPill(label: label, bg: bg, fg: fg);
  }
}

class _InfoSummary extends StatelessWidget {
  final String? name;
  final String? email;
  final String? phone;
  final String? mrn;
  final bool isLoading;

  const _InfoSummary({
    required this.name,
    required this.email,
    required this.phone,
    required this.mrn,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: kTeal)),
      );
    }

    return Column(
      children: [
        _InfoRow(icon: Icons.person_outline, label: 'Name', value: name ?? '—'),
        _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email ?? '—'),
        _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: (phone == null || phone!.isEmpty) ? '—' : phone!),
        _InfoRow(icon: Icons.badge_outlined, label: 'MRN', value: mrn ?? '—', showDivider: false),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  const _InfoRow({required this.icon, required this.label, required this.value, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: kMuted),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 12.5, color: kMuted)),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk),
              ),
            ),
          ],
        ),
        if (showDivider) const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: kFieldFill),
        ),
      ],
    );
  }
}

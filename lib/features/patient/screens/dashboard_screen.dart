import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/patient/models/appointment.dart';
import 'package:hms_mobile/features/patient/models/patient_profile.dart';
import 'package:hms_mobile/features/patient/viewmodels/home_view_model.dart';
import 'package:hms_mobile/features/patient/viewmodels/profile_view_model.dart';

/// Every place the patient app can navigate to — the home shell decides
/// whether each one is a bottom-nav tab or a pushed page.
enum PatientSection { home, appointments, book, prescriptions, lab, bills, profile }

/// The Home tab — the patient's landing page. Mirrors the web's
/// PatientDashboardController: greeting, the stats (appointments / today /
/// lab orders), upcoming visits and shortcuts to every portal section.
class DashboardTabBody extends StatelessWidget {
  final void Function(PatientSection section) onOpen;

  const DashboardTabBody({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final homeViewModel = context.watch<HomeViewModel>();
    final profileViewModel = context.watch<ProfileViewModel>();
    final profile = profileViewModel.profile;
    final upcoming = homeViewModel.appointments.where((a) => a.isScheduled).toList()
      ..sort((a, b) => '${a.date} ${a.time}'.compareTo('${b.date} ${b.time}'));

    final topInset = MediaQuery.of(context).padding.top;

    // The header scrolls away with the page, so a fixed teal strip keeps the
    // status bar readable once content slides underneath it.
    return Stack(
      children: [
        _buildScroll(context, homeViewModel, profileViewModel, profile, upcoming),
        Positioned(top: 0, left: 0, right: 0, height: topInset, child: ColoredBox(color: kCare)),
      ],
    );
  }

  Widget _buildScroll(
    BuildContext context,
    HomeViewModel homeViewModel,
    ProfileViewModel profileViewModel,
    PatientProfile? profile,
    List<Appointment> upcoming,
  ) {
    return RefreshIndicator(
      color: kCare,
      edgeOffset: 120,
      onRefresh: () => Future.wait([
        homeViewModel.loadAppointments(),
        profileViewModel.load(),
      ]),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _HomeHeader(
            name: profile?.name ?? homeViewModel.user.name,
            mrn: profile?.mrn,
            photoUrl: profile?.profilePhotoUrl ?? homeViewModel.user.profilePhotoUrl,
            onAvatarTap: () => onOpen(PatientSection.profile),
            onSearchTap: () => onOpen(PatientSection.book),
            stats: _StatsStrip(
              stats: [
                _Stat(
                  value: '${profile?.stats.totalAppointments ?? homeViewModel.appointments.length}',
                  label: 'Appointments',
                  icon: Icons.calendar_month_rounded,
                  onTap: () => onOpen(PatientSection.appointments),
                ),
                _Stat(
                  value: '${profile?.stats.todayAppointments ?? 0}',
                  label: 'Today',
                  icon: Icons.today_rounded,
                  onTap: () => onOpen(PatientSection.appointments),
                ),
                _Stat(
                  value: '${profile?.stats.labOrders ?? 0}',
                  label: 'Lab orders',
                  icon: Icons.biotech_rounded,
                  onTap: () => onOpen(PatientSection.lab),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
            child: CareSectionTitle(
              title: 'Upcoming Appointments',
              actionLabel: 'See all',
              onAction: () => onOpen(PatientSection.appointments),
            ),
          ),
          _UpcomingStrip(
            appointments: upcoming,
            isLoading: homeViewModel.isLoading && homeViewModel.appointments.isEmpty,
            onBook: () => onOpen(PatientSection.book),
            onOpenAppointments: () => onOpen(PatientSection.appointments),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: CareSectionTitle(title: 'Options'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                CareOptionTile(
                  icon: Icons.event_available_rounded,
                  title: 'Book Appointment',
                  subtitle: 'Pick a doctor, date and time',
                  onTap: () => onOpen(PatientSection.book),
                ),
                const SizedBox(height: 10),
                CareOptionTile(
                  icon: Icons.medication_rounded,
                  title: 'My Prescriptions',
                  subtitle: 'Medicines your doctor prescribed',
                  onTap: () => onOpen(PatientSection.prescriptions),
                ),
                const SizedBox(height: 10),
                CareOptionTile(
                  icon: Icons.biotech_rounded,
                  title: 'Lab Results',
                  subtitle: 'Reports and test values',
                  onTap: () => onOpen(PatientSection.lab),
                ),
                const SizedBox(height: 10),
                CareOptionTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'Bills & Payments',
                  subtitle: 'Invoices and balances',
                  onTap: () => onOpen(PatientSection.bills),
                ),
                const SizedBox(height: 10),
                CareOptionTile(
                  icon: Icons.person_rounded,
                  title: 'My Profile',
                  subtitle: 'Account details and password',
                  onTap: () => onOpen(PatientSection.profile),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String name;
  final String? mrn;
  final String? photoUrl;
  final VoidCallback onAvatarTap;
  final VoidCallback onSearchTap;
  final Widget stats;

  const _HomeHeader({
    required this.name,
    required this.mrn,
    required this.photoUrl,
    required this.onAvatarTap,
    required this.onSearchTap,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final topInset = MediaQuery.of(context).padding.top;
    const statsOverlap = 46.0;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: statsOverlap),
          child: CareHeaderBackground(
            radius: 32,
            padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 24 + 62),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: onAvatarTap,
                      child: CareAvatar(name: name, imageUrl: photoUrl, radius: 25, ring: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello 👋', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                          ),
                          if ((mrn ?? '').isNotEmpty)
                            Text('MRN: $mrn', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5)),
                        ],
                      ),
                    ),
                    _HeaderIconButton(icon: Icons.menu_rounded, onTap: () => Scaffold.of(context).openDrawer()),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onSearchTap,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: kCare),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Find a doctor & book a visit', style: TextStyle(color: Color(0xFF9AA6A4), fontSize: 14)),
                        ),
                        Icon(Icons.tune_rounded, color: kCare, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(left: 20, right: 20, bottom: 0, child: stats),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, color: Colors.white, size: 22)),
      ),
    );
  }
}

class _Stat {
  final String value;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _Stat({required this.value, required this.label, required this.icon, required this.onTap});
}

class _StatsStrip extends StatelessWidget {
  final List<_Stat> stats;
  const _StatsStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x1A0E6B61), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) VerticalDivider(width: 1, indent: 20, endIndent: 20, color: kCareBorder),
            Expanded(
              child: InkWell(
                onTap: stats[i].onTap,
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(stats[i].icon, size: 16, color: kCare),
                        const SizedBox(width: 5),
                        Text(stats[i].value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: kInk)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(stats[i].label, style: const TextStyle(fontSize: 11.5, color: kMuted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpcomingStrip extends StatelessWidget {
  final List<Appointment> appointments;
  final bool isLoading;
  final VoidCallback onBook;
  final VoidCallback onOpenAppointments;

  const _UpcomingStrip({
    required this.appointments,
    required this.isLoading,
    required this.onBook,
    required this.onOpenAppointments,
  });

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    if (isLoading) {
      return SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: kCare)));
    }

    if (appointments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: CareCard(
          child: Row(
            children: [
              const CareIconBox(icon: Icons.event_busy_rounded, filled: false, size: 48),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No upcoming visits', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk)),
                    SizedBox(height: 2),
                    Text('Book one in a few taps.', style: TextStyle(fontSize: 12.5, color: kMuted)),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onBook,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Book', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 224,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: appointments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _UpcomingCard(appointment: appointments[index], onTap: onOpenAppointments),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;
  const _UpcomingCard({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final doctor = appointment.doctorName ?? 'Doctor';
    return SizedBox(
      width: 172,
      child: CareCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Column(
          children: [
            CareAvatar(name: doctor, radius: 28),
            const SizedBox(height: 10),
            Text(
              doctor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk),
            ),
            const SizedBox(height: 2),
            Text(
              (appointment.doctorSpecialization ?? '').isEmpty ? 'General' : appointment.doctorSpecialization!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: kMuted),
            ),
            const SizedBox(height: 8),
            CareChip(label: appointment.date, bg: kCarePinkBg, fg: kCarePinkFg),
            const Spacer(),
            Container(
              width: double.infinity,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: kCare, borderRadius: BorderRadius.circular(10)),
              child: Text(
                appointment.time.isEmpty ? 'View' : appointment.time,
                style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/features/doctor/screens/doctor_home_screen.dart';
import 'package:hms_mobile/features/lab/screens/lab_home_screen.dart';
import 'package:hms_mobile/features/nurse/screens/nurse_home_screen.dart';
import 'package:hms_mobile/features/patient/screens/home_screen.dart';
import 'package:hms_mobile/features/pharmacy/screens/pharmacist_home_screen.dart';
import 'package:hms_mobile/features/admin/screens/admin_home_screen.dart';
import 'package:hms_mobile/features/receptionist/screens/receptionist_home_screen.dart';
import 'package:hms_mobile/features/staff/screens/staff_home_screen.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/features/auth/screens/force_password_change_screen.dart';

/// Routes a freshly-logged-in (or restored-session) user to the right
/// role's home shell. Every role the web defines now has one. A role that
/// somehow reaches here without a shell -- a new one added on the web, say
/// -- gets a plain "not available yet" screen rather than a crash or a
/// silent wrong-role UI.
class RoleHome extends StatefulWidget {
  final AppUser user;
  const RoleHome({super.key, required this.user});

  @override
  State<RoleHome> createState() => _RoleHomeState();
}

class _RoleHomeState extends State<RoleHome> {
  /// Set once the password has actually been changed, so the shell is
  /// shown without having to re-fetch `/me` (which the server was
  /// refusing a moment ago anyway).
  bool _passwordChanged = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    // The hospital can force a password change; until it is done the API
    // answers 403 on everything except this one endpoint, so showing a
    // role shell here would be a screen of failures with no way out.
    if (user.mustChangePassword && !_passwordChanged) {
      return ForcePasswordChangeScreen(
        user: user,
        onChanged: () => setState(() => _passwordChanged = true),
      );
    }

    // Checked before the clinical roles: an administrator may also hold
    // one of them, and the admin shell is the superset.
    if (user.roles.contains('admin') || user.roles.contains('super_admin')) {
      return AdminHomeScreen(user: user);
    }
    if (user.roles.contains('doctor')) {
      return DoctorHomeScreen(user: user);
    }
    if (user.roles.contains('nurse')) {
      return NurseHomeScreen(user: user);
    }
    if (user.roles.contains('staff')) {
      return StaffHomeScreen(user: user);
    }
    if (user.roles.contains('lab_assistant')) {
      return LabHomeScreen(user: user);
    }
    if (user.roles.contains('receptionist')) {
      return ReceptionistHomeScreen(user: user);
    }
    if (user.roles.contains('pharmacist')) {
      return PharmacistHomeScreen(user: user);
    }
    if (user.roles.contains('patient')) {
      return HomeScreen(user: user);
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_rounded, size: 40, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'The "${user.primaryRole}" role isn\'t available in this app yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: CareText.lg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/features/doctor/screens/doctor_home_screen.dart';
import 'package:hms_mobile/features/lab/screens/lab_home_screen.dart';
import 'package:hms_mobile/features/nurse/screens/nurse_home_screen.dart';
import 'package:hms_mobile/features/patient/screens/home_screen.dart';
import 'package:hms_mobile/features/pharmacy/screens/pharmacist_home_screen.dart';
import 'package:hms_mobile/features/receptionist/screens/receptionist_home_screen.dart';
import 'package:hms_mobile/features/staff/screens/staff_home_screen.dart';

/// Routes a freshly-logged-in (or restored-session) user to the right
/// role's home shell. Patient, doctor, nurse, staff, lab_assistant,
/// receptionist and pharmacist have a mobile build; admin and super_admin
/// stay web-only and see a plain "not available yet" screen rather than a
/// crash or a silent wrong-role UI.
class RoleHome extends StatelessWidget {
  final AppUser user;
  const RoleHome({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
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
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

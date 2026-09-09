import 'package:flutter/material.dart';

import 'package:hms_mobile/core/theme/app_style.dart';

/// The greeting header shared by every role's home shell: an initials
/// avatar, "Good to see you," + first name, and a trailing action (usually
/// log out). Kept as one widget so all six roles read as the same app
/// instead of six copy-pasted AppBar titles drifting apart over time.
class RoleHomeHeader extends StatelessWidget implements PreferredSizeWidget {
  final String firstName;
  final bool isLoggingOut;
  final VoidCallback onLogout;

  const RoleHomeHeader({super.key, required this.firstName, required this.isLoggingOut, required this.onLogout});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: kBg,
      foregroundColor: kInk,
      elevation: 0,
      toolbarHeight: 72,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kTeal, kTealDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Good to see you,', style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w500)),
              Text(firstName, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: kInk)),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11), border: Border.all(color: kBorder)),
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: 'Log out',
            icon: isLoggingOut
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kTeal))
                : const Icon(Icons.logout_rounded, color: kMuted, size: 19),
            onPressed: isLoggingOut ? null : onLogout,
          ),
        ),
      ],
    );
  }
}

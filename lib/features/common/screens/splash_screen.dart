import 'package:flutter/material.dart';

import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';

/// What the app shows while it checks for a saved login.
///
/// This used to be a bare spinner on a grey screen, which looked like a
/// page that had failed to load rather than the app starting up.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: kCareBg,
      body: Stack(
        children: [
          CareHeaderBackground(
            radius: 36,
            padding: EdgeInsets.fromLTRB(24, topInset + 28, 24, 0),
            child: const SizedBox.expand(),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(CareRadius.panel),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8))],
                  ),
                  child: Icon(Icons.medical_services_rounded, color: kCare, size: 42),
                ),
                const SizedBox(height: 18),
                const Text('HMS India', style: CareText.onCareDisplay),
                const SizedBox(height: 6),
                Text(
                  'Care, coordinated.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: CareText.md),
                ),
                const SizedBox(height: 34),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.9)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

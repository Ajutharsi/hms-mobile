import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:hms_mobile/core/theme/app_style.dart';

/// The illustration side panel shown only on wide (web/desktop) viewports,
/// shared by the login and register screens with different copy.
class AuthIllustrationPane extends StatelessWidget {
  final String headline;
  final String subtext;

  const AuthIllustrationPane({super.key, required this.headline, required this.subtext});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kMint,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(top: -60, right: -80, child: _blob(220, const Color(0xFFD6E1FF))),
          Positioned(bottom: -90, left: -60, child: _blob(260, const Color(0xFFDCE6FF))),
          Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 380),
                      child: SvgPicture.asset('assets/illustrations/doctors_duo.svg'),
                    ),
                    const Positioned(bottom: 28, right: 18, child: AuthPulseBadge()),
                  ],
                ),
                const SizedBox(height: 36),
                Text(
                  headline,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kInk),
                ),
                const SizedBox(height: 8),
                Text(
                  subtext,
                  style: const TextStyle(fontSize: 14.5, color: kMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class AuthPulseBadge extends StatelessWidget {
  const AuthPulseBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.monitor_heart_rounded, color: kTeal, size: 28),
    );
  }
}

/// A compact version of the same illustration for narrow (phone) screens,
/// where there's no room for the full side-by-side split layout.
class AuthCompactIllustration extends StatelessWidget {
  const AuthCompactIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: kMint,
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(top: -30, right: -30, child: _blob(110, const Color(0xFFD6E1FF))),
            SizedBox(
              height: 160,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SvgPicture.asset('assets/illustrations/doctors_duo.svg'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

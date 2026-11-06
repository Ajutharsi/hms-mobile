import 'package:flutter/material.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';

/// The three ways the app can be stuck through no fault of the person
/// using it: no connection, the server erroring, or the hospital taking
/// the system down for maintenance.
///
/// Each says which of the three it is, because the fix differs -- turn
/// Wi-Fi on, try again, or wait -- and a single "something went wrong"
/// tells nobody which.
class AppStatusScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? hint;
  final VoidCallback? onRetry;
  final String retryLabel;

  const AppStatusScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.hint,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  /// The phone has no usable connection.
  const AppStatusScreen.offline({super.key, this.onRetry})
      : icon = Icons.wifi_off_rounded,
        title = 'No connection',
        message = 'This app needs the hospital network or mobile data to load anything.',
        hint = 'Check Wi-Fi or mobile data, then try again.',
        retryLabel = 'Try again';

  /// The server answered, but with an error.
  const AppStatusScreen.serverError({super.key, this.onRetry, String? detail})
      : icon = Icons.error_outline_rounded,
        title = 'Something went wrong',
        message = 'The server could not complete that request.',
        hint = detail,
        retryLabel = 'Try again';

  /// The hospital has taken the system down on purpose.
  const AppStatusScreen.maintenance({super.key, this.onRetry, String? detail})
      : icon = Icons.build_circle_outlined,
        title = 'Under maintenance',
        message = 'The hospital is updating the system. Nothing is lost -- it will be back shortly.',
        hint = detail,
        retryLabel = 'Check again';

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);

    return Scaffold(
      backgroundColor: kCareBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(color: kCareSoft, shape: BoxShape.circle),
                  child: Icon(icon, size: 52, color: kCare),
                ),
                const SizedBox(height: 24),
                Text(title, textAlign: TextAlign.center, style: CareText.titleXxl),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: CareText.bodyMdMuted),
                if ((hint ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: kCareNeutralBg,
                      borderRadius: BorderRadius.circular(CareRadius.control),
                    ),
                    child: Text(hint!, textAlign: TextAlign.center, style: CareText.mutedSm),
                  ),
                ],
                if (onRetry != null) ...[
                  const SizedBox(height: 26),
                  SizedBox(width: 220, child: CarePrimaryButton(label: retryLabel, onPressed: onRetry)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

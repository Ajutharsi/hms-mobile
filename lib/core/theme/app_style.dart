import 'package:flutter/material.dart';

/// Neutral text tokens and the status badge colours shared by every role.
/// The brand colour itself now lives in care_ui.dart / care_palette.dart,
/// where the user's Appearance choice drives it.
const kInk = Color(0xFF12141A);
const kMuted = Color(0xFF6B7280);

/// Subtle stat/status badge colors — matches the web dashboard's
/// bg-label-* variants (success/info/warning/danger) so icon badges and
/// status chips read the same on both platforms.
const kSuccessBg = Color(0xFFDDF6E8);
const kSuccessFg = Color(0xFF10502C);
const kInfoBg = Color(0xFFD6F4F8);
const kInfoFg = Color(0xFF004A54);
const kWarningBg = Color(0xFFFFF0E1);
const kWarningFg = Color(0xFF66401B);
const kDangerBg = Color(0xFFFFE2E3);
const kDangerFg = Color(0xFF661E20);

/// Below this width, [AuthScaffold] drops the illustration side panel and
/// shows only the form — there's no room for a split layout on a phone.
const kSplitBreakpoint = 760.0;

Widget authErrorBanner(String message) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(10)),
    child: Text(message, style: const TextStyle(color: Color(0xFFB3261E), fontSize: 13.5)),
  );
}

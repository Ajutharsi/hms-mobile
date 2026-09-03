import 'package:flutter/material.dart';

/// Shared design tokens for the whole app (all six role apps import these
/// same constants, so changing a value here reskins every screen at once).
/// Names kept as `kTeal*`/`kMint` for git-history/diff continuity even
/// though the palette itself is now blue, not teal — a rename would touch
/// every screen file for zero behavioral gain.
const kTeal = Color(0xFF3D6BFF);
const kTealDark = Color(0xFF1E40E8);
const kInk = Color(0xFF12141A);
const kMuted = Color(0xFF6B7280);
const kFieldFill = Color(0xFFF3F4F8);
const kMint = Color(0xFFE8EEFF);

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

InputDecoration authFieldDecoration(String label, {required String hint, required IconData icon}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: const TextStyle(color: kInk, fontSize: 13, fontWeight: FontWeight.w600),
    hintStyle: const TextStyle(color: Color(0xFFAEB8B6), fontSize: 15),
    prefixIcon: Icon(icon, color: kMuted, size: 20),
    filled: true,
    fillColor: kFieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kTeal, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.2),
    ),
    errorStyle: const TextStyle(fontSize: 12),
  );
}

Widget authErrorBanner(String message) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(10)),
    child: Text(message, style: const TextStyle(color: Color(0xFFB3261E), fontSize: 13.5)),
  );
}

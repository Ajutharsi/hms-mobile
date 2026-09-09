import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared design tokens for the whole app (all six role apps import these
/// same constants, so changing a value here reskins every screen at once).
/// Names kept as `kTeal*`/`kMint`/`kFieldFill` for git-history/diff
/// continuity even though the palette moved from flat Material blue to a
/// warmer indigo-on-paper system — a rename would touch every screen file
/// for zero behavioral gain.
const kTeal = Color(0xFF2451D6);
const kTealDark = Color(0xFF16309E);
const kInk = Color(0xFF14213A);
const kMuted = Color(0xFF5B6478);
const kFieldFill = Color(0xFFF1ECE3);
const kMint = Color(0xFFE9EFFF);

/// Warm paper background (replaces stark white) and the accent used only
/// for primary calls-to-action — status/semantic meaning still lives in
/// the success/info/warning/danger tokens below, never in this color.
const kBg = Color(0xFFFBF7F1);
const kCoral = Color(0xFFFF6B4A);
const kBorder = Color(0xFFE4DDD0);

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

/// App-wide type system: Plus Jakarta Sans carries both headings and body
/// (set once on [ThemeData.textTheme] in `main.dart`, so it cascades to
/// every `Text`/`TextStyle` that doesn't set its own `fontFamily`); IBM
/// Plex Mono is applied by hand wherever figures line up in columns —
/// token numbers, timestamps, dosages — since that's a deliberate accent,
/// not a global default.
TextStyle kMonoStyle({
  double fontSize = 12,
  FontWeight fontWeight = FontWeight.w600,
  Color color = kMuted,
  double? letterSpacing,
}) =>
    GoogleFonts.ibmPlexMono(fontSize: fontSize, fontWeight: fontWeight, color: color, letterSpacing: letterSpacing);

InputDecoration authFieldDecoration(String label, {required String hint, required IconData icon}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: const TextStyle(color: kInk, fontSize: 13, fontWeight: FontWeight.w600),
    hintStyle: const TextStyle(color: Color(0xFFAEB0A8), fontSize: 15),
    prefixIcon: Icon(icon, color: kMuted, size: 20),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kTeal, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.2),
    ),
    errorStyle: const TextStyle(fontSize: 12),
  );
}

Widget authErrorBanner(String message) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(12)),
    child: Text(message, style: const TextStyle(color: Color(0xFFB3261E), fontSize: 13.5)),
  );
}

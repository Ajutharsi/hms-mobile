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

/// Destructive text and the pale surface it sits on — Delete/Decline/Reject
/// buttons, field errors, the auth error banner. One pair, so "this is bad
/// news" looks the same everywhere instead of 27 separate copies of the
/// same red.
const kDangerText = Color(0xFFB3261E);
const kDangerSurface = Color(0xFFFDECEC);

/// A warning that is not an error: the thing works, but someone should know.
const kWarnText = Color(0xFF8A5300);
const kWarnSurface = Color(0xFFFFF4E5);

/// White stepped back, for text and icons on top of a coloured header.
/// Translucent white rather than a grey, so it keeps working whatever
/// colour the user picks in Appearance.
const kOnCareSoft = Color(0xD9FFFFFF); // white @ 85%
const kOnCareFaint = Color(0xCCFFFFFF); // white @ 80%

/// Greys with a hint of teal, for furniture rather than content: a row's
/// trailing chevron, and the placeholder in a field nobody has filled in.
/// [kCareHint] is the darker of the two — it has to stay readable, where a
/// chevron only has to be visible.
const kCareChevron = Color(0xFFB5C2C0);
const kCareHint = Color(0xFFAEB8B6);
const kCareHintQuiet = Color(0xFF9AA6A4);

/// Neutral fills that carry no status: the background of a chip for a
/// cancelled or unknown state, and a control that is switched off.
const kCareNeutralBg = Color(0xFFF0F2F2);
const kCareDisabledBg = Color(0xFFF1F3F3);
const kCareDisabledFg = Color(0xFFBFC5C3);

/// Below this width, [AuthScaffold] drops the illustration side panel and
/// shows only the form — there's no room for a split layout on a phone.
const kSplitBreakpoint = 760.0;

Widget authErrorBanner(String message) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: kDangerSurface, borderRadius: BorderRadius.circular(10)),
    child: Text(message, style: const TextStyle(color: kDangerText, fontSize: 13.5)),
  );
}

/// Shown on the login screen of a release build that was compiled without
/// --dart-define=API_URL=https://..., so every request — credentials and
/// patient records included — would travel in plain text. A debug build
/// talking to a dev server over http is expected, so this stays hidden
/// there; a shipped build pointed at http is a mistake someone has to see.
Widget insecureConnectionNotice(String host) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: kWarnSurface, borderRadius: BorderRadius.circular(10)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_open_rounded, size: 18, color: kWarnText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'This build talks to $host without encryption. Anyone on the same '
            'network can read what you send. Tell your administrator before signing in.',
            style: const TextStyle(color: kWarnText, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

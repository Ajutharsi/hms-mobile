import 'package:flutter/material.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';

/// Neutral text tokens and the status badge colours shared by every role.
/// The brand colour itself now lives in care_ui.dart / care_palette.dart,
/// where the user's Appearance choice drives it.
/// Both taken from the Connecting Aspirants site: `--wd-title-color` and
/// `--wd-text-color`. The old pair was a near-black and a blue-grey from
/// the teal kit; these are the brand's own neutrals.
const kInk = Color(0xFF242424);
const kMuted = Color(0xFF767676);

/// The brand's second colour, `--wd-alternative-color`. The site spends it
/// sparingly — a highlighted word, a rating star — so it is here for the
/// same job, not as a second primary.
const kAccent = Color(0xFFFBBC34);
const kAccentSurface = Color(0xFFFEF6E4);

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

/// Greys for furniture rather than content: a row's trailing chevron, and
/// the placeholder in a field nobody has filled in. [kCareHint] is the
/// darker of the two — it has to stay readable, where a chevron only has
/// to be visible.
///
/// These used to carry a hint of teal, which worked while the brand was
/// teal and looked faintly green beside a blue one. They are plain greys
/// now, so they sit under any seed the user picks.
const kCareChevron = Color(0xFFBDBDBD);
const kCareHint = Color(0xFFB0B0B0);
const kCareHintQuiet = Color(0xFF9A9A9A);

/// Neutral fills that carry no status: the background of a chip for a
/// cancelled or unknown state, and a control that is switched off. The two
/// surfaces are the site's own `#f7f7f7` and `#efefef`.
const kCareNeutralBg = Color(0xFFF7F7F7);
const kCareDisabledBg = Color(0xFFEFEFEF);
const kCareDisabledFg = Color(0xFFC4C4C4);

/// Below this width, [AuthScaffold] drops the illustration side panel and
/// shows only the form — there's no room for a split layout on a phone.
const kSplitBreakpoint = 760.0;

Widget authErrorBanner(String message) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: kDangerSurface, borderRadius: BorderRadius.circular(CareRadius.control)),
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
    decoration: BoxDecoration(color: kWarnSurface, borderRadius: BorderRadius.circular(CareRadius.control)),
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

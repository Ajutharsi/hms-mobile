/// The corner radii the app rounds things to.
///
/// There were 263 `BorderRadius.circular(n)` calls across the screens,
/// spread over sixteen values — 4, 6, 7, 9, 10, 11, 18, 22, 24, 26 among
/// them. Most of that was not a decision anybody made; it was whatever
/// looked about right at the time, and the same kind of surface ended up
/// rounded three different ways on three screens.
///
/// These are named by what is being rounded rather than by size, because
/// that is the question at a call site: a status badge is a [chip], a text
/// field is a [field]. Matching the thing is what keeps two screens
/// agreeing; matching a number is what let them drift.
abstract final class CareRadius {
  /// Status badges and small pills sitting on a tinted background.
  static const double chip = 8;

  /// Buttons, icon boxes, and the small tinted panels that hold a note.
  static const double control = 12;

  /// Text fields, dropdowns and list tiles.
  static const double field = 14;

  /// The white surfaces a list is made of.
  static const double card = 16;

  /// Bottom sheets and the larger cards that hold a section.
  static const double panel = 20;

  /// The big rounded panels on the auth screens.
  static const double hero = 24;

  /// The top corners of a bottom sheet. The shared sheet in care_ui.dart
  /// was already 24 while three others sat at 20 and one at 18 — the same
  /// kind of surface, rounded four ways.
  static const double sheet = 24;

  /// The outer corner of a navigation drawer.
  static const double drawer = 28;

  /// Fully round — a capsule, whatever its height.
  static const double pill = 999;
}

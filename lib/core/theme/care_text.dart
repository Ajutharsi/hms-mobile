import 'package:flutter/material.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_palette.dart';

/// The app's type scale, in one place.
///
/// Before this existed, the screens held 871 `TextStyle(...)` literals, and
/// 679 of them were exact repeats of just 55 shapes. The sizes had drifted
/// into nineteen values, many half a pixel apart — 12 and 12.5, 14 and
/// 14.5, 16 and 16.5 — differences nobody chose and nobody can see, which
/// made the same kind of text look subtly different from screen to screen.
///
/// The scale below is eleven steps, each at least 1px from its neighbour.
/// Every old size snapped to the nearest step *at or below* it, so nothing
/// grew by even half a pixel and no row that used to fit can start
/// overflowing. The most-used sizes (12.5, 14.5, 11.5) land on a step
/// exactly, so most of the app did not move at all.
///
/// Names read `role + size + weight`:
///   role   — [muted] secondary, `body` primary, `title` bold primary,
///            `onCare` on a coloured header, `brand` brand-coloured
///   size   — [xxs] … [stat], the constants below
///   weight — bare is the role's own, `Medium` is w600, `Bold` is w700
///
/// A style used once still belongs at its call site; only a shape that
/// repeats earns a name here — and [style_tokens_test.dart] fails the build
/// if a shape starts repeating without one. The brand-coloured entries are
/// getters rather than constants because they follow the colour the user
/// picks in Appearance; a `const` would freeze the colour it compiled with.
abstract final class CareText {
  // ---- the scale ----------------------------------------------------
  static const double xxs = 10.5;
  static const double xs = 11.5;
  static const double sm = 12.5;
  static const double md = 13.5;
  static const double lg = 14.5;
  static const double xl = 15.5;
  static const double xxl = 16.5;
  static const double h3 = 18;
  static const double h2 = 21;
  static const double h1 = 24;
  static const double stat = 32;

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight heavy = FontWeight.w800;

  // ---- secondary text -------------------------------------------------
  /// Takes its size from whatever set it — for a caption inside a widget
  /// that has already chosen one.
  static const TextStyle muted = TextStyle(color: kMuted);
  static const TextStyle mutedXxs = TextStyle(fontSize: xxs, color: kMuted);
  static const TextStyle mutedXs = TextStyle(fontSize: xs, color: kMuted);
  static const TextStyle mutedSm = TextStyle(fontSize: sm, color: kMuted);
  static const TextStyle mutedLg = TextStyle(fontSize: lg, color: kMuted);

  static const TextStyle mutedXxsMedium = TextStyle(fontSize: xxs, color: kMuted, fontWeight: medium);
  static const TextStyle mutedXsMedium = TextStyle(fontSize: xs, color: kMuted, fontWeight: medium);
  static const TextStyle mutedSmMedium = TextStyle(fontSize: sm, color: kMuted, fontWeight: medium);

  static const TextStyle mutedSmBold = TextStyle(fontSize: sm, color: kMuted, fontWeight: bold);

  /// A column header, with the letters pushed apart just enough to read as
  /// a header rather than as content.
  static const TextStyle mutedSmBoldWide =
      TextStyle(fontSize: sm, color: kMuted, fontWeight: bold, letterSpacing: 0.3);

  /// "No notes recorded", "not yet scheduled" — an absent value, not text
  /// someone wrote.
  static const TextStyle mutedSmItalic = TextStyle(fontSize: sm, color: kMuted, fontStyle: FontStyle.italic);

  // ---- primary body copy ----------------------------------------------
  static const TextStyle bodyMd = TextStyle(fontSize: md, color: kInk);
  static const TextStyle bodyLg = TextStyle(fontSize: lg, color: kInk);

  // ---- titles ----------------------------------------------------------
  static const TextStyle titleSm = TextStyle(fontSize: sm, fontWeight: bold, color: kInk);
  static const TextStyle titleMd = TextStyle(fontSize: md, fontWeight: bold, color: kInk);
  static const TextStyle titleLg = TextStyle(fontSize: lg, fontWeight: bold, color: kInk);
  static const TextStyle titleXl = TextStyle(fontSize: xl, fontWeight: bold, color: kInk);
  static const TextStyle titleXxl = TextStyle(fontSize: xxl, fontWeight: bold, color: kInk);
  static const TextStyle titleH3 = TextStyle(fontSize: h3, fontWeight: bold, color: kInk);

  /// The largest thing on a page — a screen title, or a figure presented as
  /// the answer to something.
  static const TextStyle display = TextStyle(fontSize: h2, fontWeight: heavy, color: kInk);

  static const TextStyle titleSmMedium = TextStyle(fontSize: sm, fontWeight: medium, color: kInk);
  static const TextStyle titleMdMedium = TextStyle(fontSize: md, fontWeight: medium, color: kInk);
  static const TextStyle titleXlMedium = TextStyle(fontSize: xl, fontWeight: medium, color: kInk);

  /// Bold ink at whatever size the caller already set.
  static const TextStyle inkBold = TextStyle(fontWeight: bold, color: kInk);

  /// Weight or size only, for text whose colour comes from somewhere else —
  /// a `.copyWith(color: …)` or an enclosing DefaultTextStyle.
  static const TextStyle boldOnly = TextStyle(fontWeight: bold);
  static const TextStyle plainSm = TextStyle(fontSize: sm);
  static const TextStyle xlMedium = TextStyle(fontSize: xl, fontWeight: medium);

  // ---- on a coloured header or a filled button -------------------------
  static const TextStyle onCare = TextStyle(color: Colors.white);
  static const TextStyle onCareBold = TextStyle(color: Colors.white, fontWeight: bold);
  static const TextStyle onCareTitle = TextStyle(color: Colors.white, fontSize: xxl, fontWeight: bold);
  static const TextStyle onCareDisplay = TextStyle(color: Colors.white, fontSize: h3, fontWeight: heavy);

  /// A subtitle under a header title: still white, but stepped back so the
  /// title keeps the lead.
  static const TextStyle onCareSoftXs = TextStyle(color: kOnCareSoft, fontSize: xs);
  static const TextStyle onCareSoftSm = TextStyle(color: kOnCareSoft, fontSize: sm);
  static const TextStyle onCareFaintXs = TextStyle(color: kOnCareFaint, fontSize: xs);

  // ---- error text -------------------------------------------------------
  static const TextStyle danger = TextStyle(color: kDangerText);

  // ---- brand-coloured: getters, so they follow Appearance ---------------
  static TextStyle get brandBold => TextStyle(color: CareColors.dark, fontWeight: bold);
  static TextStyle get brandSmBold => TextStyle(fontSize: sm, fontWeight: bold, color: CareColors.dark);
  static TextStyle get brandSmMedium => TextStyle(color: CareColors.dark, fontSize: sm, fontWeight: medium);
  static TextStyle get brandMdMedium => TextStyle(color: CareColors.dark, fontSize: md, fontWeight: medium);

  /// A small brand-coloured eyebrow above a heading.
  static TextStyle get overline =>
      TextStyle(fontSize: xxs, fontWeight: heavy, color: CareColors.primary, letterSpacing: 0.8);

  /// The big number on a dashboard stat card.
  static TextStyle get statBig => TextStyle(fontSize: stat, fontWeight: bold, color: CareColors.dark);

  // ---- styles whose colour is decided at the call site ------------------
  /// Status chip text. The colour carries the status, so it cannot be baked
  /// in; the size and weight can.
  static TextStyle chip(Color fg, {double size = xxs}) =>
      TextStyle(color: fg, fontSize: size, fontWeight: bold);

  /// A softer chip — a tag or a nav label rather than a status.
  static TextStyle tag(Color fg, {double size = xxs}) =>
      TextStyle(color: fg, fontSize: size, fontWeight: medium);

  /// A stat figure tinted to match the thing it counts.
  static TextStyle statValue(Color color) => TextStyle(fontSize: h3, fontWeight: heavy, color: color);
}

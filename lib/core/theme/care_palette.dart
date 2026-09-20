import 'package:flutter/material.dart';

/// The app's colour scheme, derived from a single seed colour the user
/// picks — the mobile counterpart of the web template customizer's colour
/// control. Everything else (the darker header shade, the soft tint behind
/// icons, the page background, borders) is computed, so a user can only
/// ever choose a readable combination.
class CarePalette {
  final Color seed;

  const CarePalette._(this.seed);

  /// The default look: the teal from the PatientCare kit.
  static const CarePalette fallback = CarePalette._(Color(0xFF1FA99A));

  factory CarePalette.fromSeed(Color seed) => CarePalette._(seed);

  /// The seed, darkened just enough that white text on it stays legible
  /// (3:1, the WCAG AA floor for the large/bold text the kit puts on
  /// coloured surfaces). A light pick like amber therefore deepens a
  /// little rather than turning unreadable; the swatch still shows the
  /// exact colour the user chose.
  Color get primary {
    var color = seed;
    for (var i = 0; i < 12 && _contrastWithWhite(color) < 3.0; i++) {
      color = _shift(color, -0.04);
    }
    return color;
  }

  static double _contrastWithWhite(Color c) => 1.05 / (c.computeLuminance() + 0.05);

  /// Header gradient end + pressed/emphasis shade.
  Color get dark => _shift(primary, -0.08);
  Color get deep => _shift(primary, -0.16);

  /// Tint behind icons and "soft" chips.
  Color get soft => _tint(seed, 0.88);

  /// Page background — a barely-there wash of the seed.
  Color get background => _tint(seed, 0.96);

  /// Card and divider outlines.
  Color get border => _tint(seed, 0.86, saturation: 0.18);

  /// Text/icon colour for coloured surfaces. [primary] is already darkened
  /// to carry white, so this is white unless a very pale colour survived
  /// that adjustment.
  Color get onPrimary => _contrastWithWhite(primary) >= 3.0 ? Colors.white : const Color(0xFF12141A);

  /// Accent for "needs attention" chips — kept off the seed hue so it
  /// still reads as an alert whatever colour the user picks.
  Color get alertBg => const Color(0xFFFDE8EF);
  Color get alertFg => const Color(0xFFD6336C);

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, dark],
      );

  List<BoxShadow> get shadow => [BoxShadow(color: deep.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))];

  static Color _shift(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  static Color _tint(Color c, double lightness, {double? saturation}) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness(lightness.clamp(0.0, 1.0))
        .withSaturation((saturation ?? (hsl.saturation * 0.45)).clamp(0.0, 1.0))
        .toColor();
  }

  /// Ready-made choices shown in Appearance, mirroring the web
  /// customizer's presets plus the app's own default.
  static const List<({String name, Color color})> presets = [
    (name: 'Teal', color: Color(0xFF1FA99A)),
    (name: 'Blue', color: Color(0xFF2092EC)),
    (name: 'Indigo', color: Color(0xFF3D6BFF)),
    (name: 'Violet', color: Color(0xFF7367F0)),
    (name: 'Rose', color: Color(0xFFEB3D63)),
    (name: 'Amber', color: Color(0xFFE28A00)),
    (name: 'Green', color: Color(0xFF28A745)),
    (name: 'Slate', color: Color(0xFF4B5C6B)),
  ];
}

/// Colour lookup for widgets. Reads the palette currently applied by
/// [CareThemeController]; screens use these instead of fixed constants so a
/// colour change repaints the whole app.
class CareColors {
  /// Set by [CareThemeController] whenever the user picks a colour.
  static CarePalette current = CarePalette.fallback;

  static Color get primary => current.primary;
  static Color get dark => current.dark;
  static Color get deep => current.deep;
  static Color get soft => current.soft;
  static Color get background => current.background;
  static Color get border => current.border;
  static Color get onPrimary => current.onPrimary;
  static Color get alertBg => current.alertBg;
  static Color get alertFg => current.alertFg;
  static LinearGradient get gradient => current.gradient;
  static List<BoxShadow> get shadow => current.shadow;
}

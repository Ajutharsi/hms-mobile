import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hms_mobile/core/theme/care_palette.dart';

/// The Appearance screen lets a user pick any colour, so the derived
/// shades have to stay sane — above all the text colour drawn on top of it.
void main() {
  double luminanceContrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    final (hi, lo) = la > lb ? (la, lb) : (lb, la);
    return (hi + 0.05) / (lo + 0.05);
  }

  test('text on the primary colour stays readable for every preset', () {
    for (final preset in CarePalette.presets) {
      final palette = CarePalette.fromSeed(preset.color);
      final contrast = luminanceContrast(palette.onPrimary, palette.primary);
      // 3:1 is the WCAG AA floor for the large, bold text the kit puts on
      // coloured surfaces (headers, buttons, the nav bar).
      expect(contrast, greaterThanOrEqualTo(3.0), reason: '${preset.name} header text is too faint');
    }
  });

  test('derived shades order from background to deep', () {
    for (final preset in CarePalette.presets) {
      final p = CarePalette.fromSeed(preset.color);
      expect(p.background.computeLuminance(), greaterThan(p.soft.computeLuminance()),
          reason: '${preset.name}: page background should be lighter than the soft tint');
      expect(p.soft.computeLuminance(), greaterThan(p.primary.computeLuminance()),
          reason: '${preset.name}: soft tint should be lighter than the primary');
      expect(p.primary.computeLuminance(), greaterThanOrEqualTo(p.dark.computeLuminance()),
          reason: '${preset.name}: header gradient should darken, not lighten');
    }
  });

  test('a pale pick is deepened instead of left unreadable', () {
    final pale = CarePalette.fromSeed(const Color(0xFFFFE082));
    expect(pale.primary.computeLuminance(), lessThan(const Color(0xFFFFE082).computeLuminance()));
    expect(luminanceContrast(Colors.white, pale.primary), greaterThanOrEqualTo(3.0));
    expect(pale.seed, const Color(0xFFFFE082), reason: 'the swatch still shows what was picked');
  });

  test('CareColors follows the palette that was applied', () {
    CareColors.current = CarePalette.fromSeed(const Color(0xFFEB3D63));
    expect(CareColors.current.seed, const Color(0xFFEB3D63));
    final rose = CareColors.primary;
    CareColors.current = CarePalette.fallback;
    expect(CareColors.primary, isNot(rose));
    expect(CareColors.current.seed, const Color(0xFF1FA99A));
  });
}

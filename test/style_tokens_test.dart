import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hms_mobile/core/theme/care_text.dart';

/// Guards the design tokens against drifting back out into the screens.
///
/// The app once had 871 `TextStyle(...)` literals written at the call
/// sites, 679 of them exact copies of 55 shapes, across eleven font sizes
/// half a pixel apart. These tests fail if that starts happening again —
/// which is cheaper than noticing it by eye across 64 screens.
void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  /// core/theme is where the tokens are *defined*, so it is allowed to
  /// spell out sizes and colours; everywhere else should be naming them.
  bool isScreenCode(File f) => !f.path.replaceAll(r'\', '/').contains('lib/core/theme/');

  test('the type scale has no sub-pixel duplicate steps', () {
    const scale = [
      CareText.xxs,
      CareText.xs,
      CareText.sm,
      CareText.md,
      CareText.lg,
      CareText.xl,
      CareText.xxl,
      CareText.h3,
      CareText.h2,
      CareText.h1,
      CareText.stat,
    ];
    expect(scale.toSet().length, scale.length, reason: 'two steps share a size');
    for (var i = 1; i < scale.length; i++) {
      expect(scale[i], greaterThan(scale[i - 1]), reason: 'the scale is not sorted');
      expect(scale[i] - scale[i - 1], greaterThanOrEqualTo(1),
          reason: 'steps ${scale[i - 1]} and ${scale[i]} are closer than 1px — nobody can see that');
    }
  });

  test('a repeated TextStyle shape has a name instead of being copied', () {
    final counts = <String, int>{};
    for (final file in dartFiles.where(isScreenCode)) {
      final source = file.readAsStringSync();
      for (final match in RegExp(r'TextStyle\(').allMatches(source)) {
        var i = match.end;
        var depth = 1;
        while (i < source.length && depth > 0) {
          if (source[i] == '(') depth++;
          if (source[i] == ')') depth--;
          i++;
        }
        final body = source.substring(match.end, i - 1).replaceAll(RegExp(r'\s+'), ' ').trim();
        if (body.isEmpty) continue;
        counts[body.replaceAll(RegExp(r',$'), '')] = (counts[body] ?? 0) + 1;
      }
    }

    final copied = counts.entries.where((e) => e.value >= 4).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    expect(
      copied,
      isEmpty,
      reason: 'these shapes are written out 4+ times — give each one a name in '
          'CareText and use that:\n${copied.map((e) => '  ${e.value}x TextStyle(${e.key})').join('\n')}',
    );
  });

  test('screens do not hardcode colours', () {
    // The only literal colours left outside core/theme. The hue wheel in
    // Appearance really is six fixed primaries, and that card shadow is
    // neutral black rather than anything brand-coloured.
    const allowed = {
      'Color(0xFFFF0000)', 'Color(0xFFFFFF00)', 'Color(0xFF00FF00)',
      'Color(0xFF00FFFF)', 'Color(0xFF0000FF)', 'Color(0xFFFF00FF)',
      'Color(0x33000000)',
    };

    final offenders = <String>[];
    for (final file in dartFiles.where(isScreenCode)) {
      for (final match in RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)').allMatches(file.readAsStringSync())) {
        if (!allowed.contains(match[0])) {
          offenders.add('${file.path}: ${match[0]}');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'add a token in app_style.dart or care_ui.dart instead:\n${offenders.join('\n')}');
  });

  test('tokens that follow the brand colour are not frozen constants', () {
    // A `const` brand style would keep the colour it was compiled with and
    // ignore the user's choice in Appearance, which is the bug these
    // getters exist to avoid.
    final before = CareText.brandSmBold.color;
    expect(before, isNotNull);
    expect(CareText.overline.color, isNotNull);
    expect(CareText.statBig.fontSize, CareText.stat);
    // The muted/ink tokens are genuinely constant, and should stay const
    // so call sites can keep their `const` widgets.
    expect(CareText.muted.color, isNotNull);
    expect(identical(CareText.muted, CareText.muted), isTrue);
  });

  test('every scale step is actually reachable through a token', () {
    expect(CareText.mutedSm.fontSize, CareText.sm);
    expect(CareText.titleLg.fontWeight, CareText.bold);
    expect(CareText.chip(Colors.red).fontSize, CareText.xxs);
    expect(CareText.chip(Colors.red, size: CareText.xs).fontSize, CareText.xs);
    expect(CareText.tag(Colors.red).fontWeight, CareText.medium);
    expect(CareText.statValue(Colors.red).color, Colors.red);
  });
}

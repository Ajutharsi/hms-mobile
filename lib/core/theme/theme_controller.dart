import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:hms_mobile/core/theme/care_palette.dart';

/// Holds the colour the user picked in Appearance and keeps it on the
/// device, the way the web customizer keeps its colour in the browser.
class CareThemeController extends ChangeNotifier {
  static const _key = 'care_seed_color';

  final FlutterSecureStorage _storage;

  CareThemeController({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    load();
  }

  CarePalette _palette = CarePalette.fallback;
  CarePalette get palette => _palette;
  Color get seed => _palette.seed;

  bool get isDefault => _palette.seed.toARGB32() == CarePalette.fallback.seed.toARGB32();

  Future<void> load() async {
    try {
      final saved = await _storage.read(key: _key);
      final value = int.tryParse(saved ?? '');
      if (value != null) _apply(CarePalette.fromSeed(Color(value)));
    } catch (_) {
      // A locked keystore shouldn't stop the app from starting; the
      // default palette stays in place.
    }
  }

  Future<void> setSeed(Color color) async {
    _apply(CarePalette.fromSeed(color));
    try {
      await _storage.write(key: _key, value: color.toARGB32().toString());
    } catch (_) {
      // Colour still applies for this session even if it can't be saved.
    }
  }

  Future<void> resetToDefault() => setSeed(CarePalette.fallback.seed);

  void _apply(CarePalette palette) {
    _palette = palette;
    CareColors.current = palette;
    notifyListeners();
  }
}

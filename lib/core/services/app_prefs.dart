import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small on-device settings that belong to the app rather than to the
/// hospital: whether the intro has been seen and whether the session is
/// locked behind the phone's fingerprint or face check.
///
/// These live next to the token in the encrypted keystore. Nothing here
/// is sent to the server, and a locked or wiped keystore only means the
/// defaults come back.
class AppPrefs extends ChangeNotifier {
  static const _onboardingKey = 'onboarding_seen';
  static const _biometricKey = 'biometric_lock';

  final FlutterSecureStorage _storage;

  AppPrefs({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  bool onboardingSeen = false;
  bool biometricLock = false;

  /// Read once at startup, before the first screen is chosen.
  Future<void> load() async {
    try {
      onboardingSeen = await _storage.read(key: _onboardingKey) == '1';
      biometricLock = await _storage.read(key: _biometricKey) == '1';
    } catch (_) {
      // Defaults are safe: the intro shows again, the lock stays off.
    }
    notifyListeners();
  }

  Future<void> markOnboardingSeen() => _set(_onboardingKey, true, () => onboardingSeen = true);

  Future<void> setBiometricLock(bool value) => _set(_biometricKey, value, () => biometricLock = value);

  /// Forgets the app's own settings. The session token is deliberately
  /// left alone -- signing out is a separate action.
  Future<void> reset() async {
    onboardingSeen = false;
    biometricLock = false;
    notifyListeners();
    try {
      await _storage.delete(key: _onboardingKey);
      await _storage.delete(key: _biometricKey);
    } catch (_) {
      // Nothing to undo; the in-memory values are already the defaults.
    }
  }

  Future<void> _set(String key, bool value, VoidCallback apply) async {
    apply();
    notifyListeners();
    try {
      await _storage.write(key: key, value: value ? '1' : '0');
    } catch (_) {
      // The choice still holds for this run.
    }
  }
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the Sanctum token on-device (encrypted keystore/keychain) so
/// the user doesn't have to log in again every time the app opens.
class AuthStorage {
  static const _tokenKey = 'auth_token';
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clear() => _storage.delete(key: _tokenKey);
}

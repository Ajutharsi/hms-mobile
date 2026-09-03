import 'package:flutter/material.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';

enum SessionStatus { checking, loggedIn, loggedOut }

/// Checks for a saved token on app launch and confirms it's still valid,
/// so the app can skip straight to Home instead of asking to log in again
/// every time.
class SessionViewModel extends ChangeNotifier {
  final ApiService _api;
  final AuthStorage _authStorage;

  SessionViewModel({ApiService? api, AuthStorage? authStorage})
      : _api = api ?? ApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    _checkSession();
  }

  SessionStatus status = SessionStatus.checking;
  AppUser? user;

  Future<void> _checkSession() async {
    final token = await _authStorage.readToken();

    if (token == null) {
      status = SessionStatus.loggedOut;
      notifyListeners();
      return;
    }

    try {
      user = await _api.me(token);
      status = SessionStatus.loggedIn;
    } catch (_) {
      // Token missing/expired/server unreachable — fall back to login
      // rather than getting stuck on the splash screen.
      await _authStorage.clear();
      status = SessionStatus.loggedOut;
    }
    notifyListeners();
  }
}

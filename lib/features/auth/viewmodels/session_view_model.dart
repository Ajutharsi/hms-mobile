import 'package:flutter/material.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';

enum SessionStatus { checking, loggedIn, loggedOut, unreachable }

/// Checks for a saved token on app launch and confirms it's still valid,
/// so the app can skip straight to Home instead of asking to log in again
/// every time.
class SessionViewModel extends ChangeNotifier {
  final ApiService _api;
  final AuthStorage _authStorage;

  SessionViewModel({ApiService? api, AuthStorage? authStorage})
      : _api = api ?? ApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    checkSession();
  }

  SessionStatus status = SessionStatus.checking;
  AppUser? user;

  /// Set when [status] is [SessionStatus.unreachable], so the startup
  /// screen can say which kind of outage it is.
  ApiException? failure;

  Future<void> checkSession() async {
    status = SessionStatus.checking;
    failure = null;
    notifyListeners();

    final token = await _authStorage.readToken();

    if (token == null) {
      status = SessionStatus.loggedOut;
      notifyListeners();
      return;
    }

    try {
      user = await guardNetworkErrors(() => _api.me(token));
      status = SessionStatus.loggedIn;
    } on ApiException catch (error) {
      if (error.isUnauthenticated) {
        // The token really is no good: forget it and ask for a password.
        await _authStorage.clear();
        status = SessionStatus.loggedOut;
      } else {
        // The phone is offline, or the server is down or erroring. The
        // token is probably fine, so keep it -- signing somebody out
        // because their train went into a tunnel loses their place for
        // no reason.
        failure = error;
        status = SessionStatus.unreachable;
      }
    } catch (error) {
      failure = ApiException('$error');
      status = SessionStatus.unreachable;
    }
    notifyListeners();
  }
}

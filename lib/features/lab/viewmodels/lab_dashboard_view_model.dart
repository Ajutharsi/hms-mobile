import 'package:flutter/material.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/lab_api_service.dart';
import 'package:hms_mobile/features/lab/models/lab_dashboard_stats.dart';

class LabDashboardViewModel extends ChangeNotifier {
  final LabApiService _api;
  final AuthStorage _authStorage;
  final AppUser user;

  LabDashboardViewModel({required this.user, LabApiService? api, AuthStorage? authStorage})
      : _api = api ?? LabApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  bool isLoggingOut = false;
  String? loadError;
  LabDashboardStats? stats;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      stats = await guardNetworkErrors(() => _api.dashboard(token!));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    isLoggingOut = true;
    notifyListeners();

    final token = await _authStorage.readToken();
    if (token != null) {
      try {
        await ApiService().logout(token);
      } catch (_) {
        // Even if the server call fails (e.g. offline), still clear the
        // local token so the user isn't stuck signed in on-device.
      }
    }
    await _authStorage.clear();

    isLoggingOut = false;
    notifyListeners();
  }
}

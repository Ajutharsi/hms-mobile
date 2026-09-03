import 'package:flutter/material.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/receptionist_api_service.dart';
import 'package:hms_mobile/features/receptionist/models/reception_dashboard_stats.dart';

class ReceptionDashboardViewModel extends ChangeNotifier {
  final ReceptionistApiService _api;
  final AuthStorage _authStorage;
  final AppUser user;

  ReceptionDashboardViewModel({required this.user, ReceptionistApiService? api, AuthStorage? authStorage})
      : _api = api ?? ReceptionistApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  bool isLoggingOut = false;
  String? loadError;
  ReceptionDashboardStats? stats;
  List<ReceptionDashboardAppointment> todayAppointments = [];
  List<ReceptionDashboardPatient> recentPatients = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      final result = await guardNetworkErrors(() => _api.dashboard(token!));
      stats = result.$1;
      todayAppointments = result.$2;
      recentPatients = result.$3;
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

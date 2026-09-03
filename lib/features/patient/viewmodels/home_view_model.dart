import 'package:flutter/material.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/features/patient/models/appointment.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';

class HomeViewModel extends ChangeNotifier {
  final ApiService _api;
  final AuthStorage _authStorage;
  final AppUser user;

  HomeViewModel({required this.user, ApiService? api, AuthStorage? authStorage})
      : _api = api ?? ApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    loadAppointments();
  }

  bool isLoading = true;
  bool isLoggingOut = false;
  String? loadError;
  List<Appointment> appointments = [];

  Future<void> loadAppointments() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      appointments = await guardNetworkErrors(() => _api.getAppointments(token!));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Returns an error message on failure, or null on success.
  Future<String?> cancelAppointment(int id) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.cancelAppointment(token!, id));
      await loadAppointments();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    isLoggingOut = true;
    notifyListeners();

    final token = await _authStorage.readToken();
    if (token != null) {
      try {
        await _api.logout(token);
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

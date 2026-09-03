import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/round_assignment.dart';

/// Backs "My Rounds" — the bedside nurse's own ward-round assignments.
class MyRoundsViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;

  MyRoundsViewModel({NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<RoundAssignment> assignments = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      assignments = await guardNetworkErrors(() => _api.myRounds(token!));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Returns an error message on failure, or null on success.
  Future<String?> markRound(
    int patientId, {
    required int assignmentId,
    String? bloodPressure,
    String? temperature,
    String? pulseRate,
    String? spo2,
    String? notes,
  }) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.markRound(
            token!,
            patientId,
            assignmentId: assignmentId,
            bloodPressure: bloodPressure,
            temperature: temperature,
            pulseRate: pulseRate,
            spo2: spo2,
            notes: notes,
          ));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<List<StaffRound>> roundHistory(int patientId) async {
    final token = await _authStorage.readToken();
    return guardNetworkErrors(() => _api.roundHistory(token!, patientId));
  }
}

/// Backs "Staff Rounds" — the read-only charge-nurse view of every active
/// round assignment across the hospital. The web's assign/deactivate
/// actions aren't exposed on the mobile API yet (see final report).
class StaffRoundsViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;

  StaffRoundsViewModel({NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<Map<String, dynamic>> assignments = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      assignments = await guardNetworkErrors(() => _api.staffRoundsAssignments(token!));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

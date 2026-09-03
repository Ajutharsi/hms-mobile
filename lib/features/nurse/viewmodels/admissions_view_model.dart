import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/admission.dart';

class AdmissionsViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;

  AdmissionsViewModel({NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<Admission> admissions = [];
  String? statusFilter;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      admissions = await guardNetworkErrors(() => _api.admissions(token!, status: statusFilter));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String? status) {
    statusFilter = status;
    load();
  }

  /// Returns an error message on failure, or null on success.
  Future<String?> discharge(int admissionId, {required String dischargeDate, String? notes, required double totalCharges}) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.dischargeAdmission(token!, admissionId, dischargeDate: dischargeDate, notes: notes, totalCharges: totalCharges));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> transfer(int admissionId, {required int newWardId, required int newBedId, String? reason}) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.transferAdmission(token!, admissionId, newWardId: newWardId, newBedId: newBedId, reason: reason));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

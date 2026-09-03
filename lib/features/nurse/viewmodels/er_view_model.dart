import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, guardNetworkErrors;
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/er_registration.dart';

class ErViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;

  ErViewModel({NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  ErStats? stats;
  List<ErRegistration> registrations = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      final result = await guardNetworkErrors(() => _api.erList(token!));
      stats = result.$1;
      registrations = result.$2;
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> triage(int id, String triageLevel) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.erTriage(token!, id, triageLevel));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> update(int id, {int? attendingDoctorId, required String status, String? notes, String? icd10Code}) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.erUpdate(token!, id, attendingDoctorId: attendingDoctorId, status: status, notes: notes, icd10Code: icd10Code));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> discharge(int id, {required String status, String? notes}) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.erDischarge(token!, id, status: status, notes: notes));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

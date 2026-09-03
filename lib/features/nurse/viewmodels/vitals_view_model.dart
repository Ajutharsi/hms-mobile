import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/nurse_vital.dart';

class VitalsViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;

  VitalsViewModel({NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<NurseVital> vitals = [];

  Future<String?> _token() => _authStorage.readToken();

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _token();
      vitals = await guardNetworkErrors(() => _api.vitalsList(token!));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> record({
    required int patientId,
    String? bloodPressure,
    num? temperature,
    int? pulseRate,
    int? respiratoryRate,
    int? spo2,
    num? weight,
    num? height,
    String? notes,
  }) async {
    try {
      final token = await _token();
      await guardNetworkErrors(() => _api.vitalsStore(
            token!,
            patientId: patientId,
            bloodPressure: bloodPressure,
            temperature: temperature,
            pulseRate: pulseRate,
            respiratoryRate: respiratoryRate,
            spo2: spo2,
            weight: weight,
            height: height,
            notes: notes,
          ));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> destroy(int vitalId) async {
    try {
      final token = await _token();
      await guardNetworkErrors(() => _api.vitalsDestroy(token!, vitalId));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

class VitalsHistoryViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;
  final int patientId;

  VitalsHistoryViewModel({required this.patientId, NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<NurseVital> history = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      history = await guardNetworkErrors(() => _api.vitalsHistory(token!, patientId));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

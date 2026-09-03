import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/medication_order.dart';

class EmarViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;

  EmarViewModel({NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<MedicationOrder> orders = [];

  Future<String?> _token() => _authStorage.readToken();

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _token();
      orders = await guardNetworkErrors(() => _api.emarList(token!));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Returns an error message on failure, or null on success.
  Future<String?> createOrder({
    required int patientId,
    required String drugName,
    required String dosage,
    String? route,
    String? frequency,
    String? scheduledTime,
    String? notes,
    required bool isPrn,
    required bool isControlled,
  }) async {
    try {
      final token = await _token();
      await guardNetworkErrors(() => _api.emarStore(
            token!,
            patientId: patientId,
            drugName: drugName,
            dosage: dosage,
            route: route,
            frequency: frequency,
            scheduledTime: scheduledTime,
            notes: notes,
            isPrn: isPrn,
            isControlled: isControlled,
          ));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> administer(int marId, {required String status, String? notes}) async {
    try {
      final token = await _token();
      await guardNetworkErrors(() => _api.emarAdminister(token!, marId, status: status, notes: notes));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> destroy(int marId) async {
    try {
      final token = await _token();
      await guardNetworkErrors(() => _api.emarDestroy(token!, marId));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

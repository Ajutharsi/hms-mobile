import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/blood_bank.dart';

class BloodBankViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;

  BloodBankViewModel({NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  int totalUnits = 0;
  Map<String, int> byGroup = {};
  int nearExpiryCount = 0;
  List<BloodUnit> units = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      final result = await guardNetworkErrors(() => _api.bloodBankIndex(token!));
      totalUnits = result.$1;
      byGroup = result.$2;
      nearExpiryCount = result.$3;
      units = result.$4;
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> addUnit({
    required String bloodGroup,
    required String component,
    String? donorName,
    required String collectionDate,
    required String expiryDate,
    String? notes,
  }) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.bloodBankStore(
            token!,
            bloodGroup: bloodGroup,
            component: component,
            donorName: donorName,
            collectionDate: collectionDate,
            expiryDate: expiryDate,
            notes: notes,
          ));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> transfuse(int unitId, {required int patientId, String? indication}) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.bloodBankTransfuse(token!, unitId, patientId: patientId, indication: indication));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateStatus(int unitId, {required String status, int? reservedFor}) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.bloodBankUpdateStatus(token!, unitId, status: status, reservedFor: reservedFor));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> destroy(int unitId) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.bloodBankDestroy(token!, unitId));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/receptionist_api_service.dart';
import 'package:hms_mobile/features/receptionist/models/insurance_claim.dart';

class InsuranceClaimsViewModel extends ChangeNotifier {
  final ReceptionistApiService _api;
  final AuthStorage _authStorage;

  InsuranceClaimsViewModel({ReceptionistApiService? api, AuthStorage? authStorage})
      : _api = api ?? ReceptionistApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  InsuranceClaimStats? stats;
  List<InsuranceClaim> claims = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      final result = await guardNetworkErrors(() => _api.insuranceClaims(token!));
      stats = result.$1;
      claims = result.$2;
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> store(Map<String, dynamic> fields) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.insuranceClaimStore(token!, fields));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> destroy(int id) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.insuranceClaimDestroy(token!, id));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

class InsuranceClaimDetailViewModel extends ChangeNotifier {
  final ReceptionistApiService _api;
  final AuthStorage _authStorage;
  final int claimId;

  InsuranceClaimDetailViewModel({required this.claimId, ReceptionistApiService? api, AuthStorage? authStorage})
      : _api = api ?? ReceptionistApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  bool isSaving = false;
  String? loadError;
  InsuranceClaim? claim;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      claim = await guardNetworkErrors(() => _api.insuranceClaimDetail(token!, claimId));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> update(Map<String, dynamic> fields) async {
    isSaving = true;
    notifyListeners();
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.insuranceClaimUpdate(token!, claimId, fields));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> updateStatus(Map<String, dynamic> fields) async {
    isSaving = true;
    notifyListeners();
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.insuranceClaimUpdateStatus(token!, claimId, fields));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> destroy() async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.insuranceClaimDestroy(token!, claimId));
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

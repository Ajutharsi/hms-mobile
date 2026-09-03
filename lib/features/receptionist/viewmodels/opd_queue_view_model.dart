import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/receptionist_api_service.dart';
import 'package:hms_mobile/features/receptionist/models/opd_token.dart';

class OpdQueueViewModel extends ChangeNotifier {
  final ReceptionistApiService _api;
  final AuthStorage _authStorage;

  OpdQueueViewModel({ReceptionistApiService? api, AuthStorage? authStorage})
      : _api = api ?? ReceptionistApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  OpdQueueStats? stats;
  List<OpdToken> tokens = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      final result = await guardNetworkErrors(() => _api.opdQueue(token!));
      stats = result.$1;
      tokens = result.$2;
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> issueToken({required int patientId, required int doctorId, String? notes}) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.opdQueueStore(token!, patientId: patientId, doctorId: doctorId, notes: notes));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateStatus(int tokenId, String status) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.opdQueueUpdateStatus(token!, tokenId, status));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> callNext(int doctorId) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.opdQueueCallNext(token!, doctorId));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> destroy(int tokenId) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.opdQueueDestroy(token!, tokenId));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

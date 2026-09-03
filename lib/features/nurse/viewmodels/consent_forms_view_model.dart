import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, guardNetworkErrors;
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/consent_form.dart';

class ConsentFormsViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;

  ConsentFormsViewModel({NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<ConsentForm> forms = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      forms = await guardNetworkErrors(() => _api.consentFormsList(token!));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateStatus(int id, String status) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.consentFormUpdateStatus(token!, id, status));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> sign(int id, {required String patientSignature, String? witnessSignature}) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.consentFormSign(token!, id, patientSignature: patientSignature, witnessSignature: witnessSignature));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> destroy(int id) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.consentFormDestroy(token!, id));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

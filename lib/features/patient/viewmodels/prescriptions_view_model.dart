import 'package:flutter/material.dart';

import 'package:hms_mobile/features/patient/models/prescription.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';

class PrescriptionsViewModel extends ChangeNotifier {
  final ApiService _api;
  final AuthStorage _authStorage;

  PrescriptionsViewModel({ApiService? api, AuthStorage? authStorage})
      : _api = api ?? ApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    loadPrescriptions();
  }

  bool isLoading = true;
  String? errorMessage;
  List<Prescription> prescriptions = [];

  Future<void> loadPrescriptions() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      prescriptions = await guardNetworkErrors(() => _api.getPrescriptions(token!));
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

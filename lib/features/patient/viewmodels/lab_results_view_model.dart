import 'package:flutter/material.dart';

import 'package:hms_mobile/features/patient/models/lab_order.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/features/patient/services/patient_api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';

class LabResultsViewModel extends ChangeNotifier {
  final PatientApiService _api;
  final AuthStorage _authStorage;

  LabResultsViewModel({PatientApiService? api, AuthStorage? authStorage})
      : _api = api ?? PatientApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    loadLabResults();
  }

  bool isLoading = true;
  String? errorMessage;
  List<LabOrder> labOrders = [];

  Future<void> loadLabResults() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      labOrders = await guardNetworkErrors(() => _api.getLabResults(token!));
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/receptionist_api_service.dart';
import 'package:hms_mobile/features/receptionist/models/reception_patient.dart';

class ReceptionPatientsViewModel extends ChangeNotifier {
  final ReceptionistApiService _api;
  final AuthStorage _authStorage;

  ReceptionPatientsViewModel({ReceptionistApiService? api, AuthStorage? authStorage})
      : _api = api ?? ReceptionistApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<ReceptionPatient> patients = [];
  String? typeFilter;
  String _query = '';

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      patients = await guardNetworkErrors(() => _api.patients(token!, q: _query.isEmpty ? null : _query, type: typeFilter));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _query = query;
    load();
  }

  void setTypeFilter(String? type) {
    typeFilter = type;
    load();
  }
}

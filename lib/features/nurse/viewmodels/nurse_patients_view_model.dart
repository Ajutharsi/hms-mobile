import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/nurse_patient.dart';

class NursePatientsViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;

  NursePatientsViewModel({NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<NursePatient> patients = [];
  String query = '';
  String? typeFilter;
  Timer? _debounce;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      patients = await guardNetworkErrors(() => _api.patients(token!, q: query, type: typeFilter));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void search(String value) {
    query = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), load);
  }

  void setTypeFilter(String? type) {
    if (typeFilter == type) return;
    typeFilter = type;
    load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/pharmacy_api_service.dart';
import 'package:hms_mobile/features/pharmacy/models/dispensing.dart';

class DispensingListViewModel extends ChangeNotifier {
  final PharmacyApiService _api;
  final AuthStorage _authStorage;

  DispensingListViewModel({PharmacyApiService? api, AuthStorage? authStorage})
      : _api = api ?? PharmacyApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<Dispensing> dispensings = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      dispensings = await guardNetworkErrors(() => _api.dispensingList(token!));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class DispensingDetailViewModel extends ChangeNotifier {
  final PharmacyApiService _api;
  final AuthStorage _authStorage;
  final int dispensingId;

  DispensingDetailViewModel({required this.dispensingId, PharmacyApiService? api, AuthStorage? authStorage})
      : _api = api ?? PharmacyApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  DispensingDetail? detail;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      detail = await guardNetworkErrors(() => _api.dispensingDetail(token!, dispensingId));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

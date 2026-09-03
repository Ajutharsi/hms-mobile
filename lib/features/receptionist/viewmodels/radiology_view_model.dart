import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/receptionist_api_service.dart';
import 'package:hms_mobile/features/receptionist/models/radiology_order.dart';

class RadiologyViewModel extends ChangeNotifier {
  final ReceptionistApiService _api;
  final AuthStorage _authStorage;

  RadiologyViewModel({ReceptionistApiService? api, AuthStorage? authStorage})
      : _api = api ?? ReceptionistApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  RadiologyStats? stats;
  List<RadiologyOrder> orders = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      final result = await guardNetworkErrors(() => _api.radiologyOrders(token!));
      stats = result.$1;
      orders = result.$2;
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class RadiologyDetailViewModel extends ChangeNotifier {
  final ReceptionistApiService _api;
  final AuthStorage _authStorage;
  final int orderId;

  RadiologyDetailViewModel({required this.orderId, ReceptionistApiService? api, AuthStorage? authStorage})
      : _api = api ?? ReceptionistApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  bool isSaving = false;
  String? loadError;
  RadiologyOrder? order;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      order = await guardNetworkErrors(() => _api.radiologyDetail(token!, orderId));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> enterFindings({String? findings, String? impression, String? radiologistName}) async {
    isSaving = true;
    notifyListeners();
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.radiologyEnterFindings(token!, orderId, {
            if (findings != null && findings.isNotEmpty) 'findings': findings,
            if (impression != null && impression.isNotEmpty) 'impression': impression,
            if (radiologistName != null && radiologistName.isNotEmpty) 'radiologist_name': radiologistName,
          }));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> update(Map<String, dynamic> fields) async {
    isSaving = true;
    notifyListeners();
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.radiologyUpdate(token!, orderId, fields));
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
      await guardNetworkErrors(() => _api.radiologyDestroy(token!, orderId));
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/lab_api_service.dart';
import 'package:hms_mobile/features/lab/models/lab_order.dart';

class LabOrdersViewModel extends ChangeNotifier {
  final LabApiService _api;
  final AuthStorage _authStorage;

  LabOrdersViewModel({LabApiService? api, AuthStorage? authStorage})
      : _api = api ?? LabApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<LabOrder> orders = [];
  String? statusFilter;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      orders = await guardNetworkErrors(() => _api.labOrders(token!, status: statusFilter));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String? status) {
    statusFilter = status;
    load();
  }
}

class LabOrderDetailViewModel extends ChangeNotifier {
  final LabApiService _api;
  final AuthStorage _authStorage;
  final int orderId;

  LabOrderDetailViewModel({required this.orderId, LabApiService? api, AuthStorage? authStorage})
      : _api = api ?? LabApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  bool isSaving = false;
  String? loadError;
  LabOrderDetail? order;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      order = await guardNetworkErrors(() => _api.labOrderDetail(token!, orderId));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> saveResults(List<Map<String, dynamic>> results) async {
    isSaving = true;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.labOrderEnterResults(token!, orderId, results));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}

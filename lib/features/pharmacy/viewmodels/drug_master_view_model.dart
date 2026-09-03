import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/pharmacy_api_service.dart';
import 'package:hms_mobile/features/pharmacy/models/drug.dart';

class DrugMasterViewModel extends ChangeNotifier {
  final PharmacyApiService _api;
  final AuthStorage _authStorage;

  DrugMasterViewModel({PharmacyApiService? api, AuthStorage? authStorage})
      : _api = api ?? PharmacyApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<Drug> drugs = [];
  String? query;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      drugs = await guardNetworkErrors(() => _api.drugs(token!, q: query));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void search(String q) {
    query = q;
    load();
  }

  Future<String?> save({int? id, required Map<String, dynamic> fields}) async {
    try {
      final token = await _authStorage.readToken();
      if (id == null) {
        await guardNetworkErrors(() => _api.drugStore(token!, fields));
      } else {
        await guardNetworkErrors(() => _api.drugUpdate(token!, id, fields));
      }
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> destroy(int id) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.drugDestroy(token!, id));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> addStock(int id, {required int quantity, required String reason, String? notes}) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.drugAddStock(token!, id, quantity: quantity, reason: reason, notes: notes));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<List<DrugStockEntry>> stockHistory(int id) async {
    final token = await _authStorage.readToken();
    return guardNetworkErrors(() => _api.drugStockHistory(token!, id));
  }
}

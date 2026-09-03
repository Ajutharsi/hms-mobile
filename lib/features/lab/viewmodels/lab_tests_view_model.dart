import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/lab_api_service.dart';
import 'package:hms_mobile/features/lab/models/lab_test.dart';

class LabTestsViewModel extends ChangeNotifier {
  final LabApiService _api;
  final AuthStorage _authStorage;

  LabTestsViewModel({LabApiService? api, AuthStorage? authStorage})
      : _api = api ?? LabApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<LabTest> tests = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      tests = await guardNetworkErrors(() => _api.labTests(token!));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> save({
    int? id,
    required String testName,
    required String category,
    required String sampleType,
    required double price,
    String? unit,
    String? normalRangeMale,
    String? normalRangeFemale,
    String? description,
    required String status,
  }) async {
    try {
      final token = await _authStorage.readToken();
      if (id == null) {
        await guardNetworkErrors(() => _api.labTestStore(
              token!,
              testName: testName,
              category: category,
              sampleType: sampleType,
              price: price,
              unit: unit,
              normalRangeMale: normalRangeMale,
              normalRangeFemale: normalRangeFemale,
              description: description,
              status: status,
            ));
      } else {
        await guardNetworkErrors(() => _api.labTestUpdate(
              token!,
              id,
              testName: testName,
              category: category,
              sampleType: sampleType,
              price: price,
              unit: unit,
              normalRangeMale: normalRangeMale,
              normalRangeFemale: normalRangeFemale,
              description: description,
              status: status,
            ));
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
      await guardNetworkErrors(() => _api.labTestDestroy(token!, id));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/icu_chart.dart';

class IcuViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;

  IcuViewModel({NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<IcuChart> charts = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      charts = await guardNetworkErrors(() => _api.icuList(token!));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> destroy(int id) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.icuDestroy(token!, id));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/receptionist_api_service.dart';
import 'package:hms_mobile/features/receptionist/models/referral.dart';

class ReferralsViewModel extends ChangeNotifier {
  final ReceptionistApiService _api;
  final AuthStorage _authStorage;

  ReferralsViewModel({ReceptionistApiService? api, AuthStorage? authStorage})
      : _api = api ?? ReceptionistApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<Referral> referrals = [];
  String? statusFilter;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      referrals = await guardNetworkErrors(() => _api.referrals(token!, status: statusFilter));
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

  Future<String?> store(Map<String, dynamic> fields) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.referralStore(token!, fields));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateStatus(int id, String status) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.referralUpdateStatus(token!, id, status));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> destroy(int id) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.referralDestroy(token!, id));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/receptionist_api_service.dart';
import 'package:hms_mobile/features/receptionist/models/ipd_deposit.dart';

class IpdDepositsViewModel extends ChangeNotifier {
  final ReceptionistApiService _api;
  final AuthStorage _authStorage;

  IpdDepositsViewModel({ReceptionistApiService? api, AuthStorage? authStorage})
      : _api = api ?? ReceptionistApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  IpdDepositStats? stats;
  List<IpdDeposit> deposits = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      final result = await guardNetworkErrors(() => _api.ipdDeposits(token!));
      stats = result.$1;
      deposits = result.$2;
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> store({required int patientId, required double amount, required String paymentMethod, String? referenceNo, String? notes}) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.ipdDepositStore(token!, patientId: patientId, amount: amount, paymentMethod: paymentMethod, referenceNo: referenceNo, notes: notes));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> refund(int depositId, {required double amount, required String paymentMethod, String? notes}) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.ipdDepositRefund(token!, depositId, amount: amount, paymentMethod: paymentMethod, notes: notes));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

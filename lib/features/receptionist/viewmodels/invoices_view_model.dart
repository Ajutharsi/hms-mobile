import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/receptionist_api_service.dart';
import 'package:hms_mobile/features/receptionist/models/invoice.dart';

class InvoicesViewModel extends ChangeNotifier {
  final ReceptionistApiService _api;
  final AuthStorage _authStorage;

  InvoicesViewModel({ReceptionistApiService? api, AuthStorage? authStorage})
      : _api = api ?? ReceptionistApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  InvoiceStats? stats;
  List<Invoice> invoices = [];
  String? statusFilter;
  String query = '';

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      final results = await Future.wait([
        guardNetworkErrors(() => _api.invoicesStats(token!)),
        guardNetworkErrors(() => _api.invoices(token!, status: statusFilter, q: query.isEmpty ? null : query)),
      ]);
      stats = results[0] as InvoiceStats;
      invoices = results[1] as List<Invoice>;
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

  void search(String q) {
    query = q;
    load();
  }
}

class InvoiceDetailViewModel extends ChangeNotifier {
  final ReceptionistApiService _api;
  final AuthStorage _authStorage;
  final int invoiceId;

  InvoiceDetailViewModel({required this.invoiceId, ReceptionistApiService? api, AuthStorage? authStorage})
      : _api = api ?? ReceptionistApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  bool isSaving = false;
  String? loadError;
  InvoiceDetail? invoice;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      invoice = await guardNetworkErrors(() => _api.invoiceDetail(token!, invoiceId));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> addPayment({required double amount, required String paymentMethod, String? referenceNo, String? notes}) async {
    isSaving = true;
    notifyListeners();
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.invoiceAddPayment(token!, invoiceId, amount: amount, paymentMethod: paymentMethod, referenceNo: referenceNo, notes: notes));
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

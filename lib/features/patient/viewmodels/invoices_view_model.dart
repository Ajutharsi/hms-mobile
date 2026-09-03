import 'package:flutter/material.dart';

import 'package:hms_mobile/features/patient/models/invoice.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';

class InvoicesViewModel extends ChangeNotifier {
  final ApiService _api;
  final AuthStorage _authStorage;

  InvoicesViewModel({ApiService? api, AuthStorage? authStorage})
      : _api = api ?? ApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    loadInvoices();
  }

  bool isLoading = true;
  String? errorMessage;
  List<Invoice> invoices = [];

  /// IDs of invoices currently sending a help request, so each card can
  /// show its own spinner without blocking the rest of the list.
  final Set<int> requestingHelpFor = {};

  Future<void> loadInvoices() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      invoices = await guardNetworkErrors(() => _api.getInvoices(token!));
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Returns an error message on failure, or null on success.
  Future<String?> requestHelp(int invoiceId) async {
    requestingHelpFor.add(invoiceId);
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.requestInvoiceHelp(token!, invoiceId));
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      requestingHelpFor.remove(invoiceId);
      notifyListeners();
    }
  }
}

import 'package:flutter/material.dart';

import 'package:hms_mobile/features/admin/services/admin_api_service.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';

/// One load/refresh/error cycle, shared by every admin section.
///
/// Twelve screens that each fetch one payload would otherwise be twelve
/// copies of the same twenty lines; the only thing that differs is the
/// call itself, so that is the only thing a subclass supplies.
///
/// [T] is whatever the section's endpoint returns — a record, a list, a
/// model. Screens read [data] and are responsible for the null case,
/// which CareStateView already covers.
abstract class AdminSectionViewModel<T> extends ChangeNotifier {
  @protected
  final AdminApiService api;
  final AuthStorage _authStorage;

  AdminSectionViewModel({AdminApiService? api, AuthStorage? authStorage})
      : api = api ?? AdminApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  T? data;

  /// The section's own request. [token] is already read and non-null.
  @protected
  Future<T> fetch(String token);

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      data = await guardNetworkErrors(() => fetch(token!));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Runs a write and reloads on success. Returns null when it worked, or
  /// the message to show when it did not — the shape every screen's
  /// snackbar already expects.
  ///
  /// The client is handed to the closure rather than exposed as a field:
  /// a screen says which call to make without being able to reach past
  /// the view model and make one that never reloads.
  Future<String?> mutate(Future<void> Function(AdminApiService api, String token) action) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => action(api, token!));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

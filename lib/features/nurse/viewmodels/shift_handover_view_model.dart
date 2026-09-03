import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/shift_handover.dart';

/// Backs the Shift Handover list screen. Also resolves the current user's
/// name once (via the generic `/me` endpoint) — `ShiftHandoverDetail` only
/// exposes nurse *names*, not ids, so "am I the outgoing/incoming nurse"
/// has to be a name comparison; this saves the detail screen from doing
/// its own extra round trip.
class ShiftHandoverViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final ApiService _authApi;
  final AuthStorage _authStorage;

  ShiftHandoverViewModel({NurseApiService? api, ApiService? authApi, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authApi = authApi ?? ApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<ShiftHandoverSummary> handovers = [];
  String? statusFilter;
  String? currentUserName;

  Future<void> setStatusFilter(String? status) async {
    statusFilter = status;
    await load();
  }

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      final results = await guardNetworkErrors(() => Future.wait([
            _api.handoversList(token!, status: statusFilter),
            currentUserName == null ? _authApi.me(token).then((u) => u.name) : Future.value(currentUserName),
          ]));
      handovers = results[0] as List<ShiftHandoverSummary>;
      currentUserName = results[1] as String?;
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

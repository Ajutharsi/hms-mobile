import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/features/me/services/me_api_service.dart';
import 'package:hms_mobile/features/me/models/me_models.dart';

/// Shared plumbing for the three self-service screens.
abstract class _MeViewModel extends ChangeNotifier {
  final MeApiService api;
  final AuthStorage authStorage;

  _MeViewModel({MeApiService? api, AuthStorage? authStorage})
      : api = api ?? MeApiService(),
        authStorage = authStorage ?? AuthStorage();

  bool isLoading = true;
  String? loadError;

  Future<String> token() async => (await authStorage.readToken())!;

  Future<void> guarded(Future<void> Function() action) async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      await guardNetworkErrors(action);
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Null on success, else the message to show.
  Future<String?> mutate(Future<void> Function(MeApiService api, String token) action) async {
    try {
      await guardNetworkErrors(() async => action(api, await token()));
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

/// Attendance and leave on one screen, the way the plan lists them.
class MyWorkViewModel extends _MeViewModel {
  MyWorkViewModel({super.api, super.authStorage}) {
    load();
  }

  MyAttendance? attendance;
  MyLeaves? leaves;

  /// The month being shown, as YYYY-MM.
  String? month;

  Future<void> load() => guarded(() async {
        final t = await token();
        attendance = await api.attendance(t, month: month);
        leaves = await api.leaves(t);
      });

  void showMonth(DateTime value) {
    month = '${value.year}-${value.month.toString().padLeft(2, '0')}';
    load();
  }
}

class InboxViewModel extends _MeViewModel {
  InboxViewModel({super.api, super.authStorage}) {
    load();
  }

  Inbox? inbox;

  Future<void> load() => guarded(() async {
        inbox = await api.inbox(await token());
      });

  Future<String?> markAllRead() async {
    final error = await mutate((api, token) => api.markRead(token));
    if (error == null) await load();
    return error;
  }
}

/// Debounced so typing does not fire a request per keystroke.
class SearchViewModel extends _MeViewModel {
  SearchViewModel({super.api, super.authStorage}) {
    isLoading = false;
  }

  Timer? _debounce;
  String query = '';
  bool isSearching = false;
  List<SearchHit> hits = [];

  void search(String value) {
    query = value;
    _debounce?.cancel();

    if (value.trim().length < 2) {
      hits = [];
      isSearching = false;
      notifyListeners();
      return;
    }

    isSearching = true;
    notifyListeners();
    _debounce = Timer(const Duration(milliseconds: 350), _run);
  }

  Future<void> _run() async {
    final asked = query;
    try {
      final results = await guardNetworkErrors(() async => api.search(await token(), asked));
      // A slower earlier request must not overwrite a newer answer.
      if (asked != query) return;
      hits = results;
      loadError = null;
    } on ApiException catch (e) {
      if (asked != query) return;
      loadError = e.message;
      hits = [];
    } finally {
      if (asked == query) {
        isSearching = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

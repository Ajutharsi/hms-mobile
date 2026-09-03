import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/nursing_note.dart';

class NursingNotesViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;

  NursingNotesViewModel({NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<NursingNote> notes = [];

  Future<String?> _token() => _authStorage.readToken();

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _token();
      notes = await guardNetworkErrors(() => _api.nursingNotesList(token!));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> create({required int patientId, required String noteType, String? shift, required String note, required String priority}) async {
    try {
      final token = await _token();
      await guardNetworkErrors(() => _api.nursingNoteStore(token!, patientId: patientId, noteType: noteType, shift: shift, note: note, priority: priority));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> update(int noteId, {required String noteType, String? shift, required String note, required String priority}) async {
    try {
      final token = await _token();
      await guardNetworkErrors(() => _api.nursingNoteUpdate(token!, noteId, noteType: noteType, shift: shift, note: note, priority: priority));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> destroy(int noteId) async {
    try {
      final token = await _token();
      await guardNetworkErrors(() => _api.nursingNoteDestroy(token!, noteId));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

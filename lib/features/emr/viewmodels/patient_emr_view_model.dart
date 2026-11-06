import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/emr_api_service.dart';
import 'package:hms_mobile/features/emr/models/emr_models.dart';

/// Loads one patient's record and applies the small writes the screen
/// offers. Every write reloads, because allergies and problems are the
/// kind of thing two people edit at once on a ward.
class PatientEmrViewModel extends ChangeNotifier {
  final int patientId;
  final EmrApiService api;
  final AuthStorage authStorage;

  PatientEmrViewModel({
    required this.patientId,
    EmrApiService? api,
    AuthStorage? authStorage,
  })  : api = api ?? EmrApiService(),
        authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  bool isSaving = false;
  String? loadError;
  PatientEmr? record;

  Future<String> _token() async => (await authStorage.readToken())!;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      await guardNetworkErrors(() async {
        record = await api.record(await _token(), patientId);
      });
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Runs a write and reloads. Returns null on success, else the message
  /// to show.
  Future<String?> mutate(Future<void> Function(EmrApiService api, String token) action) async {
    isSaving = true;
    notifyListeners();
    try {
      await guardNetworkErrors(() async => action(api, await _token()));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> uploadPhoto({
    required Uint8List bytes,
    required String filename,
    String? description,
  }) =>
      mutate((api, token) => api.uploadAttachment(
            token,
            patientId,
            bytes: bytes,
            filename: filename,
            description: description,
          ));
}

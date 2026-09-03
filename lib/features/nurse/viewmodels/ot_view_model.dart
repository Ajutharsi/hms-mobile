import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/ot_schedule.dart';

class OtViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;

  OtViewModel({NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<OtSchedule> schedules = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      schedules = await guardNetworkErrors(() => _api.otList(token!));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> start(int id) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.otStart(token!, id));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> complete(int id, {String? postOpNotes, String? complications}) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.otComplete(token!, id, postOpNotes: postOpNotes, complications: complications));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> cancel(int id) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.otDestroy(token!, id));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> schedule({
    required int patientId,
    int? surgeonId,
    int? anaesthetistId,
    String? theatreNo,
    required String procedureName,
    String? icd10Code,
    String? anaesthesiaType,
    required String priority,
    required String scheduledStart,
    String? scheduledEnd,
    String? preOpNotes,
  }) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.otStore(
            token!,
            patientId: patientId,
            surgeonId: surgeonId,
            anaesthetistId: anaesthetistId,
            theatreNo: theatreNo,
            procedureName: procedureName,
            icd10Code: icd10Code,
            anaesthesiaType: anaesthesiaType,
            priority: priority,
            scheduledStart: scheduledStart,
            scheduledEnd: scheduledEnd,
            preOpNotes: preOpNotes,
          ));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

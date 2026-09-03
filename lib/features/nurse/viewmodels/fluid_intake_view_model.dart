import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, guardNetworkErrors;
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/fluid_intake.dart';

class FluidIntakeViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;

  FluidIntakeViewModel({NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<FluidIntakePatient> patients = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      patients = await guardNetworkErrors(() => _api.fluidIntakeList(token!));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class FluidIntakeDetailViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;
  final int patientId;

  FluidIntakeDetailViewModel({required this.patientId, NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<FluidLog> logs = [];
  num todayIntake = 0;
  num todayOutput = 0;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      final result = await guardNetworkErrors(() => _api.fluidIntakeDetail(token!, patientId));
      logs = result.$1;
      todayIntake = result.$2;
      todayOutput = result.$3;
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> logFluid({required String flowType, required String category, required int amountMl, required String logTime, String? notes}) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.fluidIntakeLog(token!, patientId, flowType: flowType, category: category, amountMl: amountMl, logTime: logTime, notes: notes));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteLog(int logId) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.fluidIntakeDestroy(token!, logId));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

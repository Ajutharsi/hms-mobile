import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, guardNetworkErrors;
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/food_intake.dart';

class FoodIntakeViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;

  FoodIntakeViewModel({NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<FoodIntakePatient> patients = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      patients = await guardNetworkErrors(() => _api.foodIntakeList(token!));
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class FoodIntakeDetailViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;
  final int patientId;

  FoodIntakeDetailViewModel({required this.patientId, NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  DietPlan? dietPlan;
  List<FoodLog> logs = [];

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      final result = await guardNetworkErrors(() => _api.foodIntakeDetail(token!, patientId));
      dietPlan = result.$1;
      logs = result.$2;
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateDietPlan({required String dietType, String? restrictions, String? notes}) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.foodIntakeStoreDietPlan(token!, patientId, dietType: dietType, restrictions: restrictions, notes: notes));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> logMeal({required String mealType, required String status, String? quantity, String? notes}) async {
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.foodIntakeLogMeal(token!, patientId, mealType: mealType, status: status, quantity: quantity, notes: notes));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

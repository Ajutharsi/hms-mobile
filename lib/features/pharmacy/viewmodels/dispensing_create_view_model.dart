import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/pharmacy_api_service.dart';
import 'package:hms_mobile/features/pharmacy/models/drug.dart';
import 'package:hms_mobile/features/pharmacy/models/pharmacy_patient.dart';

class DispenseLine {
  final Drug drug;
  int quantity;
  DispenseLine({required this.drug, this.quantity = 1});
}

class DispensingCreateViewModel extends ChangeNotifier {
  final PharmacyApiService _api;
  final AuthStorage _authStorage;

  DispensingCreateViewModel({PharmacyApiService? api, AuthStorage? authStorage})
      : _api = api ?? PharmacyApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    _loadDrugs();
  }

  bool isLoadingDrugs = true;
  bool isSaving = false;
  List<Drug> availableDrugs = [];

  List<PharmacyPatient> patientResults = [];
  bool isSearchingPatients = false;
  PharmacyPatient? selectedPatient;

  final List<DispenseLine> lines = [];

  Future<void> _loadDrugs() async {
    isLoadingDrugs = true;
    notifyListeners();
    try {
      final token = await _authStorage.readToken();
      final drugs = await guardNetworkErrors(() => _api.drugs(token!));
      availableDrugs = drugs.where((d) => d.status == 'active' && d.currentStock > 0).toList();
    } catch (_) {
      availableDrugs = [];
    } finally {
      isLoadingDrugs = false;
      notifyListeners();
    }
  }

  Future<void> searchPatients(String query) async {
    if (query.trim().isEmpty) {
      patientResults = [];
      notifyListeners();
      return;
    }
    isSearchingPatients = true;
    notifyListeners();
    try {
      final token = await _authStorage.readToken();
      patientResults = await guardNetworkErrors(() => _api.patients(token!, q: query));
    } catch (_) {
      patientResults = [];
    } finally {
      isSearchingPatients = false;
      notifyListeners();
    }
  }

  void selectPatient(PharmacyPatient patient) {
    selectedPatient = patient;
    patientResults = [];
    notifyListeners();
  }

  void clearPatient() {
    selectedPatient = null;
    notifyListeners();
  }

  void addLine(Drug drug) {
    if (lines.any((l) => l.drug.id == drug.id)) return;
    lines.add(DispenseLine(drug: drug));
    notifyListeners();
  }

  void removeLine(int drugId) {
    lines.removeWhere((l) => l.drug.id == drugId);
    notifyListeners();
  }

  void setQuantity(int drugId, int quantity) {
    final line = lines.firstWhere((l) => l.drug.id == drugId);
    line.quantity = quantity.clamp(1, line.drug.currentStock);
    notifyListeners();
  }

  Future<(int?, String?)> submit({String? notes}) async {
    if (selectedPatient == null) return (null, 'Pick a patient.');
    if (lines.isEmpty) return (null, 'Add at least one drug.');

    isSaving = true;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      final id = await guardNetworkErrors(() => _api.dispensingStore(
            token!,
            patientId: selectedPatient!.id,
            notes: (notes ?? '').trim().isEmpty ? null : notes,
            items: lines.map((l) => {'drug_id': l.drug.id, 'quantity_dispensed': l.quantity}).toList(),
          ));
      return (id, null);
    } on ApiException catch (e) {
      return (null, e.message);
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}

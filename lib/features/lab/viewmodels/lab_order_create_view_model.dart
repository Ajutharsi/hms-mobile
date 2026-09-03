import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/lab_api_service.dart';
import 'package:hms_mobile/features/lab/models/lab_order.dart';
import 'package:hms_mobile/features/lab/models/lab_test.dart';
import 'package:hms_mobile/features/patient/models/doctor.dart';

class LabOrderCreateViewModel extends ChangeNotifier {
  final LabApiService _labApi;
  final ApiService _api;
  final AuthStorage _authStorage;

  LabOrderCreateViewModel({LabApiService? labApi, ApiService? api, AuthStorage? authStorage})
      : _labApi = labApi ?? LabApiService(),
        _api = api ?? ApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    _loadTestsAndDoctors();
  }

  bool isLoadingMeta = true;
  bool isSaving = false;
  List<LabTest> availableTests = [];
  List<Doctor> doctors = [];

  List<LabPatient> patientResults = [];
  bool isSearchingPatients = false;
  LabPatient? selectedPatient;
  Doctor? selectedDoctor;
  final Set<int> selectedTestIds = {};

  Future<void> _loadTestsAndDoctors() async {
    isLoadingMeta = true;
    notifyListeners();
    try {
      final token = await _authStorage.readToken();
      final results = await Future.wait([_labApi.labTests(token!), _api.getDoctors(token)]);
      availableTests = (results[0] as List<LabTest>).where((t) => t.status == 'active').toList();
      doctors = results[1] as List<Doctor>;
    } catch (_) {
      // Leave lists empty — the form still shows a friendly "no options" state.
    } finally {
      isLoadingMeta = false;
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
      patientResults = await guardNetworkErrors(() => _labApi.patients(token!, q: query));
    } catch (_) {
      patientResults = [];
    } finally {
      isSearchingPatients = false;
      notifyListeners();
    }
  }

  void selectPatient(LabPatient patient) {
    selectedPatient = patient;
    patientResults = [];
    notifyListeners();
  }

  void clearPatient() {
    selectedPatient = null;
    notifyListeners();
  }

  void selectDoctor(Doctor? doctor) {
    selectedDoctor = doctor;
    notifyListeners();
  }

  void toggleTest(int testId) {
    if (selectedTestIds.contains(testId)) {
      selectedTestIds.remove(testId);
    } else {
      selectedTestIds.add(testId);
    }
    notifyListeners();
  }

  Future<(int?, String?)> submit({String? notes}) async {
    if (selectedPatient == null) return (null, 'Pick a patient.');
    if (selectedDoctor == null) return (null, 'Pick a doctor.');
    if (selectedTestIds.isEmpty) return (null, 'Pick at least one test.');

    isSaving = true;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      final id = await guardNetworkErrors(() => _labApi.labOrderStore(
            token!,
            patientId: selectedPatient!.id,
            doctorId: selectedDoctor!.id,
            tests: selectedTestIds.toList(),
            notes: (notes ?? '').trim().isEmpty ? null : notes,
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

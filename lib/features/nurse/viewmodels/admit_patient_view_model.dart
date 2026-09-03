import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/nurse_patient.dart';
import 'package:hms_mobile/features/nurse/models/ward.dart';
import 'package:hms_mobile/features/patient/models/doctor.dart';

class AdmitPatientViewModel extends ChangeNotifier {
  final NurseApiService _nurseApi;
  final ApiService _api;
  final AuthStorage _authStorage;

  AdmitPatientViewModel({NurseApiService? nurseApi, ApiService? api, AuthStorage? authStorage})
      : _nurseApi = nurseApi ?? NurseApiService(),
        _api = api ?? ApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    _loadMeta();
  }

  bool isLoadingMeta = true;
  bool isSearchingPatients = false;
  bool isLoadingBeds = false;
  bool isSubmitting = false;
  String? metaError;
  String? errorMessage;

  List<Ward> wards = [];
  List<Doctor> doctors = [];
  List<NursePatient> patientResults = [];
  List<Bed> availableBeds = [];

  NursePatient? selectedPatient;
  Ward? selectedWard;
  Bed? selectedBed;
  Doctor? selectedDoctor;
  DateTime admissionDate = DateTime.now();
  final reasonController = TextEditingController();

  Future<void> _loadMeta() async {
    isLoadingMeta = true;
    metaError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      wards = await guardNetworkErrors(() => _nurseApi.wards(token!));
      doctors = await guardNetworkErrors(() => _api.getDoctors(token!));
    } on ApiException catch (e) {
      metaError = e.message;
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
      patientResults = await guardNetworkErrors(() => _nurseApi.patients(token!, q: query));
    } on ApiException {
      patientResults = [];
    } finally {
      isSearchingPatients = false;
      notifyListeners();
    }
  }

  void selectPatient(NursePatient patient) {
    selectedPatient = patient;
    patientResults = [];
    notifyListeners();
  }

  void clearPatient() {
    selectedPatient = null;
    patientResults = [];
    notifyListeners();
  }

  Future<void> selectWard(Ward? ward) async {
    selectedWard = ward;
    selectedBed = null;
    availableBeds = [];
    notifyListeners();

    if (ward == null) return;

    isLoadingBeds = true;
    notifyListeners();
    try {
      final token = await _authStorage.readToken();
      availableBeds = await guardNetworkErrors(() => _nurseApi.availableBeds(token!, ward.id));
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoadingBeds = false;
      notifyListeners();
    }
  }

  void selectBed(Bed? bed) {
    selectedBed = bed;
    notifyListeners();
  }

  void selectDoctor(Doctor? doctor) {
    selectedDoctor = doctor;
    notifyListeners();
  }

  void selectAdmissionDate(DateTime date) {
    admissionDate = date;
    notifyListeners();
  }

  bool get canSubmit => selectedPatient != null && selectedWard != null && selectedBed != null && selectedDoctor != null;

  /// Returns true on success.
  Future<bool> submit() async {
    if (!canSubmit) return false;

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _nurseApi.admit(
            token!,
            patientId: selectedPatient!.id,
            wardId: selectedWard!.id,
            bedId: selectedBed!.id,
            doctorId: selectedDoctor!.id,
            admissionDate: '${admissionDate.year.toString().padLeft(4, '0')}-${admissionDate.month.toString().padLeft(2, '0')}-${admissionDate.day.toString().padLeft(2, '0')}',
            admissionReason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
          ));
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }
}

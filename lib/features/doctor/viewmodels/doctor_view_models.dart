import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/doctor_api_service.dart';
import 'package:hms_mobile/features/doctor/models/doctor_models.dart';

/// Shared plumbing: token lookup and the load/error flags every doctor
/// screen renders.
abstract class _DoctorViewModel extends ChangeNotifier {
  final DoctorApiService api;
  final AuthStorage authStorage;

  _DoctorViewModel({DoctorApiService? api, AuthStorage? authStorage})
      : api = api ?? DoctorApiService(),
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
}

class DoctorDashboardViewModel extends _DoctorViewModel {
  final AppUser user;

  DoctorDashboardViewModel({required this.user, super.api, super.authStorage}) {
    load();
  }

  bool isLoggingOut = false;
  DoctorDashboardStats? stats;
  List<DoctorAppointment> todayAppointments = [];
  List<DoctorPatient> recentPatients = [];

  Future<void> load() => guarded(() async {
        final result = await api.dashboard(await token());
        stats = result.stats;
        todayAppointments = result.today;
        recentPatients = result.recentPatients;
      });

  Future<void> logout() async {
    isLoggingOut = true;
    notifyListeners();
    final saved = await authStorage.readToken();
    if (saved != null) {
      try {
        await ApiService().logout(saved);
      } catch (_) {
        // Offline logout still clears the device so nobody stays signed in.
      }
    }
    await authStorage.clear();
    isLoggingOut = false;
    notifyListeners();
  }
}

class DoctorAppointmentsViewModel extends _DoctorViewModel {
  DoctorAppointmentsViewModel({super.api, super.authStorage}) {
    load();
  }

  List<DoctorAppointment> appointments = [];
  String filter = 'all'; // all | today | scheduled | completed

  Future<void> load() => guarded(() async {
        appointments = await api.appointments(
          await token(),
          status: (filter == 'scheduled' || filter == 'completed') ? filter : null,
          todayOnly: filter == 'today',
        );
      });

  void setFilter(String value) {
    if (filter == value) return;
    filter = value;
    load();
  }
}

class DoctorAppointmentDetailViewModel extends _DoctorViewModel {
  final int appointmentId;

  DoctorAppointmentDetailViewModel({required this.appointmentId, super.api, super.authStorage}) {
    load();
  }

  DoctorAppointmentDetail? detail;

  Future<void> load() => guarded(() async {
        detail = await api.appointmentDetail(await token(), appointmentId);
      });
}

/// The consultation form — including the diagnosis-code lookup, which is
/// debounced so typing doesn't fire a request per keystroke.
class ConsultationFormViewModel extends ChangeNotifier {
  final DoctorApiService _api;
  final AuthStorage _authStorage;
  final int appointmentId;

  ConsultationFormViewModel({
    required this.appointmentId,
    VitalsSnapshot? prefillVitals,
    DoctorApiService? api,
    AuthStorage? authStorage,
  })  : _api = api ?? DoctorApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    // Nursing's latest readings start the vitals fields; the doctor
    // overwrites them if they take their own.
    bloodPressureController.text = prefillVitals?.bloodPressure ?? '';
    temperatureController.text = prefillVitals?.temperature ?? '';
    pulseController.text = prefillVitals?.pulseRate ?? '';
    spo2Controller.text = prefillVitals?.spo2 ?? '';
  }

  final formKey = GlobalKey<FormState>();
  final chiefComplaintController = TextEditingController();
  final diagnosisController = TextEditingController();
  final treatmentController = TextEditingController();
  final notesController = TextEditingController();
  final bloodPressureController = TextEditingController();
  final temperatureController = TextEditingController();
  final pulseController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final spo2Controller = TextEditingController();

  String? icd10Code;
  List<Icd10Suggestion> suggestions = [];
  bool searchingCodes = false;
  bool isSaving = false;
  String? errorMessage;
  Timer? _debounce;

  String? validateChiefComplaint(String? value) =>
      (value == null || value.trim().length < 2) ? 'Please write the chief complaint.' : null;

  void searchIcd10(String term) {
    _debounce?.cancel();
    if (term.trim().length < 2) {
      suggestions = [];
      notifyListeners();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      searchingCodes = true;
      notifyListeners();
      try {
        suggestions = await guardNetworkErrors(() async => _api.searchIcd10((await _authStorage.readToken())!, term));
      } on ApiException {
        suggestions = [];
      } finally {
        searchingCodes = false;
        notifyListeners();
      }
    });
  }

  void pickCode(Icd10Suggestion suggestion) {
    icd10Code = suggestion.code;
    diagnosisController.text = suggestion.description;
    suggestions = [];
    notifyListeners();
  }

  void clearCode() {
    icd10Code = null;
    notifyListeners();
  }

  /// Returns the saved consultation, or null when validation/API failed.
  Future<DoctorConsultation?> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return null;

    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await guardNetworkErrors(() async => _api.saveConsultation(
            (await _authStorage.readToken())!,
            appointmentId,
            chiefComplaint: chiefComplaintController.text.trim(),
            diagnosis: diagnosisController.text.trim(),
            icd10Code: icd10Code,
            treatmentPlan: treatmentController.text.trim(),
            notes: notesController.text.trim(),
            bloodPressure: bloodPressureController.text.trim(),
            temperature: temperatureController.text.trim(),
            pulseRate: pulseController.text.trim(),
            weight: weightController.text.trim(),
            height: heightController.text.trim(),
            spo2: spo2Controller.text.trim(),
          ));
    } on ApiException catch (e) {
      errorMessage = e.message;
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [
      chiefComplaintController, diagnosisController, treatmentController, notesController,
      bloodPressureController, temperatureController, pulseController, weightController,
      heightController, spo2Controller,
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}

/// One editable medicine row on the prescription form.
class MedicineDraft {
  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final frequencyController = TextEditingController();
  final durationController = TextEditingController();
  final instructionsController = TextEditingController();
  String route = 'oral';

  bool get isBlank => [nameController, dosageController, frequencyController, durationController]
      .every((c) => c.text.trim().isEmpty);

  bool get isComplete => [nameController, dosageController, frequencyController, durationController]
      .every((c) => c.text.trim().isNotEmpty);

  PrescribedMedicine toMedicine() => PrescribedMedicine(
        medicineName: nameController.text.trim(),
        dosage: dosageController.text.trim(),
        frequency: frequencyController.text.trim(),
        duration: durationController.text.trim(),
        route: route,
        instructions: instructionsController.text.trim(),
      );

  void dispose() {
    for (final c in [nameController, dosageController, frequencyController, durationController, instructionsController]) {
      c.dispose();
    }
  }
}

class PrescriptionFormViewModel extends ChangeNotifier {
  final DoctorApiService _api;
  final AuthStorage _authStorage;
  final int consultationId;

  PrescriptionFormViewModel({required this.consultationId, DoctorApiService? api, AuthStorage? authStorage})
      : _api = api ?? DoctorApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    medicines.add(MedicineDraft());
  }

  final notesController = TextEditingController();
  final List<MedicineDraft> medicines = [];
  bool isSaving = false;
  String? errorMessage;

  void addMedicine() {
    medicines.add(MedicineDraft());
    notifyListeners();
  }

  void removeMedicine(int index) {
    if (medicines.length == 1) return;
    medicines.removeAt(index).dispose();
    notifyListeners();
  }

  void setRoute(int index, String route) {
    medicines[index].route = route;
    notifyListeners();
  }

  Future<bool> submit() async {
    final filled = medicines.where((m) => !m.isBlank).toList();
    if (filled.isEmpty) {
      errorMessage = 'Add at least one medicine.';
      notifyListeners();
      return false;
    }
    if (filled.any((m) => !m.isComplete)) {
      errorMessage = 'Each medicine needs a name, dosage, frequency and duration.';
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await guardNetworkErrors(() async => _api.savePrescription(
            (await _authStorage.readToken())!,
            consultationId,
            medicines: filled.map((m) => m.toMedicine()).toList(),
            notes: notesController.text.trim(),
          ));
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    for (final m in medicines) {
      m.dispose();
    }
    super.dispose();
  }
}

class DoctorPatientsViewModel extends _DoctorViewModel {
  DoctorPatientsViewModel({super.api, super.authStorage}) {
    load();
  }

  final searchController = TextEditingController();
  List<DoctorPatient> patients = [];
  Timer? _debounce;

  Future<void> load() => guarded(() async {
        patients = await api.patients(await token(), search: searchController.text.trim());
      });

  void onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), load);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}

class DoctorPatientDetailViewModel extends _DoctorViewModel {
  final int patientId;

  DoctorPatientDetailViewModel({required this.patientId, super.api, super.authStorage}) {
    load();
  }

  DoctorPatientDetail? detail;

  Future<void> load() => guarded(() async {
        detail = await api.patientDetail(await token(), patientId);
      });
}

class DoctorProfileViewModel extends _DoctorViewModel {
  DoctorProfileViewModel({super.api, super.authStorage}) {
    load();
  }

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  DoctorProfile? profile;
  bool isSaving = false;
  String? errorMessage;
  String? successMessage;

  Future<void> load() => guarded(() async {
        profile = await api.profile(await token());
        nameController.text = profile!.name;
        emailController.text = profile!.email;
        phoneController.text = profile!.phone ?? '';
      });

  String? validateName(String? v) => (v == null || v.trim().length < 2) ? 'Enter your name.' : null;
  String? validateEmail(String? v) =>
      (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? 'Enter a valid email.' : null;
  String? validateNewPassword(String? v) =>
      (v != null && v.isNotEmpty && v.length < 8) ? 'At least 8 characters.' : null;
  String? validateConfirm(String? v) =>
      (newPasswordController.text.isNotEmpty && v != newPasswordController.text) ? 'Passwords do not match.' : null;
  String? validateCurrentPassword(String? v) =>
      (newPasswordController.text.isNotEmpty && (v == null || v.isEmpty)) ? 'Enter your current password.' : null;

  Future<bool> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return false;

    isSaving = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();
    try {
      await guardNetworkErrors(() async => api.updateProfile(
            await token(),
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            phone: phoneController.text.trim(),
            currentPassword: currentPasswordController.text,
            password: newPasswordController.text,
            passwordConfirmation: confirmPasswordController.text,
          ));
      successMessage = 'Profile updated successfully!';
      for (final c in [currentPasswordController, newPasswordController, confirmPasswordController]) {
        c.clear();
      }
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final c in [
      nameController, emailController, phoneController,
      currentPasswordController, newPasswordController, confirmPasswordController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}

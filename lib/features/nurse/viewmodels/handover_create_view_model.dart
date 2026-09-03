import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/shift_handover.dart';

class HandoverTaskDraft {
  int? patientId;
  String? patientName;
  final TextEditingController descriptionController = TextEditingController();
}

/// Backs the multi-step "New handover" flow: pick ward/shifts/incoming
/// nurse/date -> edit a card per admitted patient in that ward -> optional
/// tasks -> submit as a draft.
class HandoverCreateViewModel extends ChangeNotifier {
  final NurseApiService _api;
  final AuthStorage _authStorage;

  HandoverCreateViewModel({NurseApiService? api, AuthStorage? authStorage})
      : _api = api ?? NurseApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    loadMeta();
  }

  bool isLoadingMeta = true;
  String? metaError;
  List<Map<String, dynamic>> wards = [];
  List<Map<String, dynamic>> nurses = [];

  int? wardId;
  String currentShift = 'morning';
  String nextShift = 'evening';
  int? incomingNurseId;
  DateTime handoverDate = DateTime.now();
  final shiftSummaryController = TextEditingController();

  bool isLoadingPatients = false;
  String? patientsError;
  List<HandoverPatientCard> patients = [];

  final List<HandoverTaskDraft> tasks = [];

  bool isSubmitting = false;
  String? submitError;

  /// Public re-render trigger for the screen to call after mutating a
  /// [HandoverPatientCard]'s fields in place (those aren't tracked by this
  /// ChangeNotifier directly, so nothing else marks the UI dirty).
  void touch() => notifyListeners();

  Future<void> loadMeta() async {
    isLoadingMeta = true;
    metaError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      final (w, n) = await guardNetworkErrors(() => _api.handoverCreateMeta(token!));
      wards = w;
      nurses = n;
    } on ApiException catch (e) {
      metaError = e.message;
    } finally {
      isLoadingMeta = false;
      notifyListeners();
    }
  }

  Future<void> selectWard(int? id) async {
    wardId = id;
    patients = [];
    notifyListeners();
    if (id == null) return;

    isLoadingPatients = true;
    patientsError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      patients = await guardNetworkErrors(() => _api.handoverWardPatients(token!, id));
    } on ApiException catch (e) {
      patientsError = e.message;
    } finally {
      isLoadingPatients = false;
      notifyListeners();
    }
  }

  void addTask() {
    tasks.add(HandoverTaskDraft());
    notifyListeners();
  }

  void removeTask(int index) {
    tasks[index].descriptionController.dispose();
    tasks.removeAt(index);
    notifyListeners();
  }

  void setTaskPatient(int index, int? patientId, String? patientName) {
    tasks[index].patientId = patientId;
    tasks[index].patientName = patientName;
    notifyListeners();
  }

  /// Returns the new handover's id on success, or null (with [submitError]
  /// set) on failure.
  Future<int?> submit() async {
    if (wardId == null || incomingNurseId == null || patients.isEmpty) {
      submitError = patients.isEmpty
          ? 'This ward has no admitted patients to hand over.'
          : 'Pick a ward and an incoming nurse first.';
      notifyListeners();
      return null;
    }

    isSubmitting = true;
    submitError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      final id = await guardNetworkErrors(() => _api.handoverStore(
            token!,
            wardId: wardId!,
            currentShift: currentShift,
            nextShift: nextShift,
            incomingNurseId: incomingNurseId!,
            handoverDate: '${handoverDate.year.toString().padLeft(4, '0')}-${handoverDate.month.toString().padLeft(2, '0')}-${handoverDate.day.toString().padLeft(2, '0')}',
            shiftSummary: shiftSummaryController.text.trim().isEmpty ? null : shiftSummaryController.text.trim(),
            patients: patients,
            tasks: [
              for (final t in tasks)
                if (t.descriptionController.text.trim().isNotEmpty)
                  {
                    if (t.patientId != null) 'patient_id': t.patientId,
                    'task_description': t.descriptionController.text.trim(),
                  },
            ],
          ));
      return id;
    } on ApiException catch (e) {
      submitError = e.message;
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    shiftSummaryController.dispose();
    for (final t in tasks) {
      t.descriptionController.dispose();
    }
    super.dispose();
  }
}

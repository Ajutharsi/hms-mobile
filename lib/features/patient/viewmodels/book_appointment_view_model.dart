import 'package:flutter/material.dart';

import 'package:hms_mobile/features/patient/models/doctor.dart';
import 'package:hms_mobile/features/patient/models/time_slot.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';

class BookAppointmentViewModel extends ChangeNotifier {
  final ApiService _api;
  final AuthStorage _authStorage;

  BookAppointmentViewModel({ApiService? api, AuthStorage? authStorage})
      : _api = api ?? ApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    loadDoctors();
  }

  final notesController = TextEditingController();

  bool loadingDoctors = true;
  bool loadingSlots = false;
  bool isBooking = false;
  String? errorMessage;

  List<Doctor> doctors = [];
  List<TimeSlot> slots = [];

  Doctor? selectedDoctor;
  DateTime? selectedDate;
  String? selectedTime;
  String visitType = 'op';

  Future<String?> _token() => _authStorage.readToken();

  Future<void> loadDoctors() async {
    loadingDoctors = true;
    notifyListeners();
    try {
      final token = await _token();
      doctors = await guardNetworkErrors(() => _api.getDoctors(token!));
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      loadingDoctors = false;
      notifyListeners();
    }
  }

  void selectDoctor(Doctor? doctor) {
    selectedDoctor = doctor;
    _loadSlots();
  }

  void selectDate(DateTime date) {
    selectedDate = date;
    _loadSlots();
  }

  void selectTime(String time) {
    selectedTime = time;
    notifyListeners();
  }

  void selectVisitType(String type) {
    visitType = type;
    notifyListeners();
  }

  Future<void> _loadSlots() async {
    if (selectedDoctor == null || selectedDate == null) return;

    loadingSlots = true;
    slots = [];
    selectedTime = null;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await _token();
      slots = await guardNetworkErrors(() => _api.getSlots(
            token!,
            doctorId: selectedDoctor!.id,
            date: formatDate(selectedDate!),
          ));
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      loadingSlots = false;
      notifyListeners();
    }
  }

  /// Returns the assigned token number on success, or null (with
  /// [errorMessage] populated) on failure.
  Future<int?> submit() async {
    if (selectedDoctor == null || selectedDate == null || selectedTime == null) {
      errorMessage = 'Please choose a doctor, date, and time.';
      notifyListeners();
      return null;
    }

    isBooking = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await _token();
      final tokenNumber = await guardNetworkErrors(() => _api.bookAppointment(
            token!,
            doctorId: selectedDoctor!.id,
            date: formatDate(selectedDate!),
            time: selectedTime!,
            type: visitType,
            notes: notesController.text.trim(),
          ));
      return tokenNumber ?? 0;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return null;
    } finally {
      isBooking = false;
      notifyListeners();
    }
  }

  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
}

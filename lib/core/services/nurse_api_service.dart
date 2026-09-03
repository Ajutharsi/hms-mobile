import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, ApiService;
import 'package:hms_mobile/features/nurse/models/admission.dart';
import 'package:hms_mobile/features/nurse/models/blood_bank.dart';
import 'package:hms_mobile/features/nurse/models/consent_form.dart';
import 'package:hms_mobile/features/nurse/models/dashboard_stats.dart';
import 'package:hms_mobile/features/nurse/models/er_registration.dart';
import 'package:hms_mobile/features/nurse/models/fluid_intake.dart';
import 'package:hms_mobile/features/nurse/models/food_intake.dart';
import 'package:hms_mobile/features/nurse/models/icu_chart.dart';
import 'package:hms_mobile/features/nurse/models/medication_order.dart';
import 'package:hms_mobile/features/nurse/models/nurse_patient.dart';
import 'package:hms_mobile/features/nurse/models/nurse_profile.dart';
import 'package:hms_mobile/features/nurse/models/nurse_vital.dart';
import 'package:hms_mobile/features/nurse/models/nursing_note.dart';
import 'package:hms_mobile/features/nurse/models/ot_schedule.dart';
import 'package:hms_mobile/features/nurse/models/round_assignment.dart';
import 'package:hms_mobile/features/nurse/models/shift_handover.dart';
import 'package:hms_mobile/features/nurse/models/ward.dart';
import 'package:hms_mobile/features/staff/models/staff_dashboard_stats.dart';

/// JSON client for the Flutter nurse app — mirrors app/Http/Controllers/Api/
/// NurseController.php one-for-one. Same conventions as [ApiService]
/// (token bearer auth, ApiException on failure) but kept as its own class
/// since the nurse role's surface is large and unrelated to the patient one.
class NurseApiService {
  static String get baseUrl => ApiService.baseUrl;

  final http.Client _client;
  NurseApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  dynamic _decode(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection and try again.');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body;
    }

    if (response.statusCode == 422) {
      final errors = (body as Map<String, dynamic>?)?['errors'] as Map<String, dynamic>?;
      final firstError = errors?.values.first;
      final message = firstError is List && firstError.isNotEmpty
          ? firstError.first.toString()
          : (body?['message']?.toString() ?? 'Invalid request.');
      throw ApiException(message);
    }

    if (response.statusCode == 401) {
      throw ApiException('Your session has expired. Please log in again.');
    }
    if (response.statusCode == 403) {
      throw ApiException((body is Map ? body['message']?.toString() : null) ?? 'You are not allowed to do that.');
    }

    throw ApiException((body is Map ? body['message']?.toString() : null) ?? 'Something went wrong (${response.statusCode}).');
  }

  Future<Map<String, dynamic>> _get(String token, String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await _client.get(uri, headers: _headers(token));
    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(String token, String path, Map<String, dynamic> body) async {
    final response = await _client.post(Uri.parse('$baseUrl$path'), headers: _headers(token), body: jsonEncode(body));
    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _put(String token, String path, [Map<String, dynamic> body = const {}]) async {
    final response = await _client.put(Uri.parse('$baseUrl$path'), headers: _headers(token), body: jsonEncode(body));
    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _delete(String token, String path) async {
    final response = await _client.delete(Uri.parse('$baseUrl$path'), headers: _headers(token));
    return _decode(response) as Map<String, dynamic>;
  }

  // ============================================================
  // Dashboard
  // ============================================================

  Future<(NurseDashboardStats, List<DashboardAppointment>, List<DashboardPatient>)> dashboard(String token) async {
    final json = await _get(token, '/nurse/dashboard');
    return (
      NurseDashboardStats.fromJson(json['stats'] as Map<String, dynamic>),
      (json['today_appointments'] as List).map((a) => DashboardAppointment.fromJson(a as Map<String, dynamic>)).toList(),
      (json['recent_patients'] as List).map((p) => DashboardPatient.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }

  Future<(StaffDashboardStats, List<DashboardPatient>)> staffDashboard(String token) async {
    final json = await _get(token, '/staff/dashboard');
    return (
      StaffDashboardStats.fromJson(json['stats'] as Map<String, dynamic>),
      (json['recent_patients'] as List).map((p) => DashboardPatient.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }

  // ============================================================
  // Patients
  // ============================================================

  Future<List<NursePatient>> patients(String token, {String? q, String? type}) async {
    final json = await _get(token, '/nurse/patients', {if (q != null && q.isNotEmpty) 'q': q, if (type != null) 'type': type});
    return (json['patients'] as List).map((p) => NursePatient.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<NursePatientDetail> patientDetail(String token, int patientId) async {
    final json = await _get(token, '/nurse/patients/$patientId');
    return NursePatientDetail.fromJson(json);
  }

  // ============================================================
  // Ward / Admissions
  // ============================================================

  Future<List<Ward>> wards(String token) async {
    final json = await _get(token, '/nurse/wards');
    return (json['wards'] as List).map((w) => Ward.fromJson(w as Map<String, dynamic>)).toList();
  }

  Future<WardDetail> wardDetail(String token, int wardId) async {
    final json = await _get(token, '/nurse/wards/$wardId');
    return WardDetail.fromJson(json);
  }

  Future<List<Bed>> availableBeds(String token, int wardId) async {
    final json = await _get(token, '/nurse/wards/available-beds', {'ward_id': '$wardId'});
    return (json['beds'] as List).map((b) => Bed.fromJson(b as Map<String, dynamic>)).toList();
  }

  Future<List<Admission>> admissions(String token, {String? status}) async {
    final json = await _get(token, '/nurse/admissions', {if (status != null) 'status': status});
    return (json['admissions'] as List).map((a) => Admission.fromJson(a as Map<String, dynamic>)).toList();
  }

  Future<void> admit(
    String token, {
    required int patientId,
    required int wardId,
    required int bedId,
    required int doctorId,
    required String admissionDate,
    String? admissionReason,
  }) =>
      _post(token, '/nurse/admissions', {
        'patient_id': patientId,
        'ward_id': wardId,
        'bed_id': bedId,
        'doctor_id': doctorId,
        'admission_date': admissionDate,
        if (admissionReason != null) 'admission_reason': admissionReason,
      });

  Future<void> dischargeAdmission(String token, int admissionId, {required String dischargeDate, String? notes, required double totalCharges}) =>
      _put(token, '/nurse/admissions/$admissionId/discharge', {
        'discharge_date': dischargeDate,
        if (notes != null) 'discharge_notes': notes,
        'total_charges': totalCharges,
      });

  Future<void> transferAdmission(String token, int admissionId, {required int newWardId, required int newBedId, String? reason}) =>
      _put(token, '/nurse/admissions/$admissionId/transfer', {
        'new_ward_id': newWardId,
        'new_bed_id': newBedId,
        if (reason != null) 'transfer_reason': reason,
      });

  Future<AdmissionBalance> admissionBalance(String token, int admissionId) async {
    final json = await _get(token, '/nurse/admissions/$admissionId/balance');
    return AdmissionBalance.fromJson(json);
  }

  // ============================================================
  // eMAR
  // ============================================================

  Future<List<MedicationOrder>> emarList(String token, {int? patientId, bool admittedOnly = false}) async {
    final json = await _get(token, '/nurse/emar', {
      if (patientId != null) 'patient_id': '$patientId',
      if (admittedOnly) 'admitted_only': '1',
    });
    return (json['medications'] as List).map((m) => MedicationOrder.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<void> emarStore(
    String token, {
    required int patientId,
    required String drugName,
    required String dosage,
    String? route,
    String? frequency,
    String? scheduledTime,
    String? notes,
    bool isPrn = false,
    bool isControlled = false,
  }) =>
      _post(token, '/nurse/emar', {
        'patient_id': patientId,
        'drug_name': drugName,
        'dosage': dosage,
        if (route != null) 'route': route,
        if (frequency != null) 'frequency': frequency,
        if (scheduledTime != null) 'scheduled_time': scheduledTime,
        if (notes != null) 'notes': notes,
        'is_prn': isPrn,
        'is_controlled': isControlled,
      });

  Future<void> emarAdminister(String token, int marId, {required String status, String? notes}) =>
      _put(token, '/nurse/emar/$marId/administer', {'status': status, if (notes != null) 'notes': notes});

  Future<void> emarDestroy(String token, int marId) => _delete(token, '/nurse/emar/$marId');

  // ============================================================
  // Vitals
  // ============================================================

  Future<List<NurseVital>> vitalsList(String token, {int? patientId, bool admittedOnly = false}) async {
    final json = await _get(token, '/nurse/vitals', {
      if (patientId != null) 'patient_id': '$patientId',
      if (admittedOnly) 'admitted_only': '1',
    });
    return (json['vitals'] as List).map((v) => NurseVital.fromJson(v as Map<String, dynamic>)).toList();
  }

  Future<void> vitalsStore(
    String token, {
    required int patientId,
    String? bloodPressure,
    num? temperature,
    int? pulseRate,
    int? respiratoryRate,
    int? spo2,
    num? weight,
    num? height,
    String? notes,
  }) =>
      _post(token, '/nurse/vitals', {
        'patient_id': patientId,
        if (bloodPressure != null) 'blood_pressure': bloodPressure,
        if (temperature != null) 'temperature': temperature,
        if (pulseRate != null) 'pulse_rate': pulseRate,
        if (respiratoryRate != null) 'respiratory_rate': respiratoryRate,
        if (spo2 != null) 'spo2': spo2,
        if (weight != null) 'weight': weight,
        if (height != null) 'height': height,
        if (notes != null) 'notes': notes,
      });

  Future<List<NurseVital>> vitalsHistory(String token, int patientId) async {
    final json = await _get(token, '/nurse/vitals/patient/$patientId');
    return (json['vitals'] as List).map((v) => NurseVital.fromJson(v as Map<String, dynamic>)).toList();
  }

  Future<void> vitalsDestroy(String token, int vitalId) => _delete(token, '/nurse/vitals/$vitalId');

  // ============================================================
  // Nursing Notes
  // ============================================================

  Future<List<NursingNote>> nursingNotesList(String token, {int? patientId, bool admittedOnly = false}) async {
    final json = await _get(token, '/nurse/nursing-notes', {
      if (patientId != null) 'patient_id': '$patientId',
      if (admittedOnly) 'admitted_only': '1',
    });
    return (json['notes'] as List).map((n) => NursingNote.fromJson(n as Map<String, dynamic>)).toList();
  }

  Future<void> nursingNoteStore(
    String token, {
    required int patientId,
    required String noteType,
    String? shift,
    required String note,
    required String priority,
  }) =>
      _post(token, '/nurse/nursing-notes', {
        'patient_id': patientId,
        'note_type': noteType,
        if (shift != null) 'shift': shift,
        'note': note,
        'priority': priority,
      });

  Future<void> nursingNoteUpdate(String token, int noteId, {required String noteType, String? shift, required String note, required String priority}) =>
      _put(token, '/nurse/nursing-notes/$noteId', {'note_type': noteType, if (shift != null) 'shift': shift, 'note': note, 'priority': priority});

  Future<void> nursingNoteDestroy(String token, int noteId) => _delete(token, '/nurse/nursing-notes/$noteId');

  // ============================================================
  // Shift Handover
  // ============================================================

  Future<List<ShiftHandoverSummary>> handoversList(String token, {String? status, int? wardId}) async {
    final json = await _get(token, '/nurse/shift-handovers', {
      if (status != null) 'status': status,
      if (wardId != null) 'ward_id': '$wardId',
    });
    return (json['handovers'] as List).map((h) => ShiftHandoverSummary.fromJson(h as Map<String, dynamic>)).toList();
  }

  Future<List<HandoverPatientCard>> handoverWardPatients(String token, int wardId) async {
    final json = await _get(token, '/nurse/shift-handovers/ward-patients', {'ward_id': '$wardId'});
    return (json['patients'] as List).map((p) => HandoverPatientCard.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)> handoverCreateMeta(String token) async {
    final json = await _get(token, '/nurse/shift-handovers/create-meta');
    return (
      (json['wards'] as List).cast<Map<String, dynamic>>(),
      (json['nurses'] as List).cast<Map<String, dynamic>>(),
    );
  }

  Future<int> handoverStore(
    String token, {
    required int wardId,
    required String currentShift,
    required String nextShift,
    required int incomingNurseId,
    required String handoverDate,
    String? shiftSummary,
    required List<HandoverPatientCard> patients,
    List<Map<String, dynamic>> tasks = const [],
  }) async {
    final json = await _post(token, '/nurse/shift-handovers', {
      'ward_id': wardId,
      'current_shift': currentShift,
      'next_shift': nextShift,
      'incoming_nurse_id': incomingNurseId,
      'handover_date': handoverDate,
      if (shiftSummary != null) 'shift_summary': shiftSummary,
      'patients': patients.map((p) => p.toPayload()).toList(),
      'tasks': tasks,
    });
    return json['id'] as int;
  }

  Future<ShiftHandoverDetail> handoverDetail(String token, int id) async {
    final json = await _get(token, '/nurse/shift-handovers/$id');
    return ShiftHandoverDetail.fromJson(json);
  }

  Future<void> handoverSubmit(String token, int id) => _post(token, '/nurse/shift-handovers/$id/submit', {});
  Future<void> handoverAccept(String token, int id) => _post(token, '/nurse/shift-handovers/$id/accept', {});
  Future<void> handoverReject(String token, int id, String reason) => _post(token, '/nurse/shift-handovers/$id/reject', {'reason': reason});
  Future<void> handoverDestroy(String token, int id) => _delete(token, '/nurse/shift-handovers/$id');

  Future<int> handoverAlertCount(String token) async {
    final json = await _get(token, '/nurse/shift-handovers/alert-count');
    return json['count'] as int;
  }

  // ============================================================
  // Operation Theatre
  // ============================================================

  Future<List<OtSchedule>> otList(String token, {int? patientId}) async {
    final json = await _get(token, '/nurse/ot', {if (patientId != null) 'patient_id': '$patientId'});
    return (json['ot_schedules'] as List).map((o) => OtSchedule.fromJson(o as Map<String, dynamic>)).toList();
  }

  Future<void> otStore(
    String token, {
    required int patientId,
    int? surgeonId,
    int? anaesthetistId,
    int? scrubNurseId,
    String? theatreNo,
    required String procedureName,
    String? icd10Code,
    String? anaesthesiaType,
    required String priority,
    required String scheduledStart,
    String? scheduledEnd,
    String? preOpNotes,
  }) =>
      _post(token, '/nurse/ot', {
        'patient_id': patientId,
        if (surgeonId != null) 'surgeon_id': surgeonId,
        if (anaesthetistId != null) 'anaesthetist_id': anaesthetistId,
        if (scrubNurseId != null) 'scrub_nurse_id': scrubNurseId,
        if (theatreNo != null) 'theatre_no': theatreNo,
        'procedure_name': procedureName,
        if (icd10Code != null) 'icd10_code': icd10Code,
        if (anaesthesiaType != null) 'anaesthesia_type': anaesthesiaType,
        'priority': priority,
        'scheduled_start': scheduledStart,
        if (scheduledEnd != null) 'scheduled_end': scheduledEnd,
        if (preOpNotes != null) 'pre_op_notes': preOpNotes,
      });

  Future<OtSchedule> otDetail(String token, int id) async {
    final json = await _get(token, '/nurse/ot/$id');
    return OtSchedule.fromJson(json);
  }

  Future<void> otStart(String token, int id) => _put(token, '/nurse/ot/$id/start');

  Future<void> otComplete(String token, int id, {String? postOpNotes, String? complications}) => _put(token, '/nurse/ot/$id/complete', {
        if (postOpNotes != null) 'post_op_notes': postOpNotes,
        if (complications != null) 'complications': complications,
      });

  Future<void> otDestroy(String token, int id) => _delete(token, '/nurse/ot/$id');

  // ============================================================
  // ICU Charting
  // ============================================================

  Future<List<IcuChart>> icuList(String token, {int? patientId}) async {
    final json = await _get(token, '/nurse/icu', {if (patientId != null) 'patient_id': '$patientId'});
    return (json['icu_charts'] as List).map((c) => IcuChart.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<void> icuStore(String token, Map<String, dynamic> fields) => _post(token, '/nurse/icu', fields);

  Future<IcuChart> icuDetail(String token, int id) async {
    final json = await _get(token, '/nurse/icu/$id');
    return IcuChart.fromJson(json);
  }

  Future<void> icuDestroy(String token, int id) => _delete(token, '/nurse/icu/$id');

  // ============================================================
  // Blood Bank
  // ============================================================

  Future<(int, Map<String, int>, int, List<BloodUnit>)> bloodBankIndex(String token) async {
    final json = await _get(token, '/nurse/blood-bank');
    final byGroup = (json['by_group'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
    return (
      json['total_units'] as int,
      byGroup,
      json['near_expiry_count'] as int,
      (json['units'] as List).map((u) => BloodUnit.fromJson(u as Map<String, dynamic>)).toList(),
    );
  }

  Future<void> bloodBankStore(
    String token, {
    required String bloodGroup,
    required String component,
    String? donorName,
    required String collectionDate,
    required String expiryDate,
    String? notes,
  }) =>
      _post(token, '/nurse/blood-bank', {
        'blood_group': bloodGroup,
        'component': component,
        if (donorName != null) 'donor_name': donorName,
        'collection_date': collectionDate,
        'expiry_date': expiryDate,
        if (notes != null) 'notes': notes,
      });

  Future<List<BloodTransfusion>> bloodBankTransfusions(String token, {int? patientId}) async {
    final json = await _get(token, '/nurse/blood-bank/transfusions', {if (patientId != null) 'patient_id': '$patientId'});
    return (json['transfusions'] as List).map((t) => BloodTransfusion.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<void> bloodBankTransfuse(String token, int unitId, {required int patientId, String? indication}) =>
      _put(token, '/nurse/blood-bank/$unitId/transfuse', {'patient_id': patientId, if (indication != null) 'indication': indication});

  Future<void> bloodBankUpdateStatus(String token, int unitId, {required String status, int? reservedFor}) =>
      _put(token, '/nurse/blood-bank/$unitId/status', {'status': status, if (reservedFor != null) 'reserved_for': reservedFor});

  Future<void> bloodBankDestroy(String token, int unitId) => _delete(token, '/nurse/blood-bank/$unitId');

  // ============================================================
  // Consent Forms
  // ============================================================

  Future<List<ConsentForm>> consentFormsList(String token) async {
    final json = await _get(token, '/nurse/consent-forms');
    return (json['consent_forms'] as List).map((f) => ConsentForm.fromJson(f as Map<String, dynamic>)).toList();
  }

  Future<int> consentFormStore(
    String token, {
    required int patientId,
    required String consentType,
    String? procedureName,
    required String description,
    String? witnessName,
    String? doctorName,
    required String consentDate,
  }) async {
    final json = await _post(token, '/nurse/consent-forms', {
      'patient_id': patientId,
      'consent_type': consentType,
      if (procedureName != null) 'procedure_name': procedureName,
      'description': description,
      if (witnessName != null) 'witness_name': witnessName,
      if (doctorName != null) 'doctor_name': doctorName,
      'consent_date': consentDate,
    });
    return json['id'] as int;
  }

  Future<void> consentFormSign(String token, int id, {required String patientSignature, String? witnessSignature}) =>
      _post(token, '/nurse/consent-forms/$id/signature', {
        'patient_signature': patientSignature,
        if (witnessSignature != null) 'witness_signature': witnessSignature,
      });

  Future<void> consentFormUpdateStatus(String token, int id, String status) =>
      _put(token, '/nurse/consent-forms/$id/status', {'status': status});

  Future<void> consentFormDestroy(String token, int id) => _delete(token, '/nurse/consent-forms/$id');

  // ============================================================
  // Emergency / ER
  // ============================================================

  Future<(ErStats, List<ErRegistration>)> erList(String token) async {
    final json = await _get(token, '/nurse/er');
    return (
      ErStats.fromJson(json['stats'] as Map<String, dynamic>),
      (json['registrations'] as List).map((e) => ErRegistration.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<int> erStore(
    String token, {
    int? patientId,
    required String patientName,
    String? patientPhone,
    int? age,
    String? gender,
    required String triageLevel,
    required String chiefComplaint,
    String? presentingSymptoms,
    String? modeOfArrival,
  }) async {
    final json = await _post(token, '/nurse/er', {
      if (patientId != null) 'patient_id': patientId,
      'patient_name': patientName,
      if (patientPhone != null) 'patient_phone': patientPhone,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      'triage_level': triageLevel,
      'chief_complaint': chiefComplaint,
      if (presentingSymptoms != null) 'presenting_symptoms': presentingSymptoms,
      if (modeOfArrival != null) 'mode_of_arrival': modeOfArrival,
    });
    return json['id'] as int;
  }

  Future<ErRegistration> erDetail(String token, int id) async {
    final json = await _get(token, '/nurse/er/$id');
    return ErRegistration.fromJson(json);
  }

  Future<void> erUpdate(String token, int id, {int? attendingDoctorId, required String status, String? notes, String? icd10Code}) =>
      _put(token, '/nurse/er/$id', {
        if (attendingDoctorId != null) 'attending_doctor_id': attendingDoctorId,
        'status': status,
        if (notes != null) 'notes': notes,
        if (icd10Code != null) 'icd10_code': icd10Code,
      });

  Future<void> erTriage(String token, int id, String triageLevel) => _put(token, '/nurse/er/$id/triage', {'triage_level': triageLevel});

  Future<void> erDischarge(String token, int id, {required String status, String? notes}) =>
      _put(token, '/nurse/er/$id/discharge', {'status': status, if (notes != null) 'notes': notes});

  Future<void> erDestroy(String token, int id) => _delete(token, '/nurse/er/$id');

  // ============================================================
  // Food Intake
  // ============================================================

  Future<List<FoodIntakePatient>> foodIntakeList(String token) async {
    final json = await _get(token, '/nurse/food-intake');
    return (json['patients'] as List).map((p) => FoodIntakePatient.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<(DietPlan?, List<FoodLog>)> foodIntakeDetail(String token, int patientId) async {
    final json = await _get(token, '/nurse/food-intake/$patientId');
    return (
      json['diet_plan'] != null ? DietPlan.fromJson(json['diet_plan'] as Map<String, dynamic>) : null,
      (json['food_logs'] as List).map((l) => FoodLog.fromJson(l as Map<String, dynamic>)).toList(),
    );
  }

  Future<void> foodIntakeStoreDietPlan(String token, int patientId, {required String dietType, String? restrictions, String? notes}) =>
      _post(token, '/nurse/food-intake/$patientId/diet-plan', {
        'diet_type': dietType,
        if (restrictions != null) 'restrictions': restrictions,
        if (notes != null) 'notes': notes,
      });

  Future<void> foodIntakeLogMeal(String token, int patientId, {required String mealType, required String status, String? quantity, String? notes}) =>
      _post(token, '/nurse/food-intake/$patientId/log-meal', {
        'meal_type': mealType,
        'status': status,
        if (quantity != null) 'quantity': quantity,
        if (notes != null) 'notes': notes,
      });

  // ============================================================
  // Fluid Intake
  // ============================================================

  Future<List<FluidIntakePatient>> fluidIntakeList(String token) async {
    final json = await _get(token, '/nurse/fluid-intake');
    return (json['patients'] as List).map((p) => FluidIntakePatient.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<(List<FluidLog>, num, num)> fluidIntakeDetail(String token, int patientId) async {
    final json = await _get(token, '/nurse/fluid-intake/$patientId');
    return (
      (json['fluid_logs'] as List).map((l) => FluidLog.fromJson(l as Map<String, dynamic>)).toList(),
      json['today_intake'] as num,
      json['today_output'] as num,
    );
  }

  Future<void> fluidIntakeLog(
    String token,
    int patientId, {
    required String flowType,
    required String category,
    required int amountMl,
    required String logTime,
    String? notes,
  }) =>
      _post(token, '/nurse/fluid-intake/$patientId/log', {
        'flow_type': flowType,
        'category': category,
        'amount_ml': amountMl,
        'log_time': logTime,
        if (notes != null) 'notes': notes,
      });

  Future<void> fluidIntakeDestroy(String token, int fluidLogId) => _delete(token, '/nurse/fluid-logs/$fluidLogId');

  // ============================================================
  // Rounds
  // ============================================================

  Future<List<RoundAssignment>> myRounds(String token) async {
    final json = await _get(token, '/nurse/my-rounds');
    return (json['assignments'] as List).map((a) => RoundAssignment.fromJson(a as Map<String, dynamic>)).toList();
  }

  Future<void> markRound(
    String token,
    int patientId, {
    required int assignmentId,
    String? bloodPressure,
    String? temperature,
    String? pulseRate,
    String? spo2,
    String? notes,
  }) =>
      _post(token, '/nurse/rounds/$patientId/mark', {
        'assignment_id': assignmentId,
        if (bloodPressure != null) 'blood_pressure': bloodPressure,
        if (temperature != null) 'temperature': temperature,
        if (pulseRate != null) 'pulse_rate': pulseRate,
        if (spo2 != null) 'spo2': spo2,
        if (notes != null) 'notes': notes,
      });

  Future<List<StaffRound>> roundHistory(String token, int patientId) async {
    final json = await _get(token, '/nurse/rounds/$patientId/history');
    return (json['rounds'] as List).map((r) => StaffRound.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<int> roundsAlertCount(String token) async {
    final json = await _get(token, '/nurse/rounds/alert-count');
    return json['count'] as int;
  }

  Future<List<Map<String, dynamic>>> staffRoundsAssignments(String token) async {
    final json = await _get(token, '/nurse/staff-rounds/assignments');
    return (json['assignments'] as List).cast<Map<String, dynamic>>();
  }

  // ============================================================
  // Profile
  // ============================================================

  Future<NurseProfile> profile(String token) async {
    final json = await _get(token, '/nurse/profile');
    return NurseProfile.fromJson(json);
  }

  Future<NurseProfile> updateProfile(
    String token, {
    required String name,
    required String email,
    String? phone,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
    Uint8List? photoBytes,
    String? photoFilename,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/nurse/profile'))
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = name
      ..fields['email'] = email;

    if (phone != null && phone.isNotEmpty) request.fields['phone'] = phone;
    if (password != null && password.isNotEmpty) {
      request.fields['password'] = password;
      request.fields['password_confirmation'] = passwordConfirmation ?? '';
      request.fields['current_password'] = currentPassword ?? '';
    }
    if (photoBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('profile_photo', photoBytes, filename: photoFilename ?? 'profile_photo.jpg'));
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    return NurseProfile.fromJson(_decode(response) as Map<String, dynamic>);
  }
}

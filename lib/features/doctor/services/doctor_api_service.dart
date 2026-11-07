import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, ApiService, sessionExpired, serverFailure;
import 'package:hms_mobile/features/doctor/models/doctor_models.dart';

/// JSON client for the Flutter doctor app — mirrors
/// app/Http/Controllers/Api/DoctorController.php.
class DoctorApiService {
  static String get baseUrl => ApiService.baseUrl;

  final http.Client _client;
  DoctorApiService({http.Client? client}) : _client = client ?? http.Client();

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

    if (response.statusCode == 200 || response.statusCode == 201) return body;

    if (response.statusCode == 422) {
      final errors = (body as Map<String, dynamic>?)?['errors'] as Map<String, dynamic>?;
      final firstError = errors?.values.first;
      throw ApiException(firstError is List && firstError.isNotEmpty
          ? firstError.first.toString()
          : (body?['message']?.toString() ?? 'Invalid request.'));
    }
    if (response.statusCode == 401) {
      throw sessionExpired();
    }
    if (response.statusCode == 403) {
      throw ApiException((body is Map ? body['message']?.toString() : null) ?? 'You are not allowed to do that.');
    }
    throw serverFailure(response.statusCode, body is Map ? body['message']?.toString() : null);
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

  /// Dashboard stats plus today's list and recent patients in one call.
  Future<({DoctorDashboardStats stats, List<DoctorAppointment> today, List<DoctorPatient> recentPatients})> dashboard(String token) async {
    final json = await _get(token, '/doctor/dashboard');
    return (
      stats: DoctorDashboardStats.fromJson(json['stats'] as Map<String, dynamic>),
      today: (json['today_appointments'] as List? ?? [])
          .map((a) => DoctorAppointment.fromJson(a as Map<String, dynamic>))
          .toList(),
      recentPatients: (json['recent_patients'] as List? ?? [])
          .map((p) => DoctorPatient.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<DoctorAppointment>> appointments(String token, {String? status, bool todayOnly = false}) async {
    final json = await _get(token, '/doctor/appointments', {
      if (status != null) 'status': status,
      if (todayOnly) 'today': '1',
    });
    return (json['appointments'] as List)
        .map((a) => DoctorAppointment.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<DoctorAppointmentDetail> appointmentDetail(String token, int id) async {
    return DoctorAppointmentDetail.fromJson(await _get(token, '/doctor/appointments/$id'));
  }

  /// Saves the consultation; the backend also marks the visit completed.
  Future<DoctorConsultation> saveConsultation(
    String token,
    int appointmentId, {
    required String chiefComplaint,
    String? diagnosis,
    String? icd10Code,
    String? treatmentPlan,
    String? notes,
    String? bloodPressure,
    String? temperature,
    String? pulseRate,
    String? weight,
    String? height,
    String? spo2,
  }) async {
    final json = await _post(token, '/doctor/appointments/$appointmentId/consultation', {
      'chief_complaint': chiefComplaint,
      if ((diagnosis ?? '').isNotEmpty) 'diagnosis': diagnosis,
      if ((icd10Code ?? '').isNotEmpty) 'icd10_code': icd10Code,
      if ((treatmentPlan ?? '').isNotEmpty) 'treatment_plan': treatmentPlan,
      if ((notes ?? '').isNotEmpty) 'notes': notes,
      if ((bloodPressure ?? '').isNotEmpty) 'blood_pressure': bloodPressure,
      if ((temperature ?? '').isNotEmpty) 'temperature': temperature,
      if ((pulseRate ?? '').isNotEmpty) 'pulse_rate': pulseRate,
      if ((weight ?? '').isNotEmpty) 'weight': weight,
      if ((height ?? '').isNotEmpty) 'height': height,
      if ((spo2 ?? '').isNotEmpty) 'spo2': spo2,
    });
    return DoctorConsultation.fromJson(json['consultation'] as Map<String, dynamic>);
  }

  Future<DoctorConsultation> consultation(String token, int id) async {
    final json = await _get(token, '/doctor/consultations/$id');
    return DoctorConsultation.fromJson(json['consultation'] as Map<String, dynamic>);
  }

  Future<DoctorConsultation> savePrescription(
    String token,
    int consultationId, {
    required List<PrescribedMedicine> medicines,
    String? notes,
  }) async {
    final json = await _post(token, '/doctor/consultations/$consultationId/prescription', {
      'medicines': medicines.map((m) => m.toJson()).toList(),
      if ((notes ?? '').isNotEmpty) 'notes': notes,
    });
    return DoctorConsultation.fromJson(json['consultation'] as Map<String, dynamic>);
  }

  Future<List<DoctorPatient>> patients(String token, {String? search}) async {
    final json = await _get(token, '/doctor/patients', {
      if ((search ?? '').isNotEmpty) 'search': search!,
    });
    return (json['patients'] as List).map((p) => DoctorPatient.fromJson(p as Map<String, dynamic>)).toList();
  }

  /// Every prescription this doctor has written, newest first. The
  /// endpoint existed from the start; nothing in the app called it.
  Future<List<DoctorPrescriptionSummary>> prescriptions(String token, {int? patientId}) async {
    final json = await _get(token, '/doctor/prescriptions', {
      if (patientId != null) 'patient_id': '$patientId',
    });
    return (json['prescriptions'] as List? ?? [])
        .map((p) => DoctorPrescriptionSummary.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<DoctorPatientDetail> patientDetail(String token, int id) async {
    return DoctorPatientDetail.fromJson(await _get(token, '/doctor/patients/$id'));
  }

  Future<List<Icd10Suggestion>> searchIcd10(String token, String term) async {
    final json = await _get(token, '/doctor/icd10', {'q': term});
    return (json['codes'] as List).map((c) => Icd10Suggestion.fromJson(c as Map<String, dynamic>)).toList();
  }

  // ------------------------------------------------------- my schedule

  Future<({int days, int sessions, List<DoctorScheduleEntry> entries})> schedule(String token) async {
    final json = await _get(token, '/doctor/schedule');
    final summary = (json['summary'] as Map?) ?? const {};
    return (
      days: (summary['days'] as int?) ?? 0,
      sessions: (summary['sessions'] as int?) ?? 0,
      entries: (json['schedule'] as List? ?? [])
          .map((e) => DoctorScheduleEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> scheduleStore(String token, Map<String, dynamic> body) async {
    await _post(token, '/doctor/schedule', body);
  }

  Future<void> scheduleUpdate(String token, int id, Map<String, dynamic> body) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/doctor/schedule/$id'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    _decode(response);
  }

  Future<void> scheduleDestroy(String token, int id) async {
    _decode(await _client.delete(Uri.parse('$baseUrl/doctor/schedule/$id'), headers: _headers(token)));
  }

  Future<DoctorProfile> profile(String token) async {
    return DoctorProfile.fromJson(await _get(token, '/doctor/profile'));
  }

  Future<void> updateProfile(
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
    // A picture cannot go as JSON, so a save that carries one is sent as
    // multipart -- the same shape every other role's profile uses.
    if (photoBytes != null) {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/doctor/profile'))
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['name'] = name
        ..fields['email'] = email;

      if ((phone ?? '').isNotEmpty) request.fields['phone'] = phone!;
      if ((password ?? '').isNotEmpty) {
        request.fields['current_password'] = currentPassword ?? '';
        request.fields['password'] = password!;
        request.fields['password_confirmation'] = passwordConfirmation ?? '';
      }
      request.files.add(http.MultipartFile.fromBytes('profile_photo', photoBytes,
          filename: photoFilename ?? 'profile_photo.jpg'));

      final streamed = await _client.send(request);
      _decode(await http.Response.fromStream(streamed));
      return;
    }

    await _post(token, '/doctor/profile', {
      'name': name,
      'email': email,
      if ((phone ?? '').isNotEmpty) 'phone': phone,
      if ((password ?? '').isNotEmpty) ...{
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    });
  }
}

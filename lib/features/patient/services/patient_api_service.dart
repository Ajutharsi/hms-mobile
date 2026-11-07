import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, ApiService, sessionExpired, serverFailure;
import 'package:hms_mobile/features/patient/models/appointment.dart';
import 'package:hms_mobile/features/patient/models/health_record.dart';
import 'package:hms_mobile/features/patient/models/invoice.dart';
import 'package:hms_mobile/features/patient/models/lab_order.dart';
import 'package:hms_mobile/features/patient/models/patient_profile.dart';
import 'package:hms_mobile/features/patient/models/prescription.dart';

/// The patient's own records: their visits, prescriptions, results, bills
/// and profile.
///
/// These used to live on the base client in core/services, which meant
/// the class every other role's client is built on also carried one
/// feature's entire API. The patient's endpoints belong with the patient,
/// the way every other role's already do.
///
/// Staying in core: the base client itself, and the doctor list and slot
/// picker. Those read as patient endpoints only because the patient app
/// asked for them first -- a nurse admitting someone, a lab assistant
/// raising an order and the OT and ER screens all pick a doctor from the
/// same list, which is why the route sits outside the patient group too.
class PatientApiService {
  static String get baseUrl => ApiService.baseUrl;

  final http.Client _client;
  PatientApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers({String? token}) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<List<Appointment>> getAppointments(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/patient/appointments'),
      headers: _headers(token: token),
    );
    final body = _decode(response);
    return (body['appointments'] as List).map((json) => Appointment.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Prescription>> getPrescriptions(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/patient/prescriptions'),
      headers: _headers(token: token),
    );
    final body = _decode(response);
    return (body['prescriptions'] as List).map((json) => Prescription.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<LabOrder>> getLabResults(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/patient/lab-results'),
      headers: _headers(token: token),
    );
    final body = _decode(response);
    return (body['lab_orders'] as List).map((json) => LabOrder.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Invoice>> getInvoices(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/patient/invoices'),
      headers: _headers(token: token),
    );
    final body = _decode(response);
    return (body['invoices'] as List).map((json) => Invoice.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Logs a help request for the billing team — this does not process any
  /// payment (the app has no payment gateway integrated).
  Future<void> requestInvoiceHelp(String token, int invoiceId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/patient/invoices/$invoiceId/request-help'),
      headers: _headers(token: token),
    );
    _decode(response);
  }

  /// [date] must be `yyyy-MM-dd`, [time] must be `HH:mm`. Returns the
  /// newly-booked appointment's token number, if one was assigned.
  Future<int?> bookAppointment(
    String token, {
    required int doctorId,
    required String date,
    required String time,
    required String type,
    String? notes,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/patient/appointments'),
      headers: _headers(token: token),
      body: jsonEncode({
        'doctor_id': doctorId,
        'appointment_date': date,
        'appointment_time': time,
        'type': type,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    );
    final body = _decode(response);
    return (body['appointment'] as Map<String, dynamic>?)?['token_number'] as int?;
  }

  Future<void> cancelAppointment(String token, int appointmentId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/patient/appointments/$appointmentId/cancel'),
      headers: _headers(token: token),
    );
    _decode(response);
  }

  /// Move a booking instead of cancelling and booking again, which
  /// loses the queue token and leaves two rows in the history.
  Future<void> rescheduleAppointment(
    String token,
    int appointmentId, {
    required String date,
    required String time,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/patient/appointments/$appointmentId/reschedule'),
      headers: _headers(token: token),
      body: jsonEncode({'appointment_date': date, 'appointment_time': time}),
    );
    _decode(response);
  }

  /// The clinical side of the patient's record, which the app could
  /// not show before: consultations, stays, allergies and vitals.
  Future<HealthRecord> getHealthRecords(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/patient/health-records'),
      headers: _headers(token: token),
    );
    return HealthRecord.fromJson(_decode(response));
  }

  Future<PatientProfile> getProfile(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/patient/profile'),
      headers: _headers(token: token),
    );
    return PatientProfile.fromJson(_decode(response));
  }

  /// [photoBytes]/[photoFilename] come from an [XFile] read with
  /// `readAsBytes()` rather than a `dart:io` `File`/path, so this keeps
  /// working on Flutter web too (see the note on [guardNetworkErrors]).
  /// Always a multipart POST (never PUT) — PHP can't parse a multipart
  /// body off a PUT request.
  Future<PatientProfile> updateProfile(
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
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/patient/profile'))
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
      request.files.add(http.MultipartFile.fromBytes(
        'profile_photo',
        photoBytes,
        filename: photoFilename ?? 'profile_photo.jpg',
      ));
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    return PatientProfile.fromJson(_decode(response));
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection and try again.');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body as Map<String, dynamic>;
    }

    if (response.statusCode == 422) {
      final errors = (body as Map<String, dynamic>?)?['errors'] as Map<String, dynamic>?;
      final firstError = errors?.values.first;
      throw ApiException(firstError is List && firstError.isNotEmpty
          ? firstError.first.toString()
          : (body?['message']?.toString() ?? 'Invalid request.'));
    }

    if (response.statusCode == 401) throw sessionExpired();

    throw serverFailure(response.statusCode, body is Map ? body['message']?.toString() : null);
  }
}

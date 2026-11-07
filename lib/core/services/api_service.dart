import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/features/patient/models/appointment.dart';
import 'package:hms_mobile/features/auth/models/auth_result.dart';
import 'package:hms_mobile/features/patient/models/doctor.dart';
import 'package:hms_mobile/features/patient/models/invoice.dart';
import 'package:hms_mobile/features/patient/models/lab_order.dart';
import 'package:hms_mobile/features/patient/models/health_record.dart';
import 'package:hms_mobile/features/patient/models/patient_profile.dart';
import 'package:hms_mobile/features/patient/models/prescription.dart';
import 'package:hms_mobile/features/patient/models/time_slot.dart';


class ApiException implements Exception {
  final String message;

  /// True when the server rejected the token itself. Until tokens had a
  /// lifetime this only happened if someone revoked one by hand; now that
  /// they expire after a week, any screen can meet it mid-session.
  final bool isUnauthenticated;

  /// True when the request never reached the server: no connection, DNS
  /// failure, timeout. Worth telling apart from a server that answered
  /// with an error, because the two need different things from the
  /// person reading the screen.
  final bool isNetwork;

  /// True when the server is deliberately down (503). The hospital put it
  /// there; trying again in a second will not help.
  final bool isMaintenance;

  ApiException(this.message, {this.isUnauthenticated = false, this.isNetwork = false, this.isMaintenance = false});

  @override
  String toString() => message;
}

/// Called once when the server says the token is no longer good.
///
/// The app sets this at start-up to clear the stored token and return to
/// the login screen. Without it a session that expires while someone is
/// working leaves them on a screen showing "Your session has expired"
/// with no way back except force-quitting.
void Function()? onSessionExpired;

/// Builds the 401 exception and lets the app know, once.
ApiException sessionExpired() {
  onSessionExpired?.call();
  return ApiException('Your session has expired. Please log in again.', isUnauthenticated: true);
}


class ApiService {
  /// Where the Laravel app is reachable from this device. Set at build
  /// time so a release build can't ship a developer's host:
  ///
  ///   flutter build apk --dart-define=API_URL=https://hms.example.com/api
  ///
  /// Without the flag it falls back to the local dev server, which suits:
  ///  - Chrome / desktop (this machine)             -> http://127.0.0.1:8000
  ///  - Android emulator or a USB phone, after
  ///    `adb reverse tcp:8000 tcp:8000`             -> http://127.0.0.1:8000
  ///  - Android emulator reaching the host directly -> http://10.0.2.2:8000
  ///  - a phone on the same Wi-Fi                   -> http://<pc-lan-ip>:8000
  ///
  /// Anything other than https:// is plain text on the wire — fine between
  /// an emulator and this PC, not fine for real patient data.
  static const String _devFallback = 'http://127.0.0.1:8000/api';

  static String get baseUrl =>
      const String.fromEnvironment('API_URL', defaultValue: _devFallback);

  /// True when traffic leaves the device unencrypted; the login screen
  /// says so rather than letting it pass unnoticed in a release build.
  static bool get isInsecure => !baseUrl.startsWith('https://');

  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers({String? token}) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// Logs in with email + password. `deviceName` just labels the token
  /// server-side (visible in the user's active-sessions list later) so
  /// something like "flutter-android" is enough.
  Future<AuthResult> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'device_name': deviceName,
      }),
    );

    return AuthResult.fromJson(_decode(response));
  }

  /// Registers a new patient — creates both the login account and the
  /// clinical patient profile, and returns a token like [login] does.
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String deviceName,
    // Required, not optional: the backend's `patients.gender` column has
    // no default and rejects a null insert outright.
    required String gender,
    String? phone,
    String? dob,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/register'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': deviceName,
        'gender': gender,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (dob != null && dob.isNotEmpty) 'dob': dob,
      }),
    );

    return AuthResult.fromJson(_decode(response));
  }

  /// Sends a password-reset email. The link inside it opens the existing
  /// Laravel web page for setting a new password — the app doesn't need to
  /// handle the reset itself, just trigger the email.
  Future<void> forgotPassword({required String email}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: _headers(),
      body: jsonEncode({'email': email}),
    );
    _decode(response);
  }

  Future<AppUser> me(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/me'),
      headers: _headers(token: token),
    );
    return AppUser.fromJson(_decode(response));
  }

  Future<List<Appointment>> getAppointments(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/patient/appointments'),
      headers: _headers(token: token),
    );
    final body = _decode(response);
    return (body['appointments'] as List)
        .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Prescription>> getPrescriptions(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/patient/prescriptions'),
      headers: _headers(token: token),
    );
    final body = _decode(response);
    return (body['prescriptions'] as List)
        .map((json) => Prescription.fromJson(json as Map<String, dynamic>))
        .toList();
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

  Future<List<Doctor>> getDoctors(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/patient/doctors'),
      headers: _headers(token: token),
    );
    final body = _decode(response);
    return (body['doctors'] as List).map((json) => Doctor.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Alias for [getDoctors] — this endpoint has no role restriction beyond
  /// Sanctum auth, so the nurse app's doctor pickers (OT surgeon/anaesthetist,
  /// ER attending doctor, admissions) reuse it under this shorter name.
  Future<List<Doctor>> doctors(String token) => getDoctors(token);

  /// [date] must be `yyyy-MM-dd`.
  Future<List<TimeSlot>> getSlots(String token, {required int doctorId, required String date}) async {
    final uri = Uri.parse('$baseUrl/patient/slots').replace(queryParameters: {
      'doctor_id': doctorId.toString(),
      'date': date,
    });
    final response = await _client.get(uri, headers: _headers(token: token));
    final body = _decode(response);
    return (body['slots'] as List).map((json) => TimeSlot.fromJson(json as Map<String, dynamic>)).toList();
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

  Future<void> logout(String token) async {
    await _client.post(
      Uri.parse('$baseUrl/logout'),
      headers: _headers(token: token),
    );
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection and try again.');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body;
    }

    if (response.statusCode == 422) {
      // Laravel validation error shape: { "errors": { "field": ["message"] } }
      final errors = body['errors'] as Map<String, dynamic>?;
      final firstError = errors?.values.first;
      final message = firstError is List && firstError.isNotEmpty
          ? firstError.first.toString()
          : (body['message']?.toString() ?? 'Invalid request.');
      throw ApiException(message);
    }

    if (response.statusCode == 401) {
      throw sessionExpired();
    }

    throw serverFailure(response.statusCode, body['message']?.toString());
  }
}

/// The message to show when the server answers with an error.
///
/// Laravel's own text is right for things the person did -- "This email
/// is already registered" -- but not for the HTTP layer. A 404 reads
/// "The route api/foo could not be found" and a 405 names the methods a
/// route supports: that is a note to a developer, shown to a nurse. For
/// those we say what it means for them instead, and keep the raw text
/// out of the way.
String serverErrorMessage(int status, String? serverMessage) {
  switch (status) {
    case 404:
      return 'This feature is not available on the server yet. Please let your administrator know.';
    case 405:
      return "The server did not accept that request. The app may be out of date -- please update it.";
    case 403:
      return serverMessage ?? 'You do not have permission to do that.';
    case 429:
      return serverMessage ?? 'Too many attempts. Please wait a minute and try again.';
    case 500:
    case 502:
    case 504:
      return 'The server ran into a problem. Please try again in a moment.';
    default:
      return serverMessage ?? 'Something went wrong ($status).';
  }
}

/// The exception to throw when the server answers with an error.
///
/// Carries the flags as well as the wording, because a screen reacts to
/// maintenance differently from an ordinary failure -- and only the
/// patient's client used to notice 503 at all, so a hospital in
/// maintenance showed every other role a generic "something went wrong".
ApiException serverFailure(int status, String? serverMessage) {
  if (status == 503) {
    return ApiException(serverMessage ?? 'The system is under maintenance.', isMaintenance: true);
  }
  if (status == 401) return sessionExpired();
  return ApiException(serverErrorMessage(status, serverMessage));
}

/// Wraps a request's network-level failures (server unreachable, DNS
/// failure, CORS block on web, etc) with the same friendly [ApiException]
/// the rest of the app expects. Deliberately platform-agnostic (no
/// dart:io SocketException) so this works on web too.
Future<T> guardNetworkErrors<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on ApiException {
    rethrow;
  } on SocketException {
    throw ApiException('Could not reach the server. Is the backend running and reachable?', isNetwork: true);
  } on http.ClientException {
    throw ApiException('Could not reach the server. Is the backend running and reachable?', isNetwork: true);
  } on TimeoutException {
    throw ApiException('The server took too long to respond. Please try again.', isNetwork: true);
  } catch (error) {
    // Anything else is ours — a bad cast or a payload we didn't expect.
    // Saying "could not reach the server" for those sent us hunting the
    // network while the real fault was in here.
    throw ApiException("Something went wrong reading the server's response. ($error)");
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, ApiService;
import 'package:hms_mobile/features/pharmacy/models/dispensing.dart';
import 'package:hms_mobile/features/pharmacy/models/drug.dart';
import 'package:hms_mobile/features/pharmacy/models/pharmacy_dashboard_stats.dart';
import 'package:hms_mobile/features/pharmacy/models/pharmacy_patient.dart';
import 'package:hms_mobile/features/pharmacy/models/pharmacy_profile.dart';

/// JSON client for the pharmacist mobile app, and the Drug Master /
/// Dispensing pieces the receptionist app also uses — mirrors
/// app/Http/Controllers/Api/PharmacyController.php.
class PharmacyApiService {
  static String get baseUrl => ApiService.baseUrl;

  final http.Client _client;
  PharmacyApiService({http.Client? client}) : _client = client ?? http.Client();

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

  Future<Map<String, dynamic>> _put(String token, String path, Map<String, dynamic> body) async {
    final response = await _client.put(Uri.parse('$baseUrl$path'), headers: _headers(token), body: jsonEncode(body));
    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _delete(String token, String path) async {
    final response = await _client.delete(Uri.parse('$baseUrl$path'), headers: _headers(token));
    return _decode(response) as Map<String, dynamic>;
  }

  Future<PharmacyDashboardStats> dashboard(String token) async {
    final json = await _get(token, '/pharmacy/dashboard');
    return PharmacyDashboardStats.fromJson(json['stats'] as Map<String, dynamic>);
  }

  // Drug Master

  Future<List<Drug>> drugs(String token, {String? q}) async {
    final json = await _get(token, '/pharmacy/drugs', {if (q != null && q.isNotEmpty) 'q': q});
    return (json['drugs'] as List).map((d) => Drug.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<void> drugStore(String token, Map<String, dynamic> fields) => _post(token, '/pharmacy/drugs', fields);

  Future<void> drugUpdate(String token, int id, Map<String, dynamic> fields) => _put(token, '/pharmacy/drugs/$id', fields);

  Future<void> drugDestroy(String token, int id) => _delete(token, '/pharmacy/drugs/$id');

  Future<void> drugAddStock(String token, int id, {required int quantity, required String reason, String? notes}) =>
      _post(token, '/pharmacy/drugs/$id/stock', {'quantity': quantity, 'reason': reason, if (notes != null) 'notes': notes});

  Future<List<DrugStockEntry>> drugStockHistory(String token, int id) async {
    final json = await _get(token, '/pharmacy/drugs/$id/stock-history');
    return (json['history'] as List).map((h) => DrugStockEntry.fromJson(h as Map<String, dynamic>)).toList();
  }

  // Dispensing

  Future<List<Dispensing>> dispensingList(String token) async {
    final json = await _get(token, '/pharmacy/dispensing');
    return (json['dispensings'] as List).map((d) => Dispensing.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<DispensingDetail> dispensingDetail(String token, int id) async {
    final json = await _get(token, '/pharmacy/dispensing/$id');
    return DispensingDetail.fromJson(json);
  }

  Future<Map<String, dynamic>> dispensingFromPrescription(String token, int prescriptionId) =>
      _get(token, '/pharmacy/dispensing/from-prescription/$prescriptionId');

  Future<DispensingAlerts> dispensingAlerts(String token) async {
    final json = await _get(token, '/pharmacy/dispensing/alerts');
    return DispensingAlerts(
      lowStock: (json['low_stock'] as List).map((d) => Drug.fromJson(d as Map<String, dynamic>)).toList(),
      nearExpiry: (json['near_expiry'] as List).map((d) => Drug.fromJson(d as Map<String, dynamic>)).toList(),
      expired: (json['expired'] as List).map((d) => Drug.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }

  Future<int> dispensingStore(String token, {required int patientId, int? prescriptionId, String? notes, required List<Map<String, dynamic>> items}) async {
    final json = await _post(token, '/pharmacy/dispensing', {
      'patient_id': patientId,
      if (prescriptionId != null) 'prescription_id': prescriptionId,
      if (notes != null) 'notes': notes,
      'items': items,
    });
    return json['id'] as int;
  }

  // Patients (picker)

  Future<List<PharmacyPatient>> patients(String token, {String? q}) async {
    final json = await _get(token, '/pharmacy/patients', {if (q != null && q.isNotEmpty) 'q': q});
    return (json['patients'] as List).map((p) => PharmacyPatient.fromJson(p as Map<String, dynamic>)).toList();
  }

  // Profile

  Future<PharmacyProfile> profile(String token) async {
    final json = await _get(token, '/pharmacy/profile');
    return PharmacyProfile.fromJson(json);
  }

  Future<PharmacyProfile> updateProfile(
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
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/pharmacy/profile'))
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
    return PharmacyProfile.fromJson(_decode(response) as Map<String, dynamic>);
  }
}

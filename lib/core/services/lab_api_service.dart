import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, ApiService;
import 'package:hms_mobile/features/lab/models/lab_dashboard_stats.dart';
import 'package:hms_mobile/features/lab/models/lab_order.dart';
import 'package:hms_mobile/features/lab/models/lab_profile.dart';
import 'package:hms_mobile/features/lab/models/lab_test.dart';

/// JSON client for the Flutter lab-assistant app — mirrors
/// app/Http/Controllers/Api/LabAssistantController.php.
class LabApiService {
  static String get baseUrl => ApiService.baseUrl;

  final http.Client _client;
  LabApiService({http.Client? client}) : _client = client ?? http.Client();

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

  Future<LabDashboardStats> dashboard(String token) async {
    final json = await _get(token, '/lab/dashboard');
    return LabDashboardStats.fromJson(json['stats'] as Map<String, dynamic>);
  }

  // Lab Tests

  Future<List<LabTest>> labTests(String token) async {
    final json = await _get(token, '/lab/tests');
    return (json['lab_tests'] as List).map((t) => LabTest.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<void> labTestStore(
    String token, {
    required String testName,
    required String category,
    required String sampleType,
    required double price,
    String? unit,
    String? normalRangeMale,
    String? normalRangeFemale,
    String? description,
    String status = 'active',
  }) =>
      _post(token, '/lab/tests', {
        'test_name': testName,
        'category': category,
        'sample_type': sampleType,
        'price': price,
        if (unit != null) 'unit': unit,
        if (normalRangeMale != null) 'normal_range_male': normalRangeMale,
        if (normalRangeFemale != null) 'normal_range_female': normalRangeFemale,
        if (description != null) 'description': description,
        'status': status,
      });

  Future<void> labTestUpdate(
    String token,
    int id, {
    required String testName,
    required String category,
    required String sampleType,
    required double price,
    String? unit,
    String? normalRangeMale,
    String? normalRangeFemale,
    String? description,
    String status = 'active',
  }) =>
      _put(token, '/lab/tests/$id', {
        'test_name': testName,
        'category': category,
        'sample_type': sampleType,
        'price': price,
        if (unit != null) 'unit': unit,
        if (normalRangeMale != null) 'normal_range_male': normalRangeMale,
        if (normalRangeFemale != null) 'normal_range_female': normalRangeFemale,
        if (description != null) 'description': description,
        'status': status,
      });

  Future<void> labTestDestroy(String token, int id) => _delete(token, '/lab/tests/$id');

  // Lab Orders

  Future<List<LabOrder>> labOrders(String token, {String? status}) async {
    final json = await _get(token, '/lab/orders', {if (status != null) 'status': status});
    return (json['lab_orders'] as List).map((o) => LabOrder.fromJson(o as Map<String, dynamic>)).toList();
  }

  Future<int> labOrderStore(
    String token, {
    required int patientId,
    required int doctorId,
    int? appointmentId,
    required List<int> tests,
    String? notes,
  }) async {
    final json = await _post(token, '/lab/orders', {
      'patient_id': patientId,
      'doctor_id': doctorId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      'tests': tests,
      if (notes != null) 'notes': notes,
    });
    return json['id'] as int;
  }

  Future<LabOrderDetail> labOrderDetail(String token, int id) async {
    final json = await _get(token, '/lab/orders/$id');
    return LabOrderDetail.fromJson(json);
  }

  Future<void> labOrderEnterResults(String token, int orderId, List<Map<String, dynamic>> results) =>
      _post(token, '/lab/orders/$orderId/results', {'results': results});

  // Patients

  Future<List<LabPatient>> patients(String token, {String? q}) async {
    final json = await _get(token, '/lab/patients', {if (q != null && q.isNotEmpty) 'q': q});
    return (json['patients'] as List).map((p) => LabPatient.fromJson(p as Map<String, dynamic>)).toList();
  }

  // Profile

  Future<LabProfile> profile(String token) async {
    final json = await _get(token, '/lab/profile');
    return LabProfile.fromJson(json);
  }

  Future<LabProfile> updateProfile(
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
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/lab/profile'))
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
    return LabProfile.fromJson(_decode(response) as Map<String, dynamic>);
  }
}

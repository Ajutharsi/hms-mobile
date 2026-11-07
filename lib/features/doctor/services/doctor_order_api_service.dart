import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, ApiService, sessionExpired, serverFailure;
import 'package:hms_mobile/features/doctor/models/doctor_order_models.dart';

/// Client for `api/doctor/orders/*` — the four things a doctor orders
/// for a patient: lab, radiology, medicines and diet.
class DoctorOrderApiService {
  static String get baseUrl => ApiService.baseUrl;

  final http.Client _client;
  DoctorOrderApiService({http.Client? client}) : _client = client ?? http.Client();

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

    if (response.statusCode >= 200 && response.statusCode < 300) return body;

    if (response.statusCode == 422) {
      final errors = (body as Map<String, dynamic>?)?['errors'] as Map<String, dynamic>?;
      final first = errors?.values.first;
      throw ApiException(first is List && first.isNotEmpty
          ? first.first.toString()
          : (body?['message']?.toString() ?? 'Invalid request.'));
    }
    if (response.statusCode == 401) throw sessionExpired();
    throw serverFailure(response.statusCode, body is Map ? body['message']?.toString() : null);
  }

  Future<DoctorOrderBoard> board(String token, int patientId) async {
    final json = _decode(await _client.get(
      Uri.parse('$baseUrl/doctor/orders/$patientId'),
      headers: _headers(token),
    )) as Map<String, dynamic>;
    return DoctorOrderBoard.fromJson(json);
  }

  /// The catalogue the lab keeps; a doctor may read it to order from it.
  Future<List<OrderableTest>> labTests(String token) async {
    final json = _decode(await _client.get(
      Uri.parse('$baseUrl/lab/tests'),
      headers: _headers(token),
    )) as Map<String, dynamic>;

    return ((json['lab_tests'] as List?) ?? const [])
        .map((t) => OrderableTest.fromJson((t as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<String> _post(String token, String path, Map<String, dynamic> body) async {
    final json = _decode(await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    ));
    return (json is Map ? json['message']?.toString() : null) ?? 'Order placed.';
  }

  Future<String> orderLab(String token, int patientId, List<int> tests, {String? notes}) =>
      _post(token, '/doctor/orders/$patientId/lab', {
        'tests': tests,
        if ((notes ?? '').isNotEmpty) 'notes': notes,
      });

  Future<String> orderRadiology(String token, int patientId, Map<String, dynamic> body) =>
      _post(token, '/doctor/orders/$patientId/radiology', body);

  Future<String> orderMedicines(
    String token,
    int patientId,
    List<Map<String, dynamic>> medicines, {
    String? notes,
  }) =>
      _post(token, '/doctor/orders/$patientId/medicines', {
        'medicines': medicines,
        if ((notes ?? '').isNotEmpty) 'notes': notes,
      });

  Future<String> orderDiet(String token, int patientId, Map<String, dynamic> body) =>
      _post(token, '/doctor/orders/$patientId/diet', body);
}

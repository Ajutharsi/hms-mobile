import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, ApiService, sessionExpired, serverFailure;
import 'package:hms_mobile/features/emr/models/emr_models.dart';

/// Client for `api/emr/*` — the patient's medical record, shared by the
/// clinical roles rather than nested under one of them.
class EmrApiService {
  static String get baseUrl => ApiService.baseUrl;

  final http.Client _client;
  EmrApiService({http.Client? client}) : _client = client ?? http.Client();

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
    if (response.statusCode == 403) {
      throw ApiException((body is Map ? body['message']?.toString() : null) ?? 'You are not allowed to do that.');
    }
    throw serverFailure(response.statusCode, body is Map ? body['message']?.toString() : null);
  }

  Future<PatientEmr> record(String token, int patientId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/emr/patients/$patientId'),
      headers: _headers(token),
    );
    return PatientEmr.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<void> _post(String token, String path, Map<String, dynamic> body) async {
    _decode(await _client.post(Uri.parse('$baseUrl$path'), headers: _headers(token), body: jsonEncode(body)));
  }

  Future<void> _put(String token, String path, Map<String, dynamic> body) async {
    _decode(await _client.put(Uri.parse('$baseUrl$path'), headers: _headers(token), body: jsonEncode(body)));
  }

  Future<void> _delete(String token, String path) async {
    _decode(await _client.delete(Uri.parse('$baseUrl$path'), headers: _headers(token)));
  }

  Future<void> addAllergy(String token, int patientId, Map<String, dynamic> body) =>
      _post(token, '/emr/patients/$patientId/allergies', body);

  Future<void> removeAllergy(String token, int id) => _delete(token, '/emr/allergies/$id');

  Future<void> addProblem(String token, int patientId, Map<String, dynamic> body) =>
      _post(token, '/emr/patients/$patientId/problems', body);

  Future<void> updateProblem(String token, int id, Map<String, dynamic> body) =>
      _put(token, '/emr/problems/$id', body);

  Future<void> removeProblem(String token, int id) => _delete(token, '/emr/problems/$id');

  Future<void> addRecord(String token, int patientId, Map<String, dynamic> body) =>
      _post(token, '/emr/patients/$patientId/records', body);

  Future<void> removeRecord(String token, int id) => _delete(token, '/emr/records/$id');

  /// Photos taken on the ward, uploaded the same multipart way the
  /// profile photo is. Always POST -- PHP cannot read a multipart body
  /// off a PUT.
  Future<void> uploadAttachment(
    String token,
    int patientId, {
    required Uint8List bytes,
    required String filename,
    String? description,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/emr/patients/$patientId/attachments'))
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token';

    if ((description ?? '').isNotEmpty) request.fields['description'] = description!;
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final response = await http.Response.fromStream(await _client.send(request));
    _decode(response);
  }

  Future<void> removeAttachment(String token, int id) => _delete(token, '/emr/attachments/$id');
}

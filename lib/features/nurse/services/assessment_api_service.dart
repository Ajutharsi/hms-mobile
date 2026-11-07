import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, ApiService, sessionExpired, serverFailure;
import 'package:hms_mobile/features/nurse/models/nursing_assessment.dart';

/// Client for `api/assessments/*` — the scored bedside assessments that
/// nurses and doctors share.
class AssessmentApiService {
  static String get baseUrl => ApiService.baseUrl;

  final http.Client _client;
  AssessmentApiService({http.Client? client}) : _client = client ?? http.Client();

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

  Future<({int total, int needsAttention, List<NursingAssessment> rows})> assessments(
    String token, {
    int? patientId,
  }) async {
    final uri = Uri.parse('$baseUrl/assessments')
        .replace(queryParameters: patientId == null ? null : {'patient_id': '$patientId'});
    final json = _decode(await _client.get(uri, headers: _headers(token))) as Map<String, dynamic>;
    final stats = (json['stats'] as Map?) ?? const {};

    return (
      total: (stats['assessments'] as int?) ?? 0,
      needsAttention: (stats['needs_attention'] as int?) ?? 0,
      rows: ((json['assessments'] as List?) ?? const [])
          .map((a) => NursingAssessment.fromJson((a as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  Future<void> record(String token, int patientId, Map<String, dynamic> body) async {
    _decode(await _client.post(
      Uri.parse('$baseUrl/assessments/patients/$patientId'),
      headers: _headers(token),
      body: jsonEncode(body),
    ));
  }

  Future<void> remove(String token, int id) async {
    _decode(await _client.delete(Uri.parse('$baseUrl/assessments/$id'), headers: _headers(token)));
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, ApiService, sessionExpired;
import 'package:hms_mobile/features/discharge/models/discharge_models.dart';

/// Client for `api/discharge-summaries/*` — a stay gathered into the
/// document the patient leaves with.
class DischargeApiService {
  static String get baseUrl => ApiService.baseUrl;

  final http.Client _client;
  DischargeApiService({http.Client? client}) : _client = client ?? http.Client();

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
    throw ApiException((body is Map ? body['message']?.toString() : null) ?? 'Something went wrong (${response.statusCode}).');
  }

  Future<({int admitted, int unwritten, List<DischargeStay> stays})> stays(
    String token, {
    String state = 'admitted',
  }) async {
    final uri = Uri.parse('$baseUrl/discharge-summaries').replace(queryParameters: {'state': state});
    final json = _decode(await _client.get(uri, headers: _headers(token))) as Map<String, dynamic>;
    final stats = (json['stats'] as Map?) ?? const {};

    return (
      admitted: (stats['admitted'] as int?) ?? 0,
      unwritten: (stats['unwritten'] as int?) ?? 0,
      stays: ((json['admissions'] as List?) ?? const [])
          .map((a) => DischargeStay.fromJson((a as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  Future<DischargeSummary> summary(String token, int admissionId) async {
    final json = _decode(await _client.get(
      Uri.parse('$baseUrl/discharge-summaries/$admissionId'),
      headers: _headers(token),
    )) as Map<String, dynamic>;
    return DischargeSummary.fromJson(json);
  }

  Future<void> save(String token, int admissionId, String notes) async {
    _decode(await _client.post(
      Uri.parse('$baseUrl/discharge-summaries/$admissionId'),
      headers: _headers(token),
      body: jsonEncode({'discharge_notes': notes}),
    ));
  }
}

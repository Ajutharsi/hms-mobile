import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, ApiService, sessionExpired;
import 'package:hms_mobile/features/rounds/models/round_models.dart';

/// Client for `api/rounds/*` — the ward round and its notes.
class RoundApiService {
  static String get baseUrl => ApiService.baseUrl;

  final http.Client _client;
  RoundApiService({http.Client? client}) : _client = client ?? http.Client();

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

  Future<({Map<String, int> stats, List<RoundPatient> patients})> round(String token) async {
    final json = _decode(await _client.get(
      Uri.parse('$baseUrl/rounds'),
      headers: _headers(token),
    )) as Map<String, dynamic>;

    return (
      stats: ((json['stats'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', (v as int?) ?? 0)),
      patients: ((json['patients'] as List?) ?? const [])
          .map((p) => RoundPatient.fromJson((p as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  Future<RoundDetail> detail(String token, int admissionId) async {
    final json = _decode(await _client.get(
      Uri.parse('$baseUrl/rounds/$admissionId'),
      headers: _headers(token),
    )) as Map<String, dynamic>;
    return RoundDetail.fromJson(json);
  }

  Future<void> addNote(String token, int admissionId, Map<String, dynamic> body) async {
    _decode(await _client.post(
      Uri.parse('$baseUrl/rounds/$admissionId/notes'),
      headers: _headers(token),
      body: jsonEncode(body),
    ));
  }

  Future<void> removeNote(String token, int noteId) async {
    _decode(await _client.delete(Uri.parse('$baseUrl/rounds/notes/$noteId'), headers: _headers(token)));
  }
}

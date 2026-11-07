import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, ApiService, sessionExpired;
import 'package:hms_mobile/features/me/models/me_models.dart';

/// Client for `api/me/*` — what the signed-in account can see about
/// itself, whatever its role: attendance, leave, its own notifications
/// and the search box.
class MeApiService {
  static String get baseUrl => ApiService.baseUrl;

  final http.Client _client;
  MeApiService({http.Client? client}) : _client = client ?? http.Client();

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

  Future<Map<String, dynamic>> _get(String token, String path, [Map<String, String>? query]) async {
    final clean = query == null ? null : {for (final e in query.entries) if (e.value.isNotEmpty) e.key: e.value};
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: (clean?.isEmpty ?? true) ? null : clean);
    return _decode(await _client.get(uri, headers: _headers(token))) as Map<String, dynamic>;
  }

  Future<MyAttendance> attendance(String token, {String? month}) async =>
      MyAttendance.fromJson(await _get(token, '/me/attendance', {if (month != null) 'month': month}));

  Future<MyLeaves> leaves(String token) async => MyLeaves.fromJson(await _get(token, '/me/leaves'));

  Future<void> applyLeave(String token, Map<String, dynamic> body) async {
    _decode(await _client.post(Uri.parse('$baseUrl/me/leaves'), headers: _headers(token), body: jsonEncode(body)));
  }

  Future<void> withdrawLeave(String token, int id) async {
    _decode(await _client.delete(Uri.parse('$baseUrl/me/leaves/$id'), headers: _headers(token)));
  }

  Future<Inbox> inbox(String token) async => Inbox.fromJson(await _get(token, '/me/notifications'));

  /// With no ids, everything unread is marked.
  Future<void> markRead(String token, {List<int>? ids}) async {
    _decode(await _client.post(
      Uri.parse('$baseUrl/me/notifications/read'),
      headers: _headers(token),
      body: jsonEncode({if (ids != null) 'ids': ids}),
    ));
  }

  Future<List<SearchHit>> search(String token, String query) async {
    final json = await _get(token, '/me/search', {'q': query});
    return ((json['results'] as List?) ?? const [])
        .map((r) => SearchHit.fromJson((r as Map).cast<String, dynamic>()))
        .toList();
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Shared plumbing for the per-role API tests.
///
/// Every service takes an http.Client, so a role can be exercised end to
/// end -- request shape out, parsed models back -- without a server and
/// without a mocking package. The payloads are real captures in
/// test/fixtures, so a field the backend renames fails a test here
/// instead of showing up as a blank screen on a ward round.

/// One request the service made, as the test wants to read it.
class SeenRequest {
  final String method;
  final Uri url;
  final Map<String, String> headers;
  final String body;

  SeenRequest(this.method, this.url, this.headers, this.body);

  String? get bearer {
    final value = headers['Authorization'] ?? headers['authorization'];
    return value != null && value.startsWith('Bearer ') ? value.substring(7) : null;
  }
}

/// Reads a captured response. Fails loudly rather than returning '{}', so
/// a renamed fixture cannot quietly turn a test into a no-op.
String fixture(String name) {
  final file = File('test/fixtures/$name.json');
  if (!file.existsSync()) {
    throw StateError('Missing fixture test/fixtures/$name.json');
  }
  return file.readAsStringSync();
}

Map<String, dynamic> fixtureJson(String name) => jsonDecode(fixture(name)) as Map<String, dynamic>;

/// A client that answers everything with [body] and records what it was
/// asked for.
({http.Client client, List<SeenRequest> seen}) respondingWith(
  String body, {
  int status = 200,
}) {
  final seen = <SeenRequest>[];
  final client = MockClient((request) async {
    seen.add(SeenRequest(request.method, request.url, request.headers, request.body));
    return http.Response(body, status, headers: {'content-type': 'application/json'});
  });
  return (client: client, seen: seen);
}

/// A client that answers with a status and a Laravel-shaped error body.
({http.Client client, List<SeenRequest> seen}) failingWith(
  int status, {
  String message = 'Something broke.',
}) =>
    respondingWith(jsonEncode({'message': message}), status: status);

/// A client whose connection never gets off the device.
http.Client unreachable() => MockClient((_) async {
      throw const SocketException('Connection refused');
    });

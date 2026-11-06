import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';

/// Posts to whichever profile endpoint belongs to the signed-in role.
///
/// While `must_change_password` is set the server refuses every other
/// route with 403, so the role's own `POST /{role}/profile` is the one
/// door left open — and clearing the password clears the flag with it.
class ForcePasswordChangeViewModel extends ChangeNotifier {
  /// Each role's profile endpoint. Admin's was added alongside this
  /// screen; without it a forced admin had no way through at all.
  static const Map<String, String> _endpoints = {
    'super_admin': '/admin/profile',
    'admin': '/admin/profile',
    'doctor': '/doctor/profile',
    'nurse': '/nurse/profile',
    'lab_assistant': '/lab/profile',
    'pharmacist': '/pharmacy/profile',
    'receptionist': '/receptionist/profile',
  };

  final AppUser user;
  final AuthStorage _storage;
  final http.Client _client;

  ForcePasswordChangeViewModel({required this.user, AuthStorage? storage, http.Client? client})
      : _storage = storage ?? AuthStorage(),
        _client = client ?? http.Client();

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  /// Null on success, otherwise the message to show.
  Future<String?> change({required String current, required String next}) async {
    final endpoint = _endpoints[user.primaryRole];
    if (endpoint == null) {
      return 'This account type cannot change its password in the app yet. '
          'Please use the web portal.';
    }

    final token = await _storage.readToken();
    if (token == null) return 'Your session has expired. Please log in again.';

    _isSaving = true;
    notifyListeners();

    try {
      final response = await _client.post(
        Uri.parse('${ApiService.baseUrl}$endpoint'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': user.name,
          'email': user.email,
          'current_password': current,
          'password': next,
          'password_confirmation': next,
        }),
      );

      if (response.statusCode == 200) return null;

      final body = jsonDecode(response.body);
      if (body is Map) {
        // Laravel sends 422 with the per-field messages; show the first,
        // which is the one the person can act on.
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
        if (body['message'] != null) return body['message'].toString();
      }
      return 'Could not change the password (${response.statusCode}).';
    } catch (_) {
      return 'Could not reach the server. Check your connection and try again.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> logout() => _storage.clear();
}

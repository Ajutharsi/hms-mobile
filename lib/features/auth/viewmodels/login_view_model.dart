import 'package:flutter/material.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';

/// Holds all state and logic for the login screen. The View just renders
/// whatever this exposes and forwards user actions back to it — it never
/// talks to [ApiService] or [AuthStorage] directly.
class LoginViewModel extends ChangeNotifier {
  final ApiService _api;
  final AuthStorage _authStorage;

  LoginViewModel({ApiService? api, AuthStorage? authStorage})
      : _api = api ?? ApiService(),
        _authStorage = authStorage ?? AuthStorage();

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;
  String? errorMessage;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your email';
    if (!value.contains('@')) return 'Enter a valid email';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    return null;
  }

  /// Returns the logged-in user on success, or null (with [errorMessage]
  /// populated) on failure. Persisting the token and deciding where to
  /// navigate afterwards is left to the View.
  Future<AppUser?> submit() async {
    if (!formKey.currentState!.validate()) return null;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await guardNetworkErrors(() => _api.login(
            email: emailController.text.trim(),
            password: passwordController.text,
            deviceName: 'flutter-app',
          ));
      await _authStorage.saveToken(result.token);
      return result.user;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

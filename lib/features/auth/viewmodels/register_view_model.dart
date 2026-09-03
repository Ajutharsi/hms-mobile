import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';

/// Holds all state and logic for the registration screen.
class RegisterViewModel extends ChangeNotifier {
  final ApiService _api;

  RegisterViewModel({ApiService? api}) : _api = api ?? ApiService();

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool isLoading = false;
  String? errorMessage;
  String? gender;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleObscureConfirm() {
    obscureConfirm = !obscureConfirm;
    notifyListeners();
  }

  void setGender(String value) {
    gender = value;
    notifyListeners();
  }

  String? validateName(String? value) {
    if (value == null || value.trim().length < 2) return 'Enter your full name';
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your email';
    if (!value.contains('@')) return 'Enter a valid email';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.length < 8) return 'At least 8 characters';
    return null;
  }

  String? validateConfirm(String? value) {
    if (value != passwordController.text) return 'Passwords do not match';
    return null;
  }

  /// Returns true on success (the View then sends the user to Login).
  Future<bool> submit() async {
    if (!formKey.currentState!.validate()) return false;

    if (gender == null) {
      errorMessage = 'Please select your gender.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // The API returns a ready-to-use token too, but registration
      // deliberately doesn't auto-login — the user signs in themselves
      // with the account they just created.
      await guardNetworkErrors(() => _api.register(
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text,
            passwordConfirmation: confirmController.text,
            phone: phoneController.text.trim(),
            gender: gender!,
            deviceName: 'flutter-app',
          ));
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }
}

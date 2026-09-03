import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final ApiService _api;

  ForgotPasswordViewModel({ApiService? api}) : _api = api ?? ApiService();

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  bool isLoading = false;
  bool sent = false;
  String? errorMessage;

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your email';
    if (!value.contains('@')) return 'Enter a valid email';
    return null;
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await guardNetworkErrors(() => _api.forgotPassword(email: emailController.text.trim()));
      sent = true;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}

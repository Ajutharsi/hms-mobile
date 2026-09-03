import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hms_mobile/features/patient/models/patient_profile.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';

class ProfileViewModel extends ChangeNotifier {
  final ApiService _api;
  final AuthStorage _authStorage;

  ProfileViewModel({ApiService? api, AuthStorage? authStorage})
      : _api = api ?? ApiService(),
        _authStorage = authStorage ?? AuthStorage() {
    load();
  }

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  String? loadError;
  String? errorMessage;
  String? successMessage;

  PatientProfile? profile;

  /// Freshly-picked photo, held in memory until [save] uploads it — shown
  /// as a live preview in place of [PatientProfile.profilePhotoUrl].
  Uint8List? pendingPhotoBytes;
  String? _pendingPhotoName;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      profile = await guardNetworkErrors(() => _api.getProfile(token!));
      nameController.text = profile!.name;
      emailController.text = profile!.email;
      phoneController.text = profile!.phone ?? '';
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    pendingPhotoBytes = await picked.readAsBytes();
    _pendingPhotoName = picked.name;
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

  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return null; // changing password is optional
    if (value.length < 8) return 'At least 8 characters';
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (newPasswordController.text.isEmpty) return null;
    if (value != newPasswordController.text) return 'Passwords do not match';
    return null;
  }

  String? validateCurrentPassword(String? value) {
    if (newPasswordController.text.isEmpty) return null;
    if (value == null || value.isEmpty) return 'Enter your current password to set a new one';
    return null;
  }

  /// Returns true on success.
  Future<bool> save() async {
    if (!formKey.currentState!.validate()) return false;

    isSaving = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final token = await _authStorage.readToken();
      profile = await guardNetworkErrors(() => _api.updateProfile(
            token!,
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            phone: phoneController.text.trim(),
            currentPassword: currentPasswordController.text.isEmpty ? null : currentPasswordController.text,
            password: newPasswordController.text.isEmpty ? null : newPasswordController.text,
            passwordConfirmation: confirmPasswordController.text,
            photoBytes: pendingPhotoBytes,
            photoFilename: _pendingPhotoName,
          ));
      pendingPhotoBytes = null;
      _pendingPhotoName = null;
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      successMessage = 'Profile updated successfully!';
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}

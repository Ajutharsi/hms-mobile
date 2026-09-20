import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/features/patient/models/patient_profile.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/patient/viewmodels/profile_view_model.dart';

/// The Profile tab body — embedded inside [HomeScreen]'s bottom-nav shell.
/// Combines the web's separate patient-dashboard stats strip and
/// `/user/profile` edit form into one screen (see
/// PatientDashboardController + UserProfileController on the web side).
class ProfileTabBody extends StatelessWidget {
  const ProfileTabBody({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();

    if (viewModel.isLoading && viewModel.profile == null) {
      return const CareStateView.loading();
    }

    if (viewModel.loadError != null && viewModel.profile == null) {
      return RefreshIndicator(
        color: kCare,
        onRefresh: viewModel.load,
        child: CareStateView.error(viewModel.loadError!),
      );
    }

    final profile = viewModel.profile!;

    return RefreshIndicator(
      color: kCare,
      onRefresh: viewModel.load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: viewModel.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AvatarHeader(profile: profile, viewModel: viewModel),
              const SizedBox(height: 22),
              CareCard(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Account details',
                        style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: kInk)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: viewModel.nameController,
                      decoration: careFieldDecoration('Full name',
                          hint: 'Your name', icon: Icons.person_outline),
                      validator: viewModel.validateName,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: viewModel.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: careFieldDecoration('Email',
                          hint: 'you@example.com', icon: Icons.email_outlined),
                      validator: viewModel.validateEmail,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: viewModel.phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: careFieldDecoration('Phone',
                          hint: 'Optional', icon: Icons.phone_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CareCard(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Change password',
                        style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: kInk)),
                    const SizedBox(height: 4),
                    const Text('Leave blank to keep your current password.',
                        style: TextStyle(fontSize: 12.5, color: kMuted)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: viewModel.currentPasswordController,
                      obscureText: true,
                      decoration: careFieldDecoration('Current password',
                          hint: '••••••••', icon: Icons.lock_outline),
                      validator: viewModel.validateCurrentPassword,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: viewModel.newPasswordController,
                      obscureText: true,
                      decoration: careFieldDecoration('New password',
                          hint: 'At least 8 characters',
                          icon: Icons.lock_outline),
                      validator: viewModel.validateNewPassword,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: viewModel.confirmPasswordController,
                      obscureText: true,
                      decoration: careFieldDecoration('Confirm new password',
                          hint: '••••••••', icon: Icons.lock_outline),
                      validator: viewModel.validateConfirmPassword,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (viewModel.errorMessage != null) ...[
                authErrorBanner(viewModel.errorMessage!),
                const SizedBox(height: 14),
              ],
              if (viewModel.successMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: kCareSoft,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    viewModel.successMessage!,
                    style: const TextStyle(
                        color: kCareDark,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              CarePrimaryButton(
                label: 'Save changes',
                loading: viewModel.isSaving,
                onPressed: () => _save(context, viewModel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, ProfileViewModel viewModel) async {
    final success = await viewModel.save();
    if (!context.mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          backgroundColor: kCareDark,
          content: Text('Profile updated successfully!')),
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  final PatientProfile profile;
  final ProfileViewModel viewModel;
  const _AvatarHeader({required this.profile, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, gradient: kCareGradient),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: kCareSoft,
                  backgroundImage: viewModel.pendingPhotoBytes != null
                      ? MemoryImage(viewModel.pendingPhotoBytes!)
                      : (profile.profilePhotoUrl != null
                          ? NetworkImage(profile.profilePhotoUrl!)
                          : null) as ImageProvider?,
                  child: viewModel.pendingPhotoBytes == null &&
                          profile.profilePhotoUrl == null
                      ? Text(
                          profile.name.isNotEmpty
                              ? profile.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: kCareDark),
                        )
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: viewModel.pickPhoto,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: kCare,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5)),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(profile.name,
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w800, color: kInk)),
          const SizedBox(height: 2),
          Text(profile.email,
              style: const TextStyle(fontSize: 13, color: kMuted)),
          if ((profile.mrn ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: kCareSoft, borderRadius: BorderRadius.circular(20)),
              child: Text(
                'MRN: ${profile.mrn}',
                style: const TextStyle(fontSize: 12, color: kCareDark, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

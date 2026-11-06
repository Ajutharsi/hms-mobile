import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/receptionist/models/reception_profile.dart';
import 'package:hms_mobile/features/receptionist/viewmodels/reception_profile_view_model.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';

class ReceptionProfileScreen extends StatelessWidget {
  /// Which role's profile endpoint to use. Every role serves the same
  /// shape at /{role}/profile, so this one screen covers all of them.
  final String endpointPrefix;

  const ReceptionProfileScreen({super.key, this.endpointPrefix = '/receptionist'});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => ReceptionProfileViewModel(endpointPrefix: endpointPrefix),
      child: const _ReceptionProfileView(),
    );
  }
}

class _ReceptionProfileView extends StatelessWidget {
  const _ReceptionProfileView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<ReceptionProfileViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'My Profile'),
      body: _buildBody(context, viewModel),
    ));
  }

  Widget _buildBody(BuildContext context, ReceptionProfileViewModel viewModel) {
    if (viewModel.isLoading && viewModel.profile == null) {
      return const CareStateView.loading();
    }

    if (viewModel.loadError != null && viewModel.profile == null) {
      return RefreshIndicator(
        color: kCare,
        onRefresh: viewModel.load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
            const SizedBox(height: 12),
            Text(viewModel.loadError!, textAlign: TextAlign.center, style: CareText.muted),
          ],
        ),
      );
    }

    final profile = viewModel.profile!;

    return RefreshIndicator(
      color: kCare,
      onRefresh: viewModel.load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Form(
          key: viewModel.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AvatarHeader(profile: profile, viewModel: viewModel),
              const SizedBox(height: 24),
              const Text('Account details', style: CareText.titleLg),
              const SizedBox(height: 12),
              TextFormField(
                controller: viewModel.nameController,
                decoration: careFieldDecoration('Full name', hint: 'Your name', icon: Icons.person_outline),
                validator: viewModel.validateName,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: viewModel.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: careFieldDecoration('Email', hint: 'you@example.com', icon: Icons.email_outlined),
                validator: viewModel.validateEmail,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: viewModel.phoneController,
                keyboardType: TextInputType.phone,
                decoration: careFieldDecoration('Phone', hint: 'Optional', icon: Icons.phone_outlined),
              ),
              const SizedBox(height: 24),
              const Text('Change password', style: CareText.titleLg),
              const SizedBox(height: 4),
              const Text('Leave blank to keep your current password.', style: CareText.mutedSm),
              const SizedBox(height: 12),
              TextFormField(
                controller: viewModel.currentPasswordController,
                obscureText: true,
                decoration: careFieldDecoration('Current password', hint: '••••••••', icon: Icons.lock_outline),
                validator: viewModel.validateCurrentPassword,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: viewModel.newPasswordController,
                obscureText: true,
                decoration: careFieldDecoration('New password', hint: 'At least 8 characters', icon: Icons.lock_outline),
                validator: viewModel.validateNewPassword,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: viewModel.confirmPasswordController,
                obscureText: true,
                decoration: careFieldDecoration('Confirm new password', hint: '••••••••', icon: Icons.lock_outline),
                validator: viewModel.validateConfirmPassword,
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
                  decoration: BoxDecoration(color: kCareSoft, borderRadius: BorderRadius.circular(CareRadius.control)),
                  child: Text(
                    viewModel.successMessage!,
                    style: CareText.brandMdMedium,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: viewModel.isSaving ? null : () => _save(context, viewModel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCareDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CareRadius.control)),
                  ),
                  child: viewModel.isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save changes', style: CareText.onCareBold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, ReceptionProfileViewModel viewModel) async {
    final success = await viewModel.save();
    if (!context.mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: kCareDark, content: const Text('Profile updated successfully!')),
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  final ReceptionProfile profile;
  final ReceptionProfileViewModel viewModel;
  const _AvatarHeader({required this.profile, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: kCareSoft,
                backgroundImage: viewModel.pendingPhotoBytes != null
                    ? MemoryImage(viewModel.pendingPhotoBytes!)
                    : (profile.profilePhotoUrl != null ? NetworkImage(profile.profilePhotoUrl!) : null) as ImageProvider?,
                child: viewModel.pendingPhotoBytes == null && profile.profilePhotoUrl == null
                    ? Text(
                        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                        style: CareText.statBig,
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: viewModel.pickPhoto,
                  borderRadius: BorderRadius.circular(CareRadius.panel),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: kCareDark, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(profile.name, style: CareText.titleH3),
          if ((profile.department ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: kCareBg, borderRadius: BorderRadius.circular(CareRadius.chip)),
              child: Text(
                profile.department!,
                style: CareText.mutedXsMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

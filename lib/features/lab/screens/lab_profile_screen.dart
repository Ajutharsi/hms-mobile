import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/lab/models/lab_profile.dart';
import 'package:hms_mobile/features/lab/viewmodels/lab_profile_view_model.dart';

class LabProfileScreen extends StatelessWidget {
  const LabProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => LabProfileViewModel(),
      child: const _LabProfileView(),
    );
  }
}

class _LabProfileView extends StatelessWidget {
  const _LabProfileView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<LabProfileViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'My Profile'),
      body: _buildBody(context, viewModel),
    ));
  }

  Widget _buildBody(BuildContext context, LabProfileViewModel viewModel) {
    if (viewModel.isLoading && viewModel.profile == null) {
      return Center(child: CircularProgressIndicator(color: kCare));
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
            Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
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
              const Text('Account details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
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
              const Text('Change password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(height: 4),
              const Text('Leave blank to keep your current password.', style: TextStyle(fontSize: 12.5, color: kMuted)),
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
                  decoration: BoxDecoration(color: kCareSoft, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    viewModel.successMessage!,
                    style: TextStyle(color: kCareDark, fontSize: 13.5, fontWeight: FontWeight.w600),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: viewModel.isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, LabProfileViewModel viewModel) async {
    final success = await viewModel.save();
    if (!context.mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: kCareDark, content: const Text('Profile updated successfully!')),
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  final LabProfile profile;
  final LabProfileViewModel viewModel;
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
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: kCareDark),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: viewModel.pickPhoto,
                  borderRadius: BorderRadius.circular(20),
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
          Text(profile.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
          if ((profile.department ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: kCareBg, borderRadius: BorderRadius.circular(8)),
              child: Text(
                profile.department!,
                style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

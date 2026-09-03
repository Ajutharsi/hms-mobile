import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/receptionist/models/reception_profile.dart';
import 'package:hms_mobile/features/receptionist/viewmodels/reception_profile_view_model.dart';

class ReceptionProfileScreen extends StatelessWidget {
  const ReceptionProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReceptionProfileViewModel(),
      child: const _ReceptionProfileView(),
    );
  }
}

class _ReceptionProfileView extends StatelessWidget {
  const _ReceptionProfileView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReceptionProfileViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, foregroundColor: kInk, elevation: 0, title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w700))),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, ReceptionProfileViewModel viewModel) {
    if (viewModel.isLoading && viewModel.profile == null) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }

    if (viewModel.loadError != null && viewModel.profile == null) {
      return RefreshIndicator(
        color: kTeal,
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
      color: kTeal,
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
                decoration: authFieldDecoration('Full name', hint: 'Your name', icon: Icons.person_outline),
                validator: viewModel.validateName,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: viewModel.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: authFieldDecoration('Email', hint: 'you@example.com', icon: Icons.email_outlined),
                validator: viewModel.validateEmail,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: viewModel.phoneController,
                keyboardType: TextInputType.phone,
                decoration: authFieldDecoration('Phone', hint: 'Optional', icon: Icons.phone_outlined),
              ),
              const SizedBox(height: 24),
              const Text('Change password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(height: 4),
              const Text('Leave blank to keep your current password.', style: TextStyle(fontSize: 12.5, color: kMuted)),
              const SizedBox(height: 12),
              TextFormField(
                controller: viewModel.currentPasswordController,
                obscureText: true,
                decoration: authFieldDecoration('Current password', hint: '••••••••', icon: Icons.lock_outline),
                validator: viewModel.validateCurrentPassword,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: viewModel.newPasswordController,
                obscureText: true,
                decoration: authFieldDecoration('New password', hint: 'At least 8 characters', icon: Icons.lock_outline),
                validator: viewModel.validateNewPassword,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: viewModel.confirmPasswordController,
                obscureText: true,
                decoration: authFieldDecoration('Confirm new password', hint: '••••••••', icon: Icons.lock_outline),
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
                  decoration: BoxDecoration(color: kMint, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    viewModel.successMessage!,
                    style: const TextStyle(color: kTealDark, fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: viewModel.isSaving ? null : () => _save(context, viewModel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTealDark,
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

  Future<void> _save(BuildContext context, ReceptionProfileViewModel viewModel) async {
    final success = await viewModel.save();
    if (!context.mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(backgroundColor: kTealDark, content: Text('Profile updated successfully!')),
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  final ReceptionProfile profile;
  final ReceptionProfileViewModel viewModel;
  const _AvatarHeader({required this.profile, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: kMint,
                backgroundImage: viewModel.pendingPhotoBytes != null
                    ? MemoryImage(viewModel.pendingPhotoBytes!)
                    : (profile.profilePhotoUrl != null ? NetworkImage(profile.profilePhotoUrl!) : null) as ImageProvider?,
                child: viewModel.pendingPhotoBytes == null && profile.profilePhotoUrl == null
                    ? Text(
                        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: kTealDark),
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
                    decoration: const BoxDecoration(color: kTealDark, shape: BoxShape.circle),
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
              decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(8)),
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

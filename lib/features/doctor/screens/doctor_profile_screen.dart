import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/doctor/viewmodels/doctor_view_models.dart';

/// The doctor's account details, plus the registration details the Doctor
/// record carries (specialisation, qualification, fee) shown read-only —
/// those are maintained by an admin on the web.
class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorProfileViewModel(),
      child: const CareTheme(child: _ProfileView()),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  Future<void> _save(BuildContext context, DoctorProfileViewModel viewModel) async {
    final success = await viewModel.save();
    if (!context.mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: kCareDark, content: const Text('Profile updated successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<DoctorProfileViewModel>();

    return Scaffold(
      appBar: carePageAppBar(context, 'My Profile'),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, DoctorProfileViewModel viewModel) {
    if (viewModel.isLoading && viewModel.profile == null) return const CareStateView.loading();
    if (viewModel.loadError != null && viewModel.profile == null) return CareStateView.error(viewModel.loadError!);

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
              Center(
                child: Column(
                  children: [
                    CareAvatar(name: profile.name, imageUrl: profile.photoUrl, radius: 44),
                    const SizedBox(height: 12),
                    Text(profile.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: kInk)),
                    const SizedBox(height: 2),
                    Text(profile.email, style: const TextStyle(fontSize: 13, color: kMuted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        if ((profile.doctorCode ?? '').isNotEmpty)
                          CareChip(label: profile.doctorCode!, bg: kCareSoft, fg: kCareDark, icon: Icons.badge_rounded),
                        if ((profile.specialization ?? '').isNotEmpty)
                          CareChip(label: profile.specialization!, bg: kInfoBg, fg: kInfoFg),
                        if ((profile.qualification ?? '').isNotEmpty)
                          CareChip(label: profile.qualification!, bg: kSuccessBg, fg: kSuccessFg),
                      ],
                    ),
                  ],
                ),
              ),
              if (!profile.isLinked) ...[
                const SizedBox(height: 18),
                const CareCard(
                  child: Row(
                    children: [
                      CareIconBox(icon: Icons.info_outline_rounded, size: 40),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This login is not linked to a doctor record yet, so it has no appointments. An admin can link it on the web.',
                          style: TextStyle(fontSize: 12.5, color: kMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              CareCard(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Account details', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: kInk)),
                    const SizedBox(height: 16),
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CareCard(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Change password', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: kInk)),
                    const SizedBox(height: 4),
                    const Text('Leave blank to keep your current password.', style: TextStyle(fontSize: 12.5, color: kMuted)),
                    const SizedBox(height: 16),
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
                      validator: viewModel.validateConfirm,
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
                  decoration: BoxDecoration(color: kCareSoft, borderRadius: BorderRadius.circular(12)),
                  child: Text(viewModel.successMessage!,
                      style: TextStyle(color: kCareDark, fontSize: 13.5, fontWeight: FontWeight.w600)),
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
}

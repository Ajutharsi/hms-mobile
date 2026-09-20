import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/auth/viewmodels/register_view_model.dart';
import 'package:hms_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:hms_mobile/features/auth/screens/login_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => RegisterViewModel(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  Future<void> _handleSubmit(RegisterViewModel viewModel) async {
    final success = await viewModel.submit();
    if (!success || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(flashMessage: 'Account created — sign in to continue.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<RegisterViewModel>();

    return AuthScaffold(
      illustrationHeadline: 'Your care, in your pocket.',
      illustrationSubtext: 'Book appointments and see your records anytime.',
      formPane: Form(
        key: viewModel.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 28),
            const Text(
              'Create your account',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: kInk, height: 1.15),
            ),
            const SizedBox(height: 8),
            const Text(
              'Register as a patient to book appointments and view your records.',
              style: TextStyle(fontSize: 14.5, color: kMuted),
            ),
            const SizedBox(height: 24),
            if (viewModel.errorMessage != null) ...[
              authErrorBanner(viewModel.errorMessage!),
              const SizedBox(height: 20),
            ],
            TextFormField(
              controller: viewModel.nameController,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              style: const TextStyle(color: kInk, fontSize: 15),
              decoration: careFieldDecoration('Full name', hint: 'e.g. Priya Sharma', icon: Icons.person_outline_rounded),
              validator: viewModel.validateName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: viewModel.emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              style: const TextStyle(color: kInk, fontSize: 15),
              decoration: careFieldDecoration('Email', hint: 'you@example.com', icon: Icons.mail_outline_rounded),
              validator: viewModel.validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: viewModel.phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              style: const TextStyle(color: kInk, fontSize: 15),
              decoration: careFieldDecoration('Phone (optional)', hint: '98765 43210', icon: Icons.call_outlined),
            ),
            const SizedBox(height: 18),
            const Text('Gender', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
            const SizedBox(height: 8),
            Row(
              children: [
                _GenderOption(label: 'Male', value: 'male', selected: viewModel.gender, onChanged: viewModel.setGender),
                const SizedBox(width: 10),
                _GenderOption(label: 'Female', value: 'female', selected: viewModel.gender, onChanged: viewModel.setGender),
                const SizedBox(width: 10),
                _GenderOption(label: 'Other', value: 'other', selected: viewModel.gender, onChanged: viewModel.setGender),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: viewModel.passwordController,
              obscureText: viewModel.obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              style: const TextStyle(color: kInk, fontSize: 15),
              decoration: careFieldDecoration('Password', hint: 'At least 8 characters', icon: Icons.lock_outline_rounded).copyWith(
                suffixIcon: IconButton(
                  splashRadius: 20,
                  icon: Icon(
                    viewModel.obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: kMuted,
                    size: 20,
                  ),
                  onPressed: viewModel.toggleObscurePassword,
                ),
              ),
              validator: viewModel.validatePassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: viewModel.confirmController,
              obscureText: viewModel.obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSubmit(viewModel),
              style: const TextStyle(color: kInk, fontSize: 15),
              decoration: careFieldDecoration('Confirm password', hint: 'Re-enter your password', icon: Icons.lock_outline_rounded)
                  .copyWith(
                suffixIcon: IconButton(
                  splashRadius: 20,
                  icon: Icon(
                    viewModel.obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: kMuted,
                    size: 20,
                  ),
                  onPressed: viewModel.toggleObscureConfirm,
                ),
              ),
              validator: viewModel.validateConfirm,
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: viewModel.isLoading ? null : () => _handleSubmit(viewModel),
                style: FilledButton.styleFrom(
                  backgroundColor: kCare,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: viewModel.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Create account', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13.5, color: kMuted),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Sign in',
                      style: TextStyle(color: kCare, fontWeight: FontWeight.w600),
                      recognizer: TapGestureRecognizer()..onTap = () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final String value;
  final String? selected;
  final ValueChanged<String> onChanged;

  const _GenderOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? kCare : kFieldFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? kCare : Colors.transparent),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : kMuted,
            ),
          ),
        ),
      ),
    );
  }
}

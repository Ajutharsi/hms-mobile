import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/auth/viewmodels/forgot_password_view_model.dart';
import 'package:hms_mobile/features/auth/widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ForgotPasswordViewModel(),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatelessWidget {
  const _ForgotPasswordView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ForgotPasswordViewModel>();

    return AuthScaffold(
      illustrationHeadline: 'We\'ve got you covered.',
      illustrationSubtext: "A reset link is just an email away.",
      formPane: viewModel.sent
          ? _SentConfirmation(email: viewModel.emailController.text.trim())
          : _ForgotPasswordForm(viewModel: viewModel),
    );
  }
}

class _ForgotPasswordForm extends StatelessWidget {
  final ForgotPasswordViewModel viewModel;
  const _ForgotPasswordForm({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: viewModel.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 28),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: kInk),
          ),
          const SizedBox(height: 20),
          const Text(
            'Reset your password',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kInk, height: 1.15),
          ),
          const SizedBox(height: 8),
          const Text(
            "Enter your account email and we'll send you a link to set a new password.",
            style: TextStyle(fontSize: 14.5, color: kMuted),
          ),
          const SizedBox(height: 30),
          if (viewModel.errorMessage != null) ...[
            authErrorBanner(viewModel.errorMessage!),
            const SizedBox(height: 20),
          ],
          TextFormField(
            controller: viewModel.emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => viewModel.submit(),
            style: const TextStyle(color: kInk, fontSize: 15),
            decoration: authFieldDecoration('Email', hint: 'you@example.com', icon: Icons.mail_outline_rounded),
            validator: viewModel.validateEmail,
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: viewModel.isLoading ? null : viewModel.submit,
              style: FilledButton.styleFrom(
                backgroundColor: kTealDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: viewModel.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text(
                      'Send reset link',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentConfirmation extends StatelessWidget {
  final String email;
  const _SentConfirmation({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 28),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: kMint, borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.center,
          child: const Icon(Icons.mark_email_read_outlined, color: kTeal, size: 28),
        ),
        const SizedBox(height: 24),
        const Text(
          'Check your email',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: kInk, height: 1.15),
        ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14.5, color: kMuted, height: 1.5),
            children: [
              const TextSpan(text: "We've sent a password reset link to "),
              TextSpan(text: email, style: const TextStyle(color: kInk, fontWeight: FontWeight.w600)),
              const TextSpan(
                text: '. Open it on this device to set a new password, then come back and sign in.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kTeal),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Back to sign in',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: kTeal),
            ),
          ),
        ),
      ],
    );
  }
}

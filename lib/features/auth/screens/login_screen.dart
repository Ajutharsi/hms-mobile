import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/navigation/role_home.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/auth/viewmodels/login_view_model.dart';
import 'package:hms_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:hms_mobile/features/auth/screens/forgot_password_screen.dart';
import 'package:hms_mobile/features/auth/screens/register_screen.dart';

/// View for the login screen — owns no business logic itself, just renders
/// [LoginViewModel]'s state and forwards user actions to it.
class LoginScreen extends StatelessWidget {
  /// Shown as a one-off snackbar right after the screen appears — used by
  /// [RegisterScreen] to say "account created, now sign in" after it sends
  /// the user back here.
  final String? flashMessage;

  const LoginScreen({super.key, this.flashMessage});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: _LoginView(flashMessage: flashMessage),
    );
  }
}

class _LoginView extends StatefulWidget {
  final String? flashMessage;
  const _LoginView({this.flashMessage});

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  @override
  void initState() {
    super.initState();
    final message = widget.flashMessage;
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: kCare),
        );
      });
    }
  }

  Future<void> _handleSubmit(LoginViewModel viewModel) async {
    final user = await viewModel.submit();
    if (user == null || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => RoleHome(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<LoginViewModel>();

    return AuthScaffold(
      illustrationHeadline: 'Care, coordinated.',
      illustrationSubtext: 'One login for the whole hospital team.',
      formPane: Form(
        key: viewModel.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 28),
            const Text(
              'Welcome back',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kInk, height: 1.15),
            ),
            const SizedBox(height: 8),
            const Text(
              "Let's get you signed in.",
              style: TextStyle(fontSize: 15, color: kMuted),
            ),
            const SizedBox(height: 24),
            if (viewModel.errorMessage != null) ...[
              authErrorBanner(viewModel.errorMessage!),
              const SizedBox(height: 20),
            ],
            TextFormField(
              controller: viewModel.emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              style: const TextStyle(color: kInk, fontSize: 15),
              decoration: careFieldDecoration('Email', hint: 'you@example.com', icon: Icons.mail_outline_rounded),
              validator: viewModel.validateEmail,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: viewModel.passwordController,
              obscureText: viewModel.obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _handleSubmit(viewModel),
              style: const TextStyle(color: kInk, fontSize: 15),
              decoration: careFieldDecoration('Password', hint: '••••••••', icon: Icons.lock_outline_rounded).copyWith(
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
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  );
                },
                child: Text(
                  'Forgot password?',
                  style: TextStyle(color: kCare, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
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
                    : const Text(
                        'Login',
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13.5, color: kMuted),
                  children: [
                    const TextSpan(text: 'New patient? '),
                    TextSpan(
                      text: 'Create an account',
                      style: TextStyle(color: kCare, fontWeight: FontWeight.w600),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'Hospital Management System',
                style: TextStyle(color: kMuted.withValues(alpha: 0.7), fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

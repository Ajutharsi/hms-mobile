import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/auth/viewmodels/force_password_change_view_model.dart';

/// Shown instead of the role's home when the hospital has forced a
/// password change.
///
/// Without it the account was effectively locked: the server answers 403
/// on every route while `must_change_password` is set, and the only ones
/// it leaves open are the roles' own profile endpoints. The app read the
/// flag, did nothing with it, and dropped the person on a home screen
/// where every panel failed to load and nothing explained why.
///
/// There is no way past this screen except changing the password or
/// signing out — which is the point.
class ForcePasswordChangeScreen extends StatelessWidget {
  final AppUser user;

  /// Called once the password is changed, so the session can be re-read
  /// and the person sent to their real home.
  final VoidCallback onChanged;

  const ForcePasswordChangeScreen({super.key, required this.user, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ForcePasswordChangeViewModel(user: user),
      child: CareTheme(child: _ForcePasswordChangeView(onChanged: onChanged)),
    );
  }
}

class _ForcePasswordChangeView extends StatefulWidget {
  final VoidCallback onChanged;
  const _ForcePasswordChangeView({required this.onChanged});

  @override
  State<_ForcePasswordChangeView> createState() => _ForcePasswordChangeViewState();
}

class _ForcePasswordChangeViewState extends State<_ForcePasswordChangeView> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _showCurrent = false;
  bool _showNext = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit(ForcePasswordChangeViewModel viewModel) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final error = await viewModel.change(current: _current.text, next: _next.text);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: kDangerText, content: Text(error, style: const TextStyle(color: Colors.white))),
      );
      return;
    }
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<ForcePasswordChangeViewModel>();

    return Scaffold(
      backgroundColor: kCareBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
          children: [
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(color: kCareSoft, shape: BoxShape.circle),
                child: Icon(Icons.lock_reset_rounded, size: 36, color: kCare),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Choose a new password', textAlign: TextAlign.center, style: CareText.titleXxl),
            const SizedBox(height: 8),
            const Text(
              'Your hospital has asked you to change it before carrying on. '
              'Nothing else will load until you do.',
              textAlign: TextAlign.center,
              style: CareText.bodyMdMuted,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(CareRadius.card),
                border: Border.all(color: kCareBorder),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CareAvatar(name: viewModel.user.name, radius: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(viewModel.user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.titleMd),
                              Text(viewModel.user.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.mutedSm),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _current,
                      obscureText: !_showCurrent,
                      decoration: careFieldDecoration('Current password', hint: '', icon: Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_showCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: kCareHint),
                          onPressed: () => setState(() => _showCurrent = !_showCurrent),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter your current password' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _next,
                      obscureText: !_showNext,
                      decoration: careFieldDecoration('New password', hint: 'At least 8 characters', icon: Icons.lock_reset_outlined)
                          .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_showNext ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: kCareHint),
                          onPressed: () => setState(() => _showNext = !_showNext),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 8) return 'Use at least 8 characters';
                        if (v == _current.text) return 'Pick something different from the old one';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirm,
                      obscureText: !_showNext,
                      decoration: careFieldDecoration('Confirm new password', hint: '', icon: Icons.check_circle_outline),
                      validator: (v) => v != _next.text ? 'The two do not match' : null,
                    ),
                    const SizedBox(height: 22),
                    CarePrimaryButton(
                      label: 'Change password',
                      loading: viewModel.isSaving,
                      onPressed: viewModel.isSaving ? null : () => _submit(viewModel),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton.icon(
                onPressed: viewModel.isSaving
                    ? null
                    : () async {
                        await viewModel.logout();
                        // The same hook a 401 uses: clears the session and
                        // sends them back to the login screen.
                        onSessionExpired?.call();
                      },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign out instead', style: CareText.mutedSmMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

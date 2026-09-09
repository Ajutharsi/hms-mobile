import 'package:flutter/material.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/auth/widgets/auth_illustration.dart';

/// Shared responsive shell for the login/register screens: a split
/// illustration+form layout on wide viewports, form-only (with a compact
/// illustration on top instead) on narrow ones.
class AuthScaffold extends StatelessWidget {
  final Widget formPane;
  final String illustrationHeadline;
  final String illustrationSubtext;

  const AuthScaffold({
    super.key,
    required this.formPane,
    required this.illustrationHeadline,
    required this.illustrationSubtext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= kSplitBreakpoint;

            if (!isWide) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AuthCompactIllustration(),
                        const SizedBox(height: 20),
                        formPane,
                      ],
                    ),
                  ),
                ),
              );
            }

            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: AuthIllustrationPane(headline: illustrationHeadline, subtext: illustrationSubtext),
                ),
                Expanded(
                  flex: 6,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: formPane,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

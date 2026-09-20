import 'package:flutter/material.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
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
      backgroundColor: kCareBg,
      body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= kSplitBreakpoint;

            if (!isWide) {
              return _CompactAuthLayout(
                subtext: illustrationSubtext,
                formPane: formPane,
              );
            }

            return SafeArea(
              child: Row(
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
              ),
            );
          },
        ),
    );
  }
}

/// Phone layout: teal patterned header with the app mark, and the form in
/// a white card that overlaps the header's curved bottom edge.
class _CompactAuthLayout extends StatelessWidget {
  final String subtext;
  final Widget formPane;

  const _CompactAuthLayout({required this.subtext, required this.formPane});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return SingleChildScrollView(
      child: Stack(
        children: [
          SizedBox(
            height: 290 + topInset,
            width: double.infinity,
            child: CareHeaderBackground(
              radius: 36,
              padding: EdgeInsets.fromLTRB(24, topInset + 28, 24, 0),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6))],
                    ),
                    child: const Icon(Icons.medical_services_rounded, color: kCare, size: 32),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'HMS India',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtext,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, 210 + topInset, 18, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [BoxShadow(color: Color(0x1A0E6B61), blurRadius: 30, offset: Offset(0, 12))],
                  ),
                  child: formPane,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

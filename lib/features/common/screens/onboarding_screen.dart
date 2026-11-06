import 'package:flutter/material.dart';

import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';

/// Three cards shown once, before the first login.
///
/// Patients arrive at this app without being told what it does; staff are
/// handed credentials and already know. So it is skippable, it is shown
/// once, and it says what the app is for rather than how to use it.
class OnboardingScreen extends StatefulWidget {
  /// Called when the intro is finished or skipped.
  final VoidCallback onDone;

  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = <({IconData icon, String title, String body})>[
    (
      icon: Icons.event_available_rounded,
      title: 'Book without queueing',
      body: 'Pick a doctor, a day and a slot from your phone. Your token number is waiting when you arrive.',
    ),
    (
      icon: Icons.medication_rounded,
      title: 'Prescriptions and results',
      body: 'Every prescription written for you and every lab result, kept together instead of on paper.',
    ),
    (
      icon: Icons.receipt_long_rounded,
      title: 'Bills in one place',
      body: 'See what a visit cost, what has been paid and what is still open.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _slides.length - 1) {
      widget.onDone();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: kCareBg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onDone,
                child: const Text('Skip', style: CareText.mutedSmMedium),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) => _Slide(slide: _slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? kCare : kCareBorder,
                      borderRadius: BorderRadius.circular(CareRadius.pill),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              child: CarePrimaryButton(
                label: isLast ? 'Get started' : 'Next',
                icon: isLast ? Icons.arrow_forward_rounded : null,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final ({IconData icon, String title, String body}) slide;
  const _Slide({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(color: kCareSoft, shape: BoxShape.circle),
            child: Icon(slide.icon, size: 66, color: kCare),
          ),
          const SizedBox(height: 32),
          Text(slide.title, textAlign: TextAlign.center, style: CareText.titleH3),
          const SizedBox(height: 10),
          Text(slide.body, textAlign: TextAlign.center, style: CareText.bodyMdMuted),
        ],
      ),
    );
  }
}

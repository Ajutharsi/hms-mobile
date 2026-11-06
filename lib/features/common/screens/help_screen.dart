import 'package:flutter/material.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';

/// Answers to the questions the front desk gets asked about the app.
///
/// It deliberately carries no phone number or support address: those
/// belong to each hospital, and a wrong one printed in the app is worse
/// than none. What it does carry is what to quote when reporting a
/// problem.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = <({String question, String answer})>[
    (
      question: 'I cannot log in',
      answer: 'Use the email address the hospital registered for you. If the password was reset for you, '
          'the app will ask you to choose a new one the first time you sign in. '
          'Three wrong tries in a row are slowed down on purpose, so wait a minute before trying again.',
    ),
    (
      question: 'Why does it say my session expired?',
      answer: 'A signed-in session lasts a week. After that the app asks for the password again. '
          'Nothing is lost -- sign in and carry on where you were.',
    ),
    (
      question: 'The screen says there is no connection',
      answer: 'The app talks to the hospital server for everything, so it needs Wi-Fi or mobile data. '
          'On the hospital network, check you are on the staff Wi-Fi rather than a guest one.',
    ),
    (
      question: 'Something is missing from a list',
      answer: 'Lists show the most recent records first and are capped, so very old entries may not appear. '
          'Pull the list down to refresh it; if a record is still missing, it may belong to another doctor '
          'or department.',
    ),
    (
      question: 'Can I change the colours or text size?',
      answer: 'Settings - Appearance changes the app colour. Text size follows your phone, '
          'so set it in the phone display settings and the app will follow.',
    ),
    (
      question: 'Is my data stored on the phone?',
      answer: 'No. Only your sign-in token and your app settings are kept on the device, in encrypted storage. '
          'Patient records are fetched from the hospital server each time and are not saved here.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);

    return Scaffold(
      appBar: carePageAppBar(context, 'Help & Support'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const CareSectionTitle(title: 'Common questions'),
          const SizedBox(height: 8),
          CareCard(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Column(
              children: [
                for (final faq in _faqs)
                  Theme(
                    // The stock expansion tile draws its own divider lines
                    // over the card's border; this drops them.
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(faq.question, style: CareText.titleMd),
                      iconColor: kCare,
                      collapsedIconColor: kCareHint,
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(faq.answer, style: CareText.bodyMdMuted)],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const CareSectionTitle(title: 'Still stuck'),
          const SizedBox(height: 8),
          CareCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ask the front desk or your hospital IT team -- they administer the accounts and can see '
                  'the same records from the web portal.',
                  style: CareText.bodyMdMuted,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: kCareNeutralBg,
                    borderRadius: BorderRadius.circular(CareRadius.control),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('When reporting a problem, say:', style: CareText.titleSm),
                      SizedBox(height: 6),
                      Text(
                        '• what you were trying to do\n'
                        '• the exact words of any message on screen\n'
                        '• the app version, from Settings - About',
                        style: CareText.mutedSm,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

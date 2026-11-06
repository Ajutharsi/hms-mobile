import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';

/// Version, what the app does with data, and the legal pages.
///
/// The privacy section describes what this app actually does rather than
/// standing in for the hospital's own policy, which is the document that
/// governs the records themselves.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '—';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    } catch (_) {
      if (mounted) setState(() => _version = 'unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);

    return Scaffold(
      appBar: carePageAppBar(context, 'About'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: kCareSoft,
                  borderRadius: BorderRadius.circular(CareRadius.panel),
                ),
                child: Icon(Icons.medical_services_rounded, color: kCare, size: 38),
              ),
              const SizedBox(height: 12),
              const Text('HMS India', style: CareText.titleXxl),
              Text('Version $_version', style: CareText.mutedSm),
            ],
          ),
          const SizedBox(height: 22),
          const CareCard(
            child: Text(
              'The mobile side of the HMS India hospital system. Patients book visits and follow their '
              'records; doctors, nurses, the front desk, the lab, the pharmacy and administrators do their '
              'own work from the same login.',
              style: CareText.bodyMdMuted,
            ),
          ),
          const SizedBox(height: 18),
          const CareSectionTitle(title: 'Privacy'),
          const SizedBox(height: 8),
          const CareCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Point(
                  icon: Icons.lock_outline_rounded,
                  text: 'Only your sign-in token and app settings are stored on this device, in the '
                      'encrypted keystore. Signing out deletes the token.',
                ),
                _Point(
                  icon: Icons.cloud_off_rounded,
                  text: 'Patient records are not saved on the phone. Every screen fetches them from the '
                      'hospital server and keeps them only while it is open.',
                ),
                _Point(
                  icon: Icons.visibility_off_outlined,
                  text: 'The app has no analytics, no advertising and no third-party trackers. It talks to '
                      'your hospital server and nothing else.',
                ),
                _Point(
                  icon: Icons.policy_outlined,
                  text: 'The records themselves are governed by your hospital\'s own privacy policy and the '
                      'consent you signed there.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const CareSectionTitle(title: 'Terms of use'),
          const SizedBox(height: 8),
          const CareCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Point(
                  icon: Icons.badge_outlined,
                  text: 'Accounts are issued by the hospital. Do not share a login -- every action is '
                      'recorded against the account that performed it.',
                ),
                _Point(
                  icon: Icons.medical_information_outlined,
                  text: 'The app shows and records clinical information. It does not give medical advice '
                      'and is not a substitute for clinical judgement.',
                ),
                _Point(
                  icon: Icons.report_gmailerrorred_outlined,
                  text: 'Report a lost or shared device to the hospital immediately so the session can be '
                      'revoked.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          CareCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Server', style: CareText.titleSm),
                const SizedBox(height: 4),
                // Worth showing: a support call usually starts with which
                // server the phone is pointed at.
                SelectableText(ApiService.baseUrl, style: CareText.mutedSm),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton.icon(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'HMS India',
                applicationVersion: _version,
              ),
              icon: const Icon(Icons.article_outlined, size: 18),
              label: const Text('Open-source licences', style: CareText.mutedSmMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Point({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: kCare),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: CareText.bodyMdMuted)),
        ],
      ),
    );
  }
}

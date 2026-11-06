import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/app_prefs.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/auth/screens/login_screen.dart';
import 'package:hms_mobile/features/common/screens/about_screen.dart';
import 'package:hms_mobile/features/common/screens/help_screen.dart';
import 'package:hms_mobile/features/settings/screens/appearance_screen.dart';

/// The app's own settings, as opposed to the hospital's.
///
/// Three rows are deliberately shown switched off rather than hidden:
/// alerts, language and text size. All are listed in the app plan, none
/// has anything behind it yet, and a switch that silently does nothing is
/// worse than one that says why it cannot.
class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final _auth = LocalAuthentication();
  bool _biometricAvailable = false;
  bool _checkingBiometrics = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    var available = false;
    try {
      // Supported *and* something enrolled: a phone with no fingerprint
      // registered would otherwise offer a lock nobody can open.
      available = await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (_) {
      available = false;
    }
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _checkingBiometrics = false;
      });
    }
  }

  Future<void> _toggleBiometric(AppPrefs prefs, bool value) async {
    if (!value) {
      await prefs.setBiometricLock(false);
      return;
    }

    // Prove the check works before turning it on, so nobody locks
    // themselves out of their own session.
    var ok = false;
    try {
      ok = await _auth.authenticate(
        localizedReason: 'Confirm it is you before turning on the lock',
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;
    if (!ok) {
      _say('The check did not pass, so the lock stays off.');
      return;
    }
    await prefs.setBiometricLock(true);
  }

  Future<void> _clearCache() async {
    final yes = await _confirm(
      title: 'Clear cached data?',
      message: 'Downloaded images are dropped and your app settings go back to their defaults. '
          'You stay signed in and nothing on the server changes.',
      confirmLabel: 'Clear',
    );
    if (!yes || !mounted) return;

    setState(() => _busy = true);
    // Photos and avatars the app has downloaded this session.
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await context.read<AppPrefs>().reset();
    if (!mounted) return;
    setState(() => _busy = false);
    _say('Cleared.');
  }

  Future<void> _logOut() async {
    final yes = await _confirm(
      title: 'Log out?',
      message: 'You will need your email and password to sign in again.',
      confirmLabel: 'Log out',
    );
    if (!yes || !mounted) return;

    setState(() => _busy = true);
    final storage = AuthStorage();
    final token = await storage.readToken();
    if (token != null) {
      try {
        await ApiService().logout(token);
      } catch (_) {
        // Offline logout still clears the device, which is the part
        // that matters on a shared phone.
      }
    }
    await storage.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<bool> _confirm({required String title, required String message, required String confirmLabel}) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: CareText.titleLg),
        content: Text(message, style: CareText.bodyMdMuted),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: CareText.mutedSmMedium),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: kDangerText, fontWeight: CareText.bold, fontSize: CareText.md),
            ),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  void _say(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: kCareDark, content: Text(message, style: const TextStyle(color: Colors.white))),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final prefs = context.watch<AppPrefs>();

    return Scaffold(
      appBar: carePageAppBar(context, 'Settings'),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const CareSectionTitle(title: 'Appearance'),
            const SizedBox(height: 8),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.palette_outlined,
                  title: 'Theme colour',
                  subtitle: 'Pick the colour the app is drawn in',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                  ),
                ),
                const _SettingsRow(
                  icon: Icons.translate_rounded,
                  title: 'Language',
                  subtitle: 'English only for now, until the app itself is translated',
                  enabled: false,
                ),
                const _SettingsRow(
                  icon: Icons.format_size_rounded,
                  title: 'Text size',
                  subtitle: 'Follows the display settings on your phone',
                  enabled: false,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const CareSectionTitle(title: 'Security'),
            const SizedBox(height: 8),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.fingerprint_rounded,
                  title: 'Unlock with biometrics',
                  subtitle: _checkingBiometrics
                      ? 'Checking what this phone supports...'
                      : _biometricAvailable
                          ? 'Ask for your fingerprint or face when the app opens'
                          : 'This phone has no fingerprint or face unlock set up',
                  enabled: _biometricAvailable,
                  trailing: Switch(
                    value: prefs.biometricLock,
                    activeTrackColor: kCare,
                    onChanged: _biometricAvailable ? (v) => _toggleBiometric(prefs, v) : null,
                  ),
                ),
                const _SettingsRow(
                  icon: Icons.notifications_none_rounded,
                  title: 'Alerts',
                  subtitle: 'Arrives with the notifications inbox, which the server does not serve yet',
                  enabled: false,
                  trailing: Switch(value: false, onChanged: null),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const CareSectionTitle(title: 'Storage'),
            const SizedBox(height: 8),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.cleaning_services_outlined,
                  title: 'Clear cached data',
                  subtitle: 'Drops downloaded images and resets app settings',
                  onTap: _clearCache,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const CareSectionTitle(title: 'About this app'),
            const SizedBox(height: 8),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  subtitle: 'Common questions and what to quote when reporting a problem',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpScreen())),
                ),
                _SettingsRow(
                  icon: Icons.info_outline_rounded,
                  title: 'About, privacy and terms',
                  subtitle: 'Version, what is stored on this phone, legal pages',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
                ),
              ],
            ),
            const SizedBox(height: 22),
            CarePrimaryButton(label: 'Log out', icon: Icons.logout_rounded, loading: _busy, onPressed: _logOut),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return CareCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool enabled;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: ListTile(
        onTap: enabled ? onTap : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CareRadius.field)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kCareSoft,
            borderRadius: BorderRadius.circular(CareRadius.control),
          ),
          child: Icon(icon, color: kCare, size: 20),
        ),
        title: Text(title, style: CareText.titleMd),
        subtitle: Text(subtitle, style: CareText.mutedXs),
        trailing: trailing ?? (enabled && onTap != null ? const Icon(Icons.chevron_right_rounded, color: kCareHint) : null),
      ),
    );
  }
}

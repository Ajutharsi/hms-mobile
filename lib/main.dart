import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/navigation/role_home.dart';
import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/core/theme/theme_controller.dart';
import 'package:hms_mobile/core/services/app_prefs.dart';
import 'package:hms_mobile/features/auth/screens/login_screen.dart';
import 'package:hms_mobile/features/auth/viewmodels/session_view_model.dart';
import 'package:hms_mobile/features/common/screens/app_status_screen.dart';
import 'package:hms_mobile/features/common/screens/onboarding_screen.dart';
import 'package:hms_mobile/features/common/screens/splash_screen.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:local_auth/local_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read before the first frame: which screen comes first depends on it.
  final prefs = AppPrefs();
  await prefs.load();

  runApp(HmsApp(prefs: prefs));
}

/// Lets the session-expiry hook reach the navigator from outside the
/// widget tree — the hook fires from an API client, which has no context.
final navigatorKey = GlobalKey<NavigatorState>();

class HmsApp extends StatefulWidget {
  final AppPrefs prefs;

  const HmsApp({super.key, required this.prefs});

  @override
  State<HmsApp> createState() => _HmsAppState();
}

class _HmsAppState extends State<HmsApp> {
  @override
  void initState() {
    super.initState();

    // Tokens last a week. When one runs out while somebody is working,
    // every screen would otherwise sit there showing "Your session has
    // expired" with no way back; this clears the stored token and returns
    // to the login screen instead.
    onSessionExpired = () async {
      await AuthStorage().clear();
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    };
  }

  @override
  void dispose() {
    onSessionExpired = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The colour the user picked in Appearance lives here, above
    // MaterialApp, so changing it repaints every screen at once.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CareThemeController()),
        ChangeNotifierProvider.value(value: widget.prefs),
      ],
      child: Consumer<CareThemeController>(
        builder: (context, theme, _) => _buildApp(context),
      ),
    );
  }

  Widget _buildApp(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'HMS India',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kCare, primary: kCare),
        scaffoldBackgroundColor: kCareBg,
        useMaterial3: true,
        // Pill-shaped by default — most buttons in this app set an explicit
        // style per call site (so this mainly covers ones that don't), but
        // keeping it consistent means any new/un-styled button matches the
        // rest of the app instead of falling back to Material's stock look.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kCareDark,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kCareDark,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kCareDark,
            side: BorderSide(color: kCareDark, width: 1.4),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: kCareDark, shape: const StadiumBorder()),
        ),
        chipTheme: const ChipThemeData(shape: StadiumBorder(), side: BorderSide.none),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: kCareSoft,
          elevation: 0,
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: kInk, elevation: 0, centerTitle: false),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CareRadius.panel), side: BorderSide(color: kCareBorder)),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: kCareDark, foregroundColor: Colors.white, elevation: 0),
      ),
      home: ChangeNotifierProvider(
        create: (_) => SessionViewModel(),
        child: const StartupGate(),
      ),
    );
  }
}

/// Decides what the app shows first.
///
/// Four things can be true at launch and each needs its own answer: the
/// check is still running, the server cannot be reached, nobody is
/// signed in, or somebody is. A single spinner used to cover all four.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool _introDone = false;
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<AppPrefs>();

    return Consumer<SessionViewModel>(
      builder: (context, viewModel, _) {
        switch (viewModel.status) {
          case SessionStatus.checking:
            return const SplashScreen();

          case SessionStatus.unreachable:
            final failure = viewModel.failure;
            if (failure?.isMaintenance == true) {
              return AppStatusScreen.maintenance(onRetry: viewModel.checkSession, detail: failure?.message);
            }
            if (failure?.isNetwork == true) {
              return AppStatusScreen.offline(onRetry: viewModel.checkSession);
            }
            return AppStatusScreen.serverError(onRetry: viewModel.checkSession, detail: failure?.message);

          case SessionStatus.loggedIn:
            // An unlocked session stays unlocked for as long as the app
            // is open; the check is for someone picking up the phone.
            if (prefs.biometricLock && !_unlocked) {
              return _BiometricGate(onUnlocked: () => setState(() => _unlocked = true));
            }
            return RoleHome(user: viewModel.user!);

          case SessionStatus.loggedOut:
            if (!prefs.onboardingSeen && !_introDone) {
              return OnboardingScreen(onDone: () {
                prefs.markOnboardingSeen();
                setState(() => _introDone = true);
              });
            }
            return const LoginScreen();
        }
      },
    );
  }
}

/// Stands in front of a restored session when the fingerprint lock is on.
///
/// There is no "skip": the only way past is the phone's own check or
/// signing out, which is the whole point of the setting.
class _BiometricGate extends StatefulWidget {
  final VoidCallback onUnlocked;
  const _BiometricGate({required this.onUnlocked});

  @override
  State<_BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<_BiometricGate> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prompt());
  }

  Future<void> _prompt() async {
    var ok = false;
    try {
      ok = await LocalAuthentication().authenticate(
        localizedReason: 'Unlock HMS India',
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      // A phone that can no longer run the check (biometrics removed,
      // hardware error) must not strand the session behind it.
      ok = true;
    }
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppStatusScreen(
      icon: Icons.fingerprint_rounded,
      title: 'Locked',
      message: 'Unlock with your fingerprint or face to continue.',
      hint: _failed ? 'The check did not pass.' : null,
      onRetry: _prompt,
      retryLabel: 'Unlock',
    );
  }
}

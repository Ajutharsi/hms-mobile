import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/navigation/role_home.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/core/theme/theme_controller.dart';
import 'package:hms_mobile/features/auth/screens/login_screen.dart';
import 'package:hms_mobile/features/auth/viewmodels/session_view_model.dart';

void main() {
  runApp(const HmsApp());
}

class HmsApp extends StatelessWidget {
  const HmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The colour the user picked in Appearance lives here, above
    // MaterialApp, so changing it repaints every screen at once.
    return ChangeNotifierProvider(
      create: (_) => CareThemeController(),
      child: Consumer<CareThemeController>(
        builder: (context, theme, _) => _buildApp(context),
      ),
    );
  }

  Widget _buildApp(BuildContext context) {
    return MaterialApp(
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: kCareBorder)),
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

/// Renders the splash spinner while [SessionViewModel] checks for a saved,
/// still-valid login, then routes to Home or Login accordingly.
class StartupGate extends StatelessWidget {
  const StartupGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionViewModel>(
      builder: (context, viewModel, _) {
        switch (viewModel.status) {
          case SessionStatus.checking:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          case SessionStatus.loggedIn:
            return RoleHome(user: viewModel.user!);
          case SessionStatus.loggedOut:
            return const LoginScreen();
        }
      },
    );
  }
}

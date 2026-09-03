import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/navigation/role_home.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/auth/screens/login_screen.dart';
import 'package:hms_mobile/features/auth/viewmodels/session_view_model.dart';

void main() {
  runApp(const HmsApp());
}

class HmsApp extends StatelessWidget {
  const HmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HMS India',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kTealDark),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        // Pill-shaped by default — most buttons in this app set an explicit
        // style per call site (so this mainly covers ones that don't), but
        // keeping it consistent means any new/un-styled button matches the
        // rest of the app instead of falling back to Material's stock look.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kTealDark,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kTealDark,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kTealDark,
            side: const BorderSide(color: kTealDark, width: 1.4),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: kTealDark, shape: const StadiumBorder()),
        ),
        chipTheme: const ChipThemeData(shape: StadiumBorder(), side: BorderSide.none),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: kMint,
          elevation: 0,
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: kInk, elevation: 0, centerTitle: false),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: kFieldFill)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: kTealDark, foregroundColor: Colors.white, elevation: 0),
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

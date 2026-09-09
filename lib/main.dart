import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final baseTextTheme = ThemeData(useMaterial3: true).textTheme;
    // Applied once here rather than per-widget: every `Text`/`TextStyle` in
    // the app that doesn't set its own `fontFamily` (i.e. all of them)
    // inherits this through `DefaultTextStyle`, so the whole app retypes
    // in one place instead of 90-odd screen edits.
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme).apply(bodyColor: kInk, displayColor: kInk);

    return MaterialApp(
      title: 'HMS India',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kTealDark),
        scaffoldBackgroundColor: kBg,
        useMaterial3: true,
        textTheme: textTheme,
        primaryTextTheme: textTheme,
        // Pill-shaped by default — most buttons in this app set an explicit
        // style per call site (so this mainly covers ones that don't), but
        // keeping it consistent means any new/un-styled button matches the
        // rest of the app instead of falling back to Material's stock look.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kTealDark,
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kTealDark,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kTealDark,
            side: const BorderSide(color: kTealDark, width: 1.4),
            textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: kTealDark,
            textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            shape: const StadiumBorder(),
          ),
        ),
        chipTheme: const ChipThemeData(shape: StadiumBorder(), side: BorderSide.none),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: kMint,
          elevation: 0,
          labelTextStyle: WidgetStatePropertyAll(GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: kBg,
          foregroundColor: kInk,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.plusJakartaSans(color: kInk, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: kBorder)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: kCoral, foregroundColor: Colors.white, elevation: 0),
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

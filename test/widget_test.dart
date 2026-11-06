import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hms_mobile/core/services/app_prefs.dart';
import 'package:hms_mobile/features/common/screens/splash_screen.dart';
import 'package:hms_mobile/main.dart';

void main() {
  // SessionViewModel reads a token from flutter_secure_storage on startup;
  // its platform channel isn't wired up in a widget test, so mock it to
  // resolve cleanly instead of throwing.
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async => null);

  testWidgets('App builds and shows the branded splash on startup', (WidgetTester tester) async {
    await tester.pumpWidget(HmsApp(prefs: AppPrefs()));

    expect(find.byType(HmsApp), findsOneWidget);
    // Not a bare spinner any more: the name is on screen while the
    // saved session is checked.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('HMS India'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

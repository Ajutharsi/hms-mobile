import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hms_mobile/main.dart';

void main() {
  // SessionViewModel reads a token from flutter_secure_storage on startup;
  // its platform channel isn't wired up in a widget test, so mock it to
  // resolve cleanly instead of throwing.
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async => null);

  testWidgets('App builds and shows the splash gate on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const HmsApp());

    expect(find.byType(HmsApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

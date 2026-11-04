import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hms_mobile/core/theme/care_ui.dart';

/// The nurse and receptionist screens now share one loading / error /
/// empty state with the patient and doctor screens. Two shapes exist
/// because a screen with stat tiles above its list cannot replace the
/// whole body — these tests pin the difference, since using the wrong
/// one fails at runtime rather than at compile time.
void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('the scrollable state view works as a RefreshIndicator child', (tester) async {
    await tester.pumpWidget(host(RefreshIndicator(
      onRefresh: () async {},
      child: const CareStateView(icon: Icons.inbox_rounded, title: 'Nothing here', message: 'It will show up once there is some.'),
    )));

    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('It will show up once there is some.'), findsOneWidget);
    // Pull-to-refresh only reaches the user if the empty state scrolls.
    expect(find.byType(Scrollable), findsWidgets);
    await tester.fling(find.text('Nothing here'), const Offset(0, 200), 1000);
    await tester.pumpAndSettle();
  });

  testWidgets('the inline state view can sit inside a list', (tester) async {
    // This is the case that matters: dropping the scrollable version in
    // here would throw on an unbounded height.
    await tester.pumpWidget(host(ListView(
      children: const [
        SizedBox(height: 60, child: Text('stats')),
        CareStateView.inline(icon: Icons.receipt_long_outlined, title: 'No invoices found', message: 'Invoices you create will be listed here.'),
      ],
    )));

    expect(tester.takeException(), isNull);
    expect(find.text('stats'), findsOneWidget);
    expect(find.text('No invoices found'), findsOneWidget);
  });

  testWidgets('the error state names the failure it was given', (tester) async {
    await tester.pumpWidget(host(CareStateView.error('Network unreachable')));

    expect(find.text("Couldn't load"), findsOneWidget);
    expect(find.text('Network unreachable'), findsOneWidget);
  });

  testWidgets('the loading state shows a spinner and no title', (tester) async {
    await tester.pumpWidget(host(const CareStateView.loading()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(''), findsNothing);
  });
}

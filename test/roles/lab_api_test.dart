import 'package:flutter_test/flutter_test.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/features/lab/services/lab_api_service.dart';

import '../support/api_harness.dart';

void main() {
  group('lab assistant', () {
    test('parses the dashboard the server actually sends', () async {
      final http = respondingWith(fixture('lab_dashboard'));
      final stats = await LabApiService(client: http.client).dashboard('tok');

      final expected = fixtureJson('lab_dashboard')['stats'] as Map<String, dynamic>;
      expect(stats.pendingOrders, expected['pending_orders']);
      expect(stats.completedToday, expected['completed_today']);
      expect(stats.totalOrders, expected['total_orders']);
      expect(stats.labTests, expected['lab_tests']);
    });

    test('asks the right path and carries the token', () async {
      final http = respondingWith(fixture('lab_dashboard'));
      await LabApiService(client: http.client).dashboard('secret-token');

      expect(http.seen.single.url.path, '/api/lab/dashboard');
      expect(http.seen.single.bearer, 'secret-token');
    });

    test('a rejected token is reported as an expired session', () async {
      await expectLater(
        LabApiService(client: failingWith(401).client).dashboard('stale'),
        throwsA(isA<ApiException>().having((e) => e.isUnauthenticated, 'isUnauthenticated', isTrue)),
      );
    });

    test('maintenance reaches the lab too', () async {
      await expectLater(
        LabApiService(client: failingWith(503).client).dashboard('tok'),
        throwsA(isA<ApiException>().having((e) => e.isMaintenance, 'isMaintenance', isTrue)),
      );
    });

    test('a role the server refuses keeps the server wording', () async {
      await expectLater(
        LabApiService(client: failingWith(403, message: 'This account is not a lab account.').client)
            .dashboard('tok'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'This account is not a lab account.')
            .having((e) => e.isUnauthenticated, 'isUnauthenticated', isFalse)),
      );
    });
  });
}

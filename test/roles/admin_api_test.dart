import 'package:flutter_test/flutter_test.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/features/admin/services/admin_api_service.dart';

import '../support/api_harness.dart';

void main() {
  group('admin', () {
    test('parses the dashboard the server actually sends', () async {
      final http = respondingWith(fixture('admin_dashboard'));
      final dashboard = await AdminApiService(client: http.client).dashboard('tok');

      final json = fixtureJson('admin_dashboard');
      final appointments = json['appointments'] as Map<String, dynamic>;
      final capacity = json['capacity'] as Map<String, dynamic>;
      expect(dashboard.appointmentsTotal, appointments['total']);
      expect(dashboard.appointmentsScheduled, appointments['scheduled']);
      expect(dashboard.appointmentsCancelled, appointments['cancelled']);
      expect(dashboard.doctors, capacity['doctors']);
    });

    test('asks the right path and carries the token', () async {
      final http = respondingWith(fixture('admin_dashboard'));
      await AdminApiService(client: http.client).dashboard('secret-token');

      expect(http.seen.single.url.path, '/api/admin/dashboard');
      expect(http.seen.single.bearer, 'secret-token');
    });

    test('a rejected token is reported as an expired session', () async {
      await expectLater(
        AdminApiService(client: failingWith(401).client).dashboard('stale'),
        throwsA(isA<ApiException>().having((e) => e.isUnauthenticated, 'isUnauthenticated', isTrue)),
      );
    });

    test('maintenance reaches the administrator too', () async {
      await expectLater(
        AdminApiService(client: failingWith(503).client).dashboard('tok'),
        throwsA(isA<ApiException>().having((e) => e.isMaintenance, 'isMaintenance', isTrue)),
      );
    });

    test('a missing endpoint does not show the route name to an administrator', () async {
      await expectLater(
        AdminApiService(
          client: failingWith(404, message: 'The route api/admin/dashboard could not be found.').client,
        ).dashboard('tok'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', isNot(contains('route')))),
      );
    });
  });
}

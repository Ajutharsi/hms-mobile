import 'package:flutter_test/flutter_test.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/features/receptionist/services/receptionist_api_service.dart';

import '../support/api_harness.dart';

void main() {
  group('receptionist', () {
    test('parses the dashboard the server actually sends', () async {
      final http = respondingWith(fixture('reception_dashboard'));
      final (stats, today, recent) =
          await ReceptionistApiService(client: http.client).dashboard('tok');

      final json = fixtureJson('reception_dashboard');
      final expected = json['stats'] as Map<String, dynamic>;
      expect(stats.totalPatients, expected['total_patients']);
      expect(stats.todayAppointments, expected['today_appointments']);
      expect(stats.pendingInvoices, expected['pending_invoices']);
      expect(stats.availableBeds, expected['available_beds']);
      expect(today.length, (json['today_appointments'] as List).length);
      expect(recent.length, (json['recent_patients'] as List).length);
    });

    test('asks the right path and carries the token', () async {
      final http = respondingWith(fixture('reception_dashboard'));
      await ReceptionistApiService(client: http.client).dashboard('secret-token');

      expect(http.seen.single.url.path, '/api/receptionist/dashboard');
      expect(http.seen.single.bearer, 'secret-token');
    });

    test('the patient search sends its term as q, which is what the server reads', () async {
      final http = respondingWith('{"patients": []}');
      await ReceptionistApiService(client: http.client).patients('tok', q: 'HMS-2026-1005');

      expect(http.seen.single.url.queryParameters['q'], 'HMS-2026-1005');
    });

    test('a rejected token is reported as an expired session', () async {
      await expectLater(
        ReceptionistApiService(client: failingWith(401).client).dashboard('stale'),
        throwsA(isA<ApiException>().having((e) => e.isUnauthenticated, 'isUnauthenticated', isTrue)),
      );
    });

    test('maintenance reaches the front desk too', () async {
      await expectLater(
        ReceptionistApiService(client: failingWith(503).client).dashboard('tok'),
        throwsA(isA<ApiException>().having((e) => e.isMaintenance, 'isMaintenance', isTrue)),
      );
    });
  });

  group('admin on the reception profile', () {
    test('the prefix decides the endpoint, so an admin does not post to /receptionist', () async {
      final http = respondingWith(fixture('reception_profile'));
      await ReceptionistApiService(client: http.client).profile('tok', prefix: '/admin');

      expect(http.seen.single.url.path, '/api/admin/profile');
    });

    test('and the front desk still gets its own', () async {
      final http = respondingWith(fixture('reception_profile'));
      await ReceptionistApiService(client: http.client).profile('tok');

      expect(http.seen.single.url.path, '/api/receptionist/profile');
    });
  });
}

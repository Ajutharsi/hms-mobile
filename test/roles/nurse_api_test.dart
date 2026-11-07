import 'package:flutter_test/flutter_test.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/features/nurse/services/nurse_api_service.dart';

import '../support/api_harness.dart';

void main() {
  group('nurse', () {
    test('parses the dashboard the server actually sends', () async {
      final http = respondingWith(fixture('nurse_dashboard'));
      final (stats, today, recent) = await NurseApiService(client: http.client).dashboard('tok');

      final json = fixtureJson('nurse_dashboard');
      final expected = json['stats'] as Map<String, dynamic>;
      expect(stats.ipPatients, expected['ip_patients']);
      expect(stats.pendingMedications, expected['pending_medications']);
      expect(stats.overdueRounds, expected['overdue_rounds']);
      expect(today.length, (json['today_appointments'] as List).length);
      expect(recent.length, (json['recent_patients'] as List).length);
    });

    test('asks the right path and carries the token', () async {
      final http = respondingWith(fixture('nurse_dashboard'));
      await NurseApiService(client: http.client).dashboard('secret-token');

      expect(http.seen.single.url.path, '/api/nurse/dashboard');
      expect(http.seen.single.bearer, 'secret-token');
    });

    test('a rejected token is reported as an expired session', () async {
      await expectLater(
        NurseApiService(client: failingWith(401).client).dashboard('stale'),
        throwsA(isA<ApiException>().having((e) => e.isUnauthenticated, 'isUnauthenticated', isTrue)),
      );
    });

    test('an unreachable server reads as a connection problem, not a server error', () async {
      await expectLater(
        guardNetworkErrors(() => NurseApiService(client: unreachable()).dashboard('tok')),
        throwsA(isA<ApiException>().having((e) => e.isNetwork, 'isNetwork', isTrue)),
      );
    });

    test('maintenance is told apart from an ordinary failure', () async {
      await expectLater(
        NurseApiService(client: failingWith(503, message: 'Back at 6pm.').client).dashboard('tok'),
        throwsA(isA<ApiException>().having((e) => e.isMaintenance, 'isMaintenance', isTrue)),
      );
    });
  });

  group('staff', () {
    test('parses its own dashboard, which rides on the nurse client', () async {
      final http = respondingWith(fixture('staff_dashboard'));
      final (stats, patients) = await NurseApiService(client: http.client).staffDashboard('tok');

      final json = fixtureJson('staff_dashboard');
      final expected = json['stats'] as Map<String, dynamic>;
      expect(stats.myAssignedWards, expected['my_assigned_wards']);
      expect(stats.overdueRounds, expected['overdue_rounds']);
      expect(patients.length, (json['recent_patients'] as List).length);
      expect(http.seen.single.url.path, '/api/staff/dashboard');
    });
  });
}

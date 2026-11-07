import 'package:flutter_test/flutter_test.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/features/pharmacy/services/pharmacy_api_service.dart';

import '../support/api_harness.dart';

void main() {
  group('pharmacist', () {
    test('parses the dashboard the server actually sends', () async {
      final http = respondingWith(fixture('pharmacy_dashboard'));
      final stats = await PharmacyApiService(client: http.client).dashboard('tok');

      final expected = fixtureJson('pharmacy_dashboard')['stats'] as Map<String, dynamic>;
      expect(stats.totalDrugs, expected['total_drugs']);
      expect(stats.lowStock, expected['low_stock']);
      expect(stats.nearExpiry, expected['near_expiry']);
      expect(stats.dispensedToday, expected['dispensed_today']);
    });

    test('asks the right path and carries the token', () async {
      final http = respondingWith(fixture('pharmacy_dashboard'));
      await PharmacyApiService(client: http.client).dashboard('secret-token');

      expect(http.seen.single.url.path, '/api/pharmacy/dashboard');
      expect(http.seen.single.bearer, 'secret-token');
    });

    test('the drug search sends its term as a query, not a body', () async {
      final http = respondingWith('{"drugs": []}');
      await PharmacyApiService(client: http.client).drugs('tok', q: 'paracetamol');

      final sent = http.seen.single;
      expect(sent.method, 'GET');
      expect(sent.url.queryParameters['q'], 'paracetamol');
    });

    test('a rejected token is reported as an expired session', () async {
      await expectLater(
        PharmacyApiService(client: failingWith(401).client).dashboard('stale'),
        throwsA(isA<ApiException>().having((e) => e.isUnauthenticated, 'isUnauthenticated', isTrue)),
      );
    });

    test('maintenance reaches the pharmacy too', () async {
      await expectLater(
        PharmacyApiService(client: failingWith(503).client).dashboard('tok'),
        throwsA(isA<ApiException>().having((e) => e.isMaintenance, 'isMaintenance', isTrue)),
      );
    });
  });
}

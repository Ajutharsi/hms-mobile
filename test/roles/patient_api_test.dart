import 'package:flutter_test/flutter_test.dart';

import 'package:hms_mobile/core/models/app_user.dart';
import 'package:hms_mobile/core/services/api_service.dart';

import '../support/api_harness.dart';

void main() {
  group('patient', () {
    test('parses its own profile the way the server sends it', () async {
      final http = respondingWith(fixture('patient_profile'));
      final profile = await ApiService(client: http.client).getProfile('tok');

      final user = fixtureJson('patient_profile')['user'] as Map<String, dynamic>;
      expect(profile.name, user['name']);
      expect(profile.email, user['email']);
      expect(http.seen.single.url.path, '/api/patient/profile');
      expect(http.seen.single.bearer, 'tok');
    });

    test('an empty list of appointments is a list, not a crash', () async {
      final http = respondingWith(fixture('patient_appointments'));
      final appointments = await ApiService(client: http.client).getAppointments('tok');

      expect(appointments, isEmpty);
    });

    test('a rejected token is reported as an expired session', () async {
      await expectLater(
        ApiService(client: failingWith(401).client).getAppointments('stale'),
        throwsA(isA<ApiException>().having((e) => e.isUnauthenticated, 'isUnauthenticated', isTrue)),
      );
    });

    test('maintenance is told apart from an ordinary failure', () async {
      await expectLater(
        ApiService(client: failingWith(503, message: 'Back at 6pm.').client).getAppointments('tok'),
        throwsA(isA<ApiException>()
            .having((e) => e.isMaintenance, 'isMaintenance', isTrue)
            .having((e) => e.message, 'message', 'Back at 6pm.')),
      );
    });

    test('a validation error shows the field message, not a generic one', () async {
      const body = '{"message":"Invalid.","errors":{"email":["This email is already registered."]}}';
      final http = respondingWith(body, status: 422);

      await expectLater(
        ApiService(client: http.client).register(
          name: 'A', email: 'a@b.c', password: 'secret12',
          passwordConfirmation: 'secret12', deviceName: 'test', gender: 'male',
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'This email is already registered.')),
      );
    });
  });

  group('the signed-in account', () {
    test('carries the hospital the server reports', () {
      final user = AppUser.fromJson(fixtureJson('me_admin'));

      expect(user.roles, isNotEmpty);
      expect(user.currency, isNotNull);
      expect(user.hospitalName, isNotNull);
    });

    test('an older server that sends no hospital block still parses', () {
      final user = AppUser.fromJson({
        'id': 1, 'name': 'A', 'email': 'a@b.c', 'roles': ['patient'],
        'must_change_password': false,
      });

      expect(user.currency, isNull);
      expect(user.hospitalName, isNull);
      expect(user.primaryRole, 'patient');
    });
  });
}

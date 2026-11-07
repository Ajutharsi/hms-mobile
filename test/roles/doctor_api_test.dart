import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/features/doctor/services/doctor_api_service.dart';

import '../support/api_harness.dart';

void main() {
  group('doctor', () {
    test('parses the dashboard the server actually sends', () async {
      final http = respondingWith(fixture('doctor_dashboard'));
      final result = await DoctorApiService(client: http.client).dashboard('tok');

      final expected = fixtureJson('doctor_dashboard')['stats'] as Map<String, dynamic>;
      expect(result.stats.myAppointments, expected['my_appointments']);
      expect(result.stats.prescriptions, expected['prescriptions']);
      expect(result.stats.labOrders, expected['lab_orders']);
      expect(result.stats.pendingRadiology, expected['pending_radiology']);
      expect(result.recentPatients.length,
          (fixtureJson('doctor_dashboard')['recent_patients'] as List).length);
    });

    test('asks the right path and carries the token', () async {
      final http = respondingWith(fixture('doctor_dashboard'));
      await DoctorApiService(client: http.client).dashboard('secret-token');

      expect(http.seen, hasLength(1));
      expect(http.seen.single.url.path, '/api/doctor/dashboard');
      expect(http.seen.single.bearer, 'secret-token');
    });

    test('a rejected token is reported as an expired session', () async {
      final http = failingWith(401);
      await expectLater(
        DoctorApiService(client: http.client).dashboard('stale'),
        throwsA(isA<ApiException>().having((e) => e.isUnauthenticated, 'isUnauthenticated', isTrue)),
      );
    });

    test('a missing endpoint does not show the route name to the doctor', () async {
      final http = failingWith(404, message: 'The route api/doctor/dashboard could not be found.');
      await expectLater(
        DoctorApiService(client: http.client).dashboard('tok'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', isNot(contains('route')))
            .having((e) => e.message, 'message', contains('not available'))),
      );
    });

    test('a profile save with a picture goes up as multipart', () async {
      final http = respondingWith(fixture('doctor_profile'));
      await DoctorApiService(client: http.client).updateProfile(
        'tok',
        name: 'Dr. Kumar',
        email: 'doctor@hospital.com',
        photoBytes: Uint8List.fromList([1, 2, 3]),
        photoFilename: 'face.jpg',
      );

      final sent = http.seen.single;
      expect(sent.method, 'POST');
      expect(sent.url.path, '/api/doctor/profile');
      expect(sent.headers['content-type'], startsWith('multipart/form-data'));
      expect(sent.body, contains('face.jpg'));
    });

    test('a profile save without one stays JSON', () async {
      final http = respondingWith('{}');
      await DoctorApiService(client: http.client)
          .updateProfile('tok', name: 'Dr. Kumar', email: 'doctor@hospital.com');

      expect(http.seen.single.headers['Content-Type'], contains('application/json'));
    });
  });
}

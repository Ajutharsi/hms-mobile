import 'package:flutter_test/flutter_test.dart';

import 'package:hms_mobile/core/services/api_service.dart';

void main() {
  group('what the server says vs what the person reads', () {
    test('a 404 never leaks the route name', () {
      const laravel = 'The route api/admin/payroll could not be found.';
      final shown = serverErrorMessage(404, laravel);

      expect(shown, isNot(contains('api/')));
      expect(shown, isNot(contains('route')));
      expect(shown, contains('not available'));
    });

    test('a 405 points at the app being old rather than at the HTTP verb', () {
      final shown = serverErrorMessage(405, 'The GET method is not supported for route api/login.');

      expect(shown, isNot(contains('GET')));
      expect(shown, contains('out of date'));
    });

    test('a 500 does not ask anyone to check their connection', () {
      final shown = serverErrorMessage(500, 'Server Error');

      expect(shown, contains('server'));
      expect(shown, isNot(contains('connection')));
    });

    test('403 and 429 keep the wording the server chose, which is the useful one', () {
      expect(serverErrorMessage(403, 'This account is not a nurse account.'),
          'This account is not a nurse account.');
      expect(serverErrorMessage(429, 'Too many login attempts.'), 'Too many login attempts.');
    });

    test('an unknown status still names itself, so a bug report can quote it', () {
      expect(serverErrorMessage(418, null), contains('418'));
    });

    test('maintenance carries its flag as well as its wording', () {
      final failure = serverFailure(503, 'Back at 6pm.');

      expect(failure.isMaintenance, isTrue);
      expect(failure.message, 'Back at 6pm.');
    });

    test('a 401 is an expired session whichever client meets it', () {
      expect(serverFailure(401, null).isUnauthenticated, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:hms_mobile/core/services/api_service.dart';

void main() {
  test('the dev fallback is recognised as unencrypted', () {
    // No --dart-define=API_URL in a test run, so baseUrl is the local dev
    // server. What matters here is that isInsecure actually notices http —
    // it is what gates the warning on the login screen of a release build.
    expect(ApiService.baseUrl, startsWith('http://'));
    expect(ApiService.isInsecure, isTrue);
    expect(Uri.parse(ApiService.baseUrl).host, isNotEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:hms_mobile/core/services/current_user.dart';
import 'package:hms_mobile/core/services/hospital_settings.dart';

void main() {
  setUp(() {
    rememberHospital(currency: 'LKR', name: 'Hospital MS');
    forgetMyPhoto();
  });

  group('money', () {
    test('follows the hospital, which is not always India', () {
      rememberHospital(currency: 'LKR');
      expect(money(1200), 'Rs1200');

      rememberHospital(currency: 'INR');
      expect(money(1200), '\u20B91200');

      rememberHospital(currency: 'USD');
      expect(money(1200), '\u00241200');
    });

    test('a currency with no symbol shows its code rather than a wrong sign', () {
      rememberHospital(currency: 'XOF');
      expect(money(50), 'XOF50');
    });

    test('decimals are opt-in, because a dashboard headline does not want them', () {
      rememberHospital(currency: 'INR');
      expect(money(1234.56), '\u20B91235');
      expect(money(1234.56, decimals: 2), '\u20B91234.56');
    });

    test('a null amount reads as zero instead of crashing a bill', () {
      expect(money(null), 'Rs0');
      expect(money(null, decimals: 2), 'Rs0.00');
    });

    test('a blank or missing currency leaves the last good one alone', () {
      rememberHospital(currency: 'INR');
      rememberHospital(currency: '');
      rememberHospital(currency: null);
      expect(hospitalCurrency.value, 'INR');
    });

    test('the code is normalised, so lkr and LKR are the same hospital', () {
      rememberHospital(currency: 'lkr');
      expect(hospitalCurrency.value, 'LKR');
      expect(money(5), 'Rs5');
    });
  });

  group('the signed-in user\'s picture', () {
    test('a new one reaches every listener', () {
      var notified = 0;
      void listener() => notified++;
      myPhotoUrl.addListener(listener);
      addTearDown(() => myPhotoUrl.removeListener(listener));

      rememberMyPhoto('https://example.test/a.jpg');
      expect(myPhotoUrl.value, 'https://example.test/a.jpg');
      expect(notified, 1);
    });

    test('setting the same one again does not repaint the shells', () {
      rememberMyPhoto('https://example.test/a.jpg');

      var notified = 0;
      void listener() => notified++;
      myPhotoUrl.addListener(listener);
      addTearDown(() => myPhotoUrl.removeListener(listener));

      rememberMyPhoto('https://example.test/a.jpg');
      expect(notified, 0);
    });

    test('signing out clears it, so the next account has its own face', () {
      rememberMyPhoto('https://example.test/a.jpg');
      forgetMyPhoto();
      expect(myPhotoUrl.value, isNull);
    });
  });
}

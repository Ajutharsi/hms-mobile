import 'package:flutter_test/flutter_test.dart';

import 'package:hms_mobile/core/models/json_value.dart';
import 'package:hms_mobile/features/nurse/models/nurse_vital.dart';
import 'package:hms_mobile/features/patient/models/invoice.dart';

/// MySQL decimals come back as JSON strings, so every model that reads a
/// decimal has to accept both shapes. A plain `as num?` threw here, and
/// the Vitals screen reported it as "could not reach the server".
void main() {
  test('numbers are read from either a number or a string', () {
    expect(asNum(98.2), 98.2);
    expect(asNum('98.2'), 98.2);
    expect(asNum(' 61.00 '), 61);
    expect(asNum(null), isNull);
    expect(asNum('not a number'), isNull);
    expect(asDoubleOr(null), 0);
    expect(asDoubleOr('12.5'), 12.5);
    expect(asDoubleOr(null, 1), 1);
  });

  test('a vital parses with decimals sent as strings', () {
    final vital = NurseVital.fromJson({
      'id': 2,
      'patient_id': 1,
      'patient_name': 'Julie Nayar',
      'patient_mrn': 'HMS-2026-0001',
      'blood_pressure': '118/62',
      'temperature': '98.2',
      'pulse_rate': 105,
      'respiratory_rate': 18,
      'spo2': null,
      'weight': '61.00',
      'height': null,
      'news_score': null,
      'notes': null,
      'recorded_at': '2026-09-17T15:25:34.000000Z',
    });

    expect(vital.temperature, 98.2);
    expect(vital.weight, 61);
    expect(vital.height, isNull);
    expect(vital.spo2, isNull);
  });

  test('an invoice parses with money sent as strings', () {
    final invoice = Invoice.fromJson({
      'id': 7,
      'invoice_no': 'INV-2026-0007',
      'date': '2026-09-30',
      'status': 'partial',
      'total': '1500.00',
      'paid_amount': '500.00',
      'balance': '1000.00',
      'items': [],
    });

    expect(invoice.total, 1500);
    expect(invoice.paidAmount, 500);
    expect(invoice.balance, 1000);
    expect(invoice.hasBalance, isTrue);
  });
}

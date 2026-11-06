import 'package:hms_mobile/core/models/json_value.dart';

/// One thing that has been ordered for a patient, whatever kind it is.
class DoctorOrderRow {
  /// 'lab', 'radiology', 'medicine' or 'diet'.
  final String kind;
  final int id;
  final String title;
  final String? detail;
  final String? status;
  final String? date;

  const DoctorOrderRow({
    required this.kind,
    required this.id,
    required this.title,
    this.detail,
    this.status,
    this.date,
  });

  factory DoctorOrderRow.fromJson(Map<String, dynamic> j) => DoctorOrderRow(
        kind: j['kind']?.toString() ?? '',
        id: asIntOr(j['id']),
        title: j['title']?.toString() ?? '',
        detail: j['detail']?.toString(),
        status: j['status']?.toString(),
        date: j['date']?.toString(),
      );
}

class DoctorOrderBoard {
  final int patientId;
  final String patientName;
  final String patientMrn;

  /// False when this doctor has no consultation for the patient, which
  /// is what a prescription has to hang off.
  final bool canPrescribe;

  final List<DoctorOrderRow> orders;

  const DoctorOrderBoard({
    required this.patientId,
    required this.patientName,
    required this.patientMrn,
    required this.canPrescribe,
    required this.orders,
  });

  factory DoctorOrderBoard.fromJson(Map<String, dynamic> j) {
    final patient = (j['patient'] as Map?)?.cast<String, dynamic>() ?? const {};
    return DoctorOrderBoard(
      patientId: asIntOr(patient['id']),
      patientName: patient['name']?.toString() ?? 'Patient',
      patientMrn: patient['mrn']?.toString() ?? '',
      canPrescribe: j['can_prescribe'] == true,
      orders: ((j['orders'] as List?) ?? const [])
          .map((o) => DoctorOrderRow.fromJson((o as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

/// A test from the lab's catalogue, as the order form shows it.
class OrderableTest {
  final int id;
  final String name;
  final String? category;
  final String? sampleType;
  final double price;

  const OrderableTest({
    required this.id,
    required this.name,
    this.category,
    this.sampleType,
    required this.price,
  });

  factory OrderableTest.fromJson(Map<String, dynamic> j) => OrderableTest(
        id: asIntOr(j['id']),
        name: j['test_name']?.toString() ?? '',
        category: j['category']?.toString(),
        sampleType: j['sample_type']?.toString(),
        price: asDoubleOr(j['price']),
      );
}

import 'package:hms_mobile/core/models/json_value.dart';
import 'package:hms_mobile/features/pharmacy/models/drug.dart';

class Dispensing {
  final int id;
  final String? dispensingNo;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final String? prescriptionNo;
  final double totalAmount;
  final String status;
  final int itemsCount;
  final String? dispensedDate;

  const Dispensing({
    required this.id,
    this.dispensingNo,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    this.prescriptionNo,
    required this.totalAmount,
    required this.status,
    required this.itemsCount,
    this.dispensedDate,
  });

  factory Dispensing.fromJson(Map<String, dynamic> json) => Dispensing(
        id: json['id'] as int,
        dispensingNo: json['dispensing_no']?.toString(),
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        prescriptionNo: json['prescription_no']?.toString(),
        totalAmount: asDoubleOr(json['total_amount'], 0),
        status: json['status']?.toString() ?? 'dispensed',
        itemsCount: json['items_count'] as int? ?? 0,
        dispensedDate: json['dispensed_date']?.toString(),
      );
}

class DispensingItem {
  final String medicineName;
  final int? quantityPrescribed;
  final int quantityDispensed;
  final double unitPrice;
  final double totalPrice;

  const DispensingItem({
    required this.medicineName,
    this.quantityPrescribed,
    required this.quantityDispensed,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory DispensingItem.fromJson(Map<String, dynamic> json) => DispensingItem(
        medicineName: json['medicine_name']?.toString() ?? '',
        quantityPrescribed: json['quantity_prescribed'] as int?,
        quantityDispensed: json['quantity_dispensed'] as int? ?? 0,
        unitPrice: asDoubleOr(json['unit_price'], 0),
        totalPrice: asDoubleOr(json['total_price'], 0),
      );
}

class DispensingDetail extends Dispensing {
  final String? notes;
  final String? dispensedByName;
  final List<DispensingItem> items;

  const DispensingDetail({
    required super.id,
    super.dispensingNo,
    required super.patientId,
    super.patientName,
    super.patientMrn,
    super.prescriptionNo,
    required super.totalAmount,
    required super.status,
    super.dispensedDate,
    this.notes,
    this.dispensedByName,
    required this.items,
  }) : super(itemsCount: 0);

  factory DispensingDetail.fromJson(Map<String, dynamic> json) => DispensingDetail(
        id: json['id'] as int,
        dispensingNo: json['dispensing_no']?.toString(),
        patientId: json['patient_id'] as int? ?? 0,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        prescriptionNo: json['prescription_no']?.toString(),
        totalAmount: asDoubleOr(json['total_amount'], 0),
        status: json['status']?.toString() ?? 'dispensed',
        dispensedDate: json['dispensed_date']?.toString(),
        notes: json['notes']?.toString(),
        dispensedByName: json['dispensed_by_name']?.toString(),
        items: (json['items'] as List? ?? []).map((i) => DispensingItem.fromJson(i as Map<String, dynamic>)).toList(),
      );
}

class DispensingAlerts {
  final List<Drug> lowStock;
  final List<Drug> nearExpiry;
  final List<Drug> expired;

  const DispensingAlerts({required this.lowStock, required this.nearExpiry, required this.expired});
}

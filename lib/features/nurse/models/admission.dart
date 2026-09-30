import 'package:hms_mobile/core/models/json_value.dart';

class Admission {
  final int id;
  final String? admissionNo;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final String? patientPhotoUrl;
  final String? wardName;
  final String? bedNo;
  final String? doctorName;
  final String? admissionDate;
  final String? dischargeDate;
  final String status;
  final double totalCharges;

  const Admission({
    required this.id,
    this.admissionNo,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    this.patientPhotoUrl,
    this.wardName,
    this.bedNo,
    this.doctorName,
    this.admissionDate,
    this.dischargeDate,
    required this.status,
    required this.totalCharges,
  });

  bool get isAdmitted => status == 'admitted';

  factory Admission.fromJson(Map<String, dynamic> json) => Admission(
        id: json['id'] as int,
        admissionNo: json['admission_no']?.toString(),
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        patientPhotoUrl: json['patient_photo_url']?.toString(),
        wardName: json['ward_name']?.toString(),
        bedNo: json['bed_no']?.toString(),
        doctorName: json['doctor_name']?.toString(),
        admissionDate: json['admission_date']?.toString(),
        dischargeDate: json['discharge_date']?.toString(),
        status: json['status']?.toString() ?? '',
        totalCharges: asDoubleOr(json['total_charges'], 0),
      );
}

class AdmissionBalance {
  final double invoiceTotal;
  final double paymentsMade;
  final double depositBalance;
  final double outstanding;

  const AdmissionBalance({
    required this.invoiceTotal,
    required this.paymentsMade,
    required this.depositBalance,
    required this.outstanding,
  });

  factory AdmissionBalance.fromJson(Map<String, dynamic> json) => AdmissionBalance(
        invoiceTotal: asDoubleOr(json['invoice_total'], 0),
        paymentsMade: asDoubleOr(json['payments_made'], 0),
        depositBalance: asDoubleOr(json['deposit_balance'], 0),
        outstanding: asDoubleOr(json['outstanding'], 0),
      );
}

class SchemeBillingStats {
  final int total;
  final int pending;
  final double approvedAmount;
  final int settled;

  const SchemeBillingStats({required this.total, required this.pending, required this.approvedAmount, required this.settled});

  factory SchemeBillingStats.fromJson(Map<String, dynamic> json) => SchemeBillingStats(
        total: json['total'] as int? ?? 0,
        pending: json['pending'] as int? ?? 0,
        approvedAmount: (json['approved_amount'] as num?)?.toDouble() ?? 0,
        settled: json['settled'] as int? ?? 0,
      );
}

class SchemeBilling {
  final int id;
  final String? schemeBillNo;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final int? invoiceId;
  final String scheme;
  final String? schemeName;
  final String? beneficiaryId;
  final String? packageCode;
  final String? packageName;
  final double packageRate;
  final double actualBill;
  final double? schemePayment;
  final double? patientLiability;
  final String status;
  final String? rejectionReason;
  final String? submissionDate;
  final String? settlementDate;
  final String? icd10Code;

  const SchemeBilling({
    required this.id,
    this.schemeBillNo,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    this.invoiceId,
    required this.scheme,
    this.schemeName,
    this.beneficiaryId,
    this.packageCode,
    this.packageName,
    required this.packageRate,
    required this.actualBill,
    this.schemePayment,
    this.patientLiability,
    required this.status,
    this.rejectionReason,
    this.submissionDate,
    this.settlementDate,
    this.icd10Code,
  });

  factory SchemeBilling.fromJson(Map<String, dynamic> json) => SchemeBilling(
        id: json['id'] as int,
        schemeBillNo: json['scheme_bill_no']?.toString(),
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        invoiceId: json['invoice_id'] as int?,
        scheme: json['scheme']?.toString() ?? 'other',
        schemeName: json['scheme_name']?.toString(),
        beneficiaryId: json['beneficiary_id']?.toString(),
        packageCode: json['package_code']?.toString(),
        packageName: json['package_name']?.toString(),
        packageRate: (json['package_rate'] as num?)?.toDouble() ?? 0,
        actualBill: (json['actual_bill'] as num?)?.toDouble() ?? 0,
        schemePayment: (json['scheme_payment'] as num?)?.toDouble(),
        patientLiability: (json['patient_liability'] as num?)?.toDouble(),
        status: json['status']?.toString() ?? 'draft',
        rejectionReason: json['rejection_reason']?.toString(),
        submissionDate: json['submission_date']?.toString(),
        settlementDate: json['settlement_date']?.toString(),
        icd10Code: json['icd10_code']?.toString(),
      );
}

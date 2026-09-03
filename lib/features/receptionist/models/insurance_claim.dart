class InsuranceClaimStats {
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final double totalApprovedAmount;

  const InsuranceClaimStats({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.totalApprovedAmount,
  });

  factory InsuranceClaimStats.fromJson(Map<String, dynamic> json) => InsuranceClaimStats(
        total: json['total'] as int? ?? 0,
        pending: json['pending'] as int? ?? 0,
        approved: json['approved'] as int? ?? 0,
        rejected: json['rejected'] as int? ?? 0,
        totalApprovedAmount: (json['total_approved_amount'] as num?)?.toDouble() ?? 0,
      );
}

class InsuranceClaim {
  final int id;
  final String? claimNo;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final int? invoiceId;
  final String insuranceCompany;
  final String? tpaName;
  final String policyNumber;
  final String? memberId;
  final double claimAmount;
  final double? approvedAmount;
  final double? patientLiability;
  final String claimType;
  final String status;
  final String? admissionDate;
  final String? dischargeDate;
  final String? diagnosis;
  final String? treatmentDetails;
  final String? rejectionReason;
  final String? icd10Code;

  const InsuranceClaim({
    required this.id,
    this.claimNo,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    this.invoiceId,
    required this.insuranceCompany,
    this.tpaName,
    required this.policyNumber,
    this.memberId,
    required this.claimAmount,
    this.approvedAmount,
    this.patientLiability,
    required this.claimType,
    required this.status,
    this.admissionDate,
    this.dischargeDate,
    this.diagnosis,
    this.treatmentDetails,
    this.rejectionReason,
    this.icd10Code,
  });

  factory InsuranceClaim.fromJson(Map<String, dynamic> json) => InsuranceClaim(
        id: json['id'] as int,
        claimNo: json['claim_no']?.toString(),
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        invoiceId: json['invoice_id'] as int?,
        insuranceCompany: json['insurance_company']?.toString() ?? '',
        tpaName: json['tpa_name']?.toString(),
        policyNumber: json['policy_number']?.toString() ?? '',
        memberId: json['member_id']?.toString(),
        claimAmount: (json['claim_amount'] as num?)?.toDouble() ?? 0,
        approvedAmount: (json['approved_amount'] as num?)?.toDouble(),
        patientLiability: (json['patient_liability'] as num?)?.toDouble(),
        claimType: json['claim_type']?.toString() ?? 'cashless',
        status: json['status']?.toString() ?? 'draft',
        admissionDate: json['admission_date']?.toString(),
        dischargeDate: json['discharge_date']?.toString(),
        diagnosis: json['diagnosis']?.toString(),
        treatmentDetails: json['treatment_details']?.toString(),
        rejectionReason: json['rejection_reason']?.toString(),
        icd10Code: json['icd10_code']?.toString(),
      );
}

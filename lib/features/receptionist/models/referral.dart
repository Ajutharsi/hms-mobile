class Referral {
  final int id;
  final String? referralNo;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final String? referredByName;
  final String? referredToName;
  final String reason;
  final String? notes;
  final String priority;
  final String status;
  final String? referralDate;

  const Referral({
    required this.id,
    this.referralNo,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    this.referredByName,
    this.referredToName,
    required this.reason,
    this.notes,
    required this.priority,
    required this.status,
    this.referralDate,
  });

  factory Referral.fromJson(Map<String, dynamic> json) => Referral(
        id: json['id'] as int,
        referralNo: json['referral_no']?.toString(),
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        referredByName: json['referred_by_name']?.toString(),
        referredToName: json['referred_to_name']?.toString(),
        reason: json['reason']?.toString() ?? '',
        notes: json['notes']?.toString(),
        priority: json['priority']?.toString() ?? 'routine',
        status: json['status']?.toString() ?? 'pending',
        referralDate: json['referral_date']?.toString(),
      );
}

class ConsentForm {
  final int id;
  final String? consentNo;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final String consentType;
  final String? procedureName;
  final String description;
  final String? witnessName;
  final String? doctorName;
  final String? consentDate;
  final String status;
  final String? createdByName;
  final bool hasPatientSignature;
  final bool hasWitnessSignature;

  const ConsentForm({
    required this.id,
    this.consentNo,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    required this.consentType,
    this.procedureName,
    required this.description,
    this.witnessName,
    this.doctorName,
    this.consentDate,
    required this.status,
    this.createdByName,
    required this.hasPatientSignature,
    required this.hasWitnessSignature,
  });

  factory ConsentForm.fromJson(Map<String, dynamic> json) => ConsentForm(
        id: json['id'] as int,
        consentNo: json['consent_no']?.toString(),
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        consentType: json['consent_type']?.toString() ?? 'general',
        procedureName: json['procedure_name']?.toString(),
        description: json['description']?.toString() ?? '',
        witnessName: json['witness_name']?.toString(),
        doctorName: json['doctor_name']?.toString(),
        consentDate: json['consent_date']?.toString(),
        status: json['status']?.toString() ?? 'pending',
        createdByName: json['created_by_name']?.toString(),
        hasPatientSignature: json['has_patient_signature'] == true,
        hasWitnessSignature: json['has_witness_signature'] == true,
      );
}

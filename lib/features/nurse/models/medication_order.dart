class MedicationOrder {
  final int id;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final String drugName;
  final String dosage;
  final String? route;
  final String? frequency;
  final String? scheduledTime;
  final String? administeredAt;
  final String status;
  final String? notes;
  final bool isPrn;
  final bool isControlled;
  final String? nurseName;

  const MedicationOrder({
    required this.id,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    required this.drugName,
    required this.dosage,
    this.route,
    this.frequency,
    this.scheduledTime,
    this.administeredAt,
    required this.status,
    this.notes,
    required this.isPrn,
    required this.isControlled,
    this.nurseName,
  });

  bool get isScheduled => status == 'scheduled';

  factory MedicationOrder.fromJson(Map<String, dynamic> json) => MedicationOrder(
        id: json['id'] as int,
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        drugName: json['drug_name']?.toString() ?? '',
        dosage: json['dosage']?.toString() ?? '',
        route: json['route']?.toString(),
        frequency: json['frequency']?.toString(),
        scheduledTime: json['scheduled_time']?.toString(),
        administeredAt: json['administered_at']?.toString(),
        status: json['status']?.toString() ?? 'scheduled',
        notes: json['notes']?.toString(),
        isPrn: json['is_prn'] == true,
        isControlled: json['is_controlled'] == true,
        nurseName: json['nurse_name']?.toString(),
      );
}

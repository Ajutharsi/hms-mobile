class RadiologyOrder {
  final int id;
  final String? orderNo;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final String? doctorName;
  final String modality;
  final String bodyPart;
  final String studyDescription;
  final String? clinicalIndication;
  final String priority;
  final String status;
  final String? orderDate;
  final String? scheduledAt;
  final String? completedAt;
  final String? findings;
  final String? impression;
  final String? radiologistName;

  const RadiologyOrder({
    required this.id,
    this.orderNo,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    this.doctorName,
    required this.modality,
    required this.bodyPart,
    required this.studyDescription,
    this.clinicalIndication,
    required this.priority,
    required this.status,
    this.orderDate,
    this.scheduledAt,
    this.completedAt,
    this.findings,
    this.impression,
    this.radiologistName,
  });

  factory RadiologyOrder.fromJson(Map<String, dynamic> json) => RadiologyOrder(
        id: json['id'] as int,
        orderNo: json['order_no']?.toString(),
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        doctorName: json['doctor_name']?.toString(),
        modality: json['modality']?.toString() ?? '',
        bodyPart: json['body_part']?.toString() ?? '',
        studyDescription: json['study_description']?.toString() ?? '',
        clinicalIndication: json['clinical_indication']?.toString(),
        priority: json['priority']?.toString() ?? 'routine',
        status: json['status']?.toString() ?? 'ordered',
        orderDate: json['order_date']?.toString(),
        scheduledAt: json['scheduled_at']?.toString(),
        completedAt: json['completed_at']?.toString(),
        findings: json['findings']?.toString(),
        impression: json['impression']?.toString(),
        radiologistName: json['radiologist_name']?.toString(),
      );
}

class RadiologyStats {
  final int total;
  final int pending;
  final int completed;
  final int emergency;

  const RadiologyStats({required this.total, required this.pending, required this.completed, required this.emergency});

  factory RadiologyStats.fromJson(Map<String, dynamic> json) => RadiologyStats(
        total: json['total'] as int? ?? 0,
        pending: json['pending'] as int? ?? 0,
        completed: json['completed'] as int? ?? 0,
        emergency: json['emergency'] as int? ?? 0,
      );
}

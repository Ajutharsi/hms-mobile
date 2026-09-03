class OpdToken {
  final int id;
  final String? tokenNo;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final int doctorId;
  final String? doctorName;
  final String status;
  final int queuePosition;
  final String? calledAt;
  final String? notes;

  const OpdToken({
    required this.id,
    this.tokenNo,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    required this.doctorId,
    this.doctorName,
    required this.status,
    required this.queuePosition,
    this.calledAt,
    this.notes,
  });

  factory OpdToken.fromJson(Map<String, dynamic> json) => OpdToken(
        id: json['id'] as int,
        tokenNo: json['token_no']?.toString(),
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        doctorId: json['doctor_id'] as int,
        doctorName: json['doctor_name']?.toString(),
        status: json['status']?.toString() ?? 'waiting',
        queuePosition: json['queue_position'] as int? ?? 0,
        calledAt: json['called_at']?.toString(),
        notes: json['notes']?.toString(),
      );
}

class OpdQueueStats {
  final int total;
  final int waiting;
  final int inConsult;
  final int completed;

  const OpdQueueStats({required this.total, required this.waiting, required this.inConsult, required this.completed});

  factory OpdQueueStats.fromJson(Map<String, dynamic> json) => OpdQueueStats(
        total: json['total'] as int? ?? 0,
        waiting: json['waiting'] as int? ?? 0,
        inConsult: json['in_consult'] as int? ?? 0,
        completed: json['completed'] as int? ?? 0,
      );
}

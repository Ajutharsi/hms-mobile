class OtSchedule {
  final int id;
  final String? otNo;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final String? surgeonName;
  final String? theatreNo;
  final String procedureName;
  final String? anaesthesiaType;
  final String priority;
  final String status;
  final String? scheduledStart;
  final String? scheduledEnd;
  final String? actualStart;
  final String? actualEnd;
  final String? preOpNotes;
  final String? postOpNotes;
  final String? complications;

  const OtSchedule({
    required this.id,
    this.otNo,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    this.surgeonName,
    this.theatreNo,
    required this.procedureName,
    this.anaesthesiaType,
    required this.priority,
    required this.status,
    this.scheduledStart,
    this.scheduledEnd,
    this.actualStart,
    this.actualEnd,
    this.preOpNotes,
    this.postOpNotes,
    this.complications,
  });

  factory OtSchedule.fromJson(Map<String, dynamic> json) => OtSchedule(
        id: json['id'] as int,
        otNo: json['ot_no']?.toString(),
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        surgeonName: json['surgeon_name']?.toString(),
        theatreNo: json['theatre_no']?.toString(),
        procedureName: json['procedure_name']?.toString() ?? '',
        anaesthesiaType: json['anaesthesia_type']?.toString(),
        priority: json['priority']?.toString() ?? 'elective',
        status: json['status']?.toString() ?? 'scheduled',
        scheduledStart: json['scheduled_start']?.toString(),
        scheduledEnd: json['scheduled_end']?.toString(),
        actualStart: json['actual_start']?.toString(),
        actualEnd: json['actual_end']?.toString(),
        preOpNotes: json['pre_op_notes']?.toString(),
        postOpNotes: json['post_op_notes']?.toString(),
        complications: json['complications']?.toString(),
      );
}

class NursingNote {
  final int id;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final String noteType;
  final String? shift;
  final String note;
  final String priority;
  final String? notedAt;
  final String? writtenByName;

  const NursingNote({
    required this.id,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    required this.noteType,
    this.shift,
    required this.note,
    required this.priority,
    this.notedAt,
    this.writtenByName,
  });

  factory NursingNote.fromJson(Map<String, dynamic> json) => NursingNote(
        id: json['id'] as int,
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        noteType: json['note_type']?.toString() ?? 'nursing',
        shift: json['shift']?.toString(),
        note: json['note']?.toString() ?? '',
        priority: json['priority']?.toString() ?? 'routine',
        notedAt: json['noted_at']?.toString(),
        writtenByName: json['written_by_name']?.toString(),
      );
}

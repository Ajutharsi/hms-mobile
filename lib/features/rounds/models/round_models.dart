import 'package:hms_mobile/core/models/json_value.dart';

/// An admitted patient on the round list.
class RoundPatient {
  final int admissionId;
  final String admissionNo;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final String? wardName;
  final String? bedNo;
  final String? doctorName;
  final String? lastNoteAt;
  final bool seenToday;

  const RoundPatient({
    required this.admissionId,
    required this.admissionNo,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    this.wardName,
    this.bedNo,
    this.doctorName,
    this.lastNoteAt,
    required this.seenToday,
  });

  factory RoundPatient.fromJson(Map<String, dynamic> j) => RoundPatient(
        admissionId: asIntOr(j['admission_id']),
        admissionNo: j['admission_no']?.toString() ?? '',
        patientId: asIntOr(j['patient_id']),
        patientName: j['patient_name']?.toString(),
        patientMrn: j['patient_mrn']?.toString(),
        wardName: j['ward_name']?.toString(),
        bedNo: j['bed_no']?.toString(),
        doctorName: j['doctor_name']?.toString(),
        lastNoteAt: j['last_note_at']?.toString(),
        seenToday: j['seen_today'] == true,
      );

  String get where => [wardName, bedNo].where((s) => (s ?? '').isNotEmpty).join(' · ');

  /// What the round wants to know at a glance.
  String get lastSeen => (lastNoteAt ?? '').isEmpty ? 'No note yet' : 'Last note $lastNoteAt';
}

/// One SOAP note.
class RoundNote {
  final int id;
  final String noteType;
  final String? subjective;
  final String? objective;
  final String? assessment;
  final String? plan;
  final String? author;
  final String? notedAt;

  const RoundNote({
    required this.id,
    required this.noteType,
    this.subjective,
    this.objective,
    this.assessment,
    this.plan,
    this.author,
    this.notedAt,
  });

  factory RoundNote.fromJson(Map<String, dynamic> j) => RoundNote(
        id: asIntOr(j['id']),
        noteType: j['note_type']?.toString() ?? 'round',
        subjective: j['subjective']?.toString(),
        objective: j['objective']?.toString(),
        assessment: j['assessment']?.toString(),
        plan: j['plan']?.toString(),
        author: j['author']?.toString(),
        notedAt: j['noted_at']?.toString(),
      );

  /// The four parts in SOAP order, skipping the ones left blank.
  List<({String label, String text})> get parts => [
        if ((subjective ?? '').isNotEmpty) (label: 'Subjective', text: subjective!),
        if ((objective ?? '').isNotEmpty) (label: 'Objective', text: objective!),
        if ((assessment ?? '').isNotEmpty) (label: 'Assessment', text: assessment!),
        if ((plan ?? '').isNotEmpty) (label: 'Plan', text: plan!),
      ];
}

class RoundDetail {
  final int admissionId;
  final String admissionNo;
  final String? patientName;
  final String? patientMrn;
  final String? wardName;
  final String? bedNo;
  final String? admissionReason;
  final Map<String, String>? lastVitals;
  final List<RoundNote> notes;

  const RoundDetail({
    required this.admissionId,
    required this.admissionNo,
    this.patientName,
    this.patientMrn,
    this.wardName,
    this.bedNo,
    this.admissionReason,
    this.lastVitals,
    required this.notes,
  });

  factory RoundDetail.fromJson(Map<String, dynamic> j) {
    final admission = (j['admission'] as Map?)?.cast<String, dynamic>() ?? const {};
    return RoundDetail(
      admissionId: asIntOr(admission['id']),
      admissionNo: admission['admission_no']?.toString() ?? '',
      patientName: admission['patient_name']?.toString(),
      patientMrn: admission['patient_mrn']?.toString(),
      wardName: admission['ward_name']?.toString(),
      bedNo: admission['bed_no']?.toString(),
      admissionReason: admission['admission_reason']?.toString(),
      lastVitals: (j['last_vitals'] as Map?)
          ?.map((k, v) => MapEntry('$k', v?.toString() ?? ''))
          .cast<String, String>(),
      notes: ((j['notes'] as List?) ?? const [])
          .map((n) => RoundNote.fromJson((n as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  String get where => [wardName, bedNo].where((s) => (s ?? '').isNotEmpty).join(' · ');
}

import 'package:hms_mobile/core/models/json_value.dart';

/// Everything `GET /emr/patients/{id}` returns, in the order the screen
/// shows it: allergies first, because that is the part somebody is in a
/// hurry to find.
class PatientEmr {
  final EmrPatient patient;
  final List<EmrAllergy> allergies;
  final List<EmrProblem> problems;
  final List<EmrRecord> records;
  final List<EmrAttachment> attachments;

  const PatientEmr({
    required this.patient,
    required this.allergies,
    required this.problems,
    required this.records,
    required this.attachments,
  });

  factory PatientEmr.fromJson(Map<String, dynamic> j) => PatientEmr(
        patient: EmrPatient.fromJson(j['patient'] as Map<String, dynamic>? ?? const {}),
        allergies: _list(j['allergies'], EmrAllergy.fromJson),
        problems: _list(j['problems'], EmrProblem.fromJson),
        records: _list(j['records'], EmrRecord.fromJson),
        attachments: _list(j['attachments'], EmrAttachment.fromJson),
      );

  bool get isEmpty =>
      allergies.isEmpty && problems.isEmpty && records.isEmpty && attachments.isEmpty;

  /// Shown as a warning strip at the top of the record.
  List<EmrAllergy> get severeAllergies =>
      allergies.where((a) => a.severity == 'severe').toList();
}

List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) build) =>
    (raw as List? ?? []).map((e) => build(e as Map<String, dynamic>)).toList();

class EmrPatient {
  final int id;
  final String name;
  final String mrn;
  final String? gender;
  final String? bloodGroup;

  const EmrPatient({
    required this.id,
    required this.name,
    required this.mrn,
    this.gender,
    this.bloodGroup,
  });

  factory EmrPatient.fromJson(Map<String, dynamic> j) => EmrPatient(
        id: asIntOr(j['id']),
        name: j['name']?.toString() ?? 'Patient',
        mrn: j['mrn']?.toString() ?? '',
        gender: j['gender']?.toString(),
        bloodGroup: j['blood_group']?.toString(),
      );
}

class EmrAllergy {
  final int id;
  final String allergen;
  final String type;
  final String severity;
  final String? reaction;

  const EmrAllergy({
    required this.id,
    required this.allergen,
    required this.type,
    required this.severity,
    this.reaction,
  });

  factory EmrAllergy.fromJson(Map<String, dynamic> j) => EmrAllergy(
        id: asIntOr(j['id']),
        allergen: j['allergen']?.toString() ?? '',
        type: j['type']?.toString() ?? 'other',
        severity: j['severity']?.toString() ?? 'mild',
        reaction: j['reaction']?.toString(),
      );
}

class EmrProblem {
  final int id;
  final String problemName;
  final String? onsetDate;
  final String status;
  final String? notes;

  const EmrProblem({
    required this.id,
    required this.problemName,
    this.onsetDate,
    required this.status,
    this.notes,
  });

  factory EmrProblem.fromJson(Map<String, dynamic> j) => EmrProblem(
        id: asIntOr(j['id']),
        problemName: j['problem_name']?.toString() ?? '',
        onsetDate: j['onset_date']?.toString(),
        status: j['status']?.toString() ?? 'active',
        notes: j['notes']?.toString(),
      );
}

class EmrRecord {
  final int id;
  final String recordType;
  final String? recordDate;
  final String description;
  final String? doctorName;
  final String? notes;

  const EmrRecord({
    required this.id,
    required this.recordType,
    this.recordDate,
    required this.description,
    this.doctorName,
    this.notes,
  });

  factory EmrRecord.fromJson(Map<String, dynamic> j) => EmrRecord(
        id: asIntOr(j['id']),
        recordType: j['record_type']?.toString() ?? '',
        recordDate: j['record_date']?.toString(),
        description: j['description']?.toString() ?? '',
        doctorName: j['doctor_name']?.toString(),
        notes: j['notes']?.toString(),
      );
}

class EmrAttachment {
  final int id;
  final String fileName;
  final String? fileType;
  final String? fileSize;
  final String? description;
  final String? uploadedBy;
  final String? url;

  const EmrAttachment({
    required this.id,
    required this.fileName,
    this.fileType,
    this.fileSize,
    this.description,
    this.uploadedBy,
    this.url,
  });

  factory EmrAttachment.fromJson(Map<String, dynamic> j) => EmrAttachment(
        id: asIntOr(j['id']),
        fileName: j['file_name']?.toString() ?? 'File',
        fileType: j['file_type']?.toString(),
        fileSize: j['file_size']?.toString(),
        description: j['description']?.toString(),
        uploadedBy: j['uploaded_by']?.toString(),
        url: j['url']?.toString(),
      );

  bool get isImage => (fileType ?? '').startsWith('image/');
}

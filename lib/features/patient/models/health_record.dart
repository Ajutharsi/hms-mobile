/// Everything the hospital holds about the signed-in patient.
///
/// Read-only: the clinical side of the record, which the app could not
/// show before — what was found at a consultation, what they react to,
/// what happened during a stay.
class HealthRecord {
  final String name;
  final String mrn;
  final String? bloodGroup;
  final String? gender;
  final List<RecordAllergy> allergies;
  final List<RecordProblem> problems;
  final List<RecordConsultation> consultations;
  final List<RecordStay> stays;
  final List<RecordVitals> vitals;

  const HealthRecord({
    required this.name,
    required this.mrn,
    this.bloodGroup,
    this.gender,
    required this.allergies,
    required this.problems,
    required this.consultations,
    required this.stays,
    required this.vitals,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    final patient = (json['patient'] as Map?)?.cast<String, dynamic>() ?? const {};

    List<T> list<T>(String key, T Function(Map<String, dynamic>) build) =>
        ((json[key] as List?) ?? const []).map((e) => build((e as Map).cast<String, dynamic>())).toList();

    return HealthRecord(
      name: patient['name']?.toString() ?? '',
      mrn: patient['mrn']?.toString() ?? '',
      bloodGroup: patient['blood_group']?.toString(),
      gender: patient['gender']?.toString(),
      allergies: list('allergies', RecordAllergy.fromJson),
      problems: list('problems', RecordProblem.fromJson),
      consultations: list('consultations', RecordConsultation.fromJson),
      stays: list('stays', RecordStay.fromJson),
      vitals: list('vitals', RecordVitals.fromJson),
    );
  }

  bool get isEmpty =>
      allergies.isEmpty && problems.isEmpty && consultations.isEmpty && stays.isEmpty && vitals.isEmpty;
}

class RecordAllergy {
  final String allergen;
  final String? type;
  final String severity;
  final String? reaction;

  const RecordAllergy({required this.allergen, this.type, required this.severity, this.reaction});

  factory RecordAllergy.fromJson(Map<String, dynamic> j) => RecordAllergy(
        allergen: j['allergen']?.toString() ?? '',
        type: j['type']?.toString(),
        severity: j['severity']?.toString() ?? 'mild',
        reaction: j['reaction']?.toString(),
      );
}

class RecordProblem {
  final String problemName;
  final String status;
  final String? onsetDate;

  const RecordProblem({required this.problemName, required this.status, this.onsetDate});

  factory RecordProblem.fromJson(Map<String, dynamic> j) => RecordProblem(
        problemName: j['problem_name']?.toString() ?? '',
        status: j['status']?.toString() ?? 'active',
        onsetDate: j['onset_date']?.toString(),
      );
}

class RecordConsultation {
  final String? date;
  final String? doctorName;
  final String? chiefComplaint;
  final String? diagnosis;
  final String? treatmentPlan;

  const RecordConsultation({this.date, this.doctorName, this.chiefComplaint, this.diagnosis, this.treatmentPlan});

  factory RecordConsultation.fromJson(Map<String, dynamic> j) => RecordConsultation(
        date: j['date']?.toString(),
        doctorName: j['doctor_name']?.toString(),
        chiefComplaint: j['chief_complaint']?.toString(),
        diagnosis: j['diagnosis']?.toString(),
        treatmentPlan: j['treatment_plan']?.toString(),
      );
}

class RecordStay {
  final String admissionNo;
  final String? wardName;
  final String? doctorName;
  final String? admissionDate;
  final String? dischargeDate;
  final String status;
  final String? reason;
  final String? dischargeNotes;

  const RecordStay({
    required this.admissionNo,
    this.wardName,
    this.doctorName,
    this.admissionDate,
    this.dischargeDate,
    required this.status,
    this.reason,
    this.dischargeNotes,
  });

  factory RecordStay.fromJson(Map<String, dynamic> j) => RecordStay(
        admissionNo: j['admission_no']?.toString() ?? '',
        wardName: j['ward_name']?.toString(),
        doctorName: j['doctor_name']?.toString(),
        admissionDate: j['admission_date']?.toString(),
        dischargeDate: j['discharge_date']?.toString(),
        status: j['status']?.toString() ?? 'admitted',
        reason: j['reason']?.toString(),
        dischargeNotes: j['discharge_notes']?.toString(),
      );

  String get span => (dischargeDate ?? '').isEmpty
      ? 'Admitted ${admissionDate ?? ''}'
      : '${admissionDate ?? ''} → ${dischargeDate!}';
}

class RecordVitals {
  final String? recordedAt;
  final String? bloodPressure;
  final String? temperature;
  final String? pulseRate;
  final String? spo2;
  final String? weight;

  const RecordVitals({
    this.recordedAt,
    this.bloodPressure,
    this.temperature,
    this.pulseRate,
    this.spo2,
    this.weight,
  });

  factory RecordVitals.fromJson(Map<String, dynamic> j) => RecordVitals(
        recordedAt: j['recorded_at']?.toString(),
        bloodPressure: j['blood_pressure']?.toString(),
        temperature: j['temperature']?.toString(),
        pulseRate: j['pulse_rate']?.toString(),
        spo2: j['spo2']?.toString(),
        weight: j['weight']?.toString(),
      );

  /// The readings that were actually taken, as label/value pairs.
  List<({String label, String value})> get readings => [
        if ((bloodPressure ?? '').isNotEmpty) (label: 'BP', value: bloodPressure!),
        if ((pulseRate ?? '').isNotEmpty) (label: 'Pulse', value: pulseRate!),
        if ((temperature ?? '').isNotEmpty) (label: 'Temp', value: temperature!),
        if ((spo2 ?? '').isNotEmpty) (label: 'SpO₂', value: spo2!),
        if ((weight ?? '').isNotEmpty) (label: 'Weight', value: weight!),
      ];
}

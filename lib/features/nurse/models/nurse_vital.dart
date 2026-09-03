class NurseVital {
  final int id;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final String? bloodPressure;
  final num? temperature;
  final int? pulseRate;
  final int? respiratoryRate;
  final int? spo2;
  final num? weight;
  final num? height;
  final int? newsScore;
  final String? notes;
  final String? recordedAt;
  final String? recordedByName;

  const NurseVital({
    required this.id,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    this.bloodPressure,
    this.temperature,
    this.pulseRate,
    this.respiratoryRate,
    this.spo2,
    this.weight,
    this.height,
    this.newsScore,
    this.notes,
    this.recordedAt,
    this.recordedByName,
  });

  factory NurseVital.fromJson(Map<String, dynamic> json) => NurseVital(
        id: json['id'] as int,
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        bloodPressure: json['blood_pressure']?.toString(),
        temperature: json['temperature'] as num?,
        pulseRate: json['pulse_rate'] as int?,
        respiratoryRate: json['respiratory_rate'] as int?,
        spo2: json['spo2'] as int?,
        weight: json['weight'] as num?,
        height: json['height'] as num?,
        newsScore: json['news_score'] as int?,
        notes: json['notes']?.toString(),
        recordedAt: json['recorded_at']?.toString(),
        recordedByName: json['recorded_by_name']?.toString(),
      );
}

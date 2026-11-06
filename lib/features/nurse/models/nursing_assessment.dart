import 'package:hms_mobile/core/models/json_value.dart';

/// One bedside assessment, with the bands the server worked out.
///
/// The app shows the band, not the raw number, because "high" is what a
/// nurse acts on; the number is there for the ones who know the scale.
class NursingAssessment {
  final int id;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final String? assessedBy;
  final String? assessedAt;
  final int? fallRiskScore;
  final String? fallRiskBand;
  final int? painScore;
  final String? painBand;
  final int? bradenScore;
  final String? bradenBand;
  final int? ewsScore;
  final String? ewsBand;
  final bool needsAttention;
  final String? notes;

  const NursingAssessment({
    required this.id,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    this.assessedBy,
    this.assessedAt,
    this.fallRiskScore,
    this.fallRiskBand,
    this.painScore,
    this.painBand,
    this.bradenScore,
    this.bradenBand,
    this.ewsScore,
    this.ewsBand,
    required this.needsAttention,
    this.notes,
  });

  factory NursingAssessment.fromJson(Map<String, dynamic> j) => NursingAssessment(
        id: asIntOr(j['id']),
        patientId: asIntOr(j['patient_id']),
        patientName: j['patient_name']?.toString(),
        patientMrn: j['patient_mrn']?.toString(),
        assessedBy: j['assessed_by']?.toString(),
        assessedAt: j['assessed_at']?.toString(),
        fallRiskScore: j['fall_risk_score'] as int?,
        fallRiskBand: j['fall_risk_band']?.toString(),
        painScore: j['pain_score'] as int?,
        painBand: j['pain_band']?.toString(),
        bradenScore: j['braden_score'] as int?,
        bradenBand: j['braden_band']?.toString(),
        ewsScore: j['ews_score'] as int?,
        ewsBand: j['ews_band']?.toString(),
        needsAttention: j['needs_attention'] == true,
        notes: j['notes']?.toString(),
      );

  /// The four scales, in the order the screen shows them, skipping the
  /// ones that were not scored.
  List<({String label, String value, String? band})> get scores => [
        if (fallRiskScore != null)
          (label: 'Fall risk', value: '$fallRiskScore', band: fallRiskBand),
        if (ewsScore != null) (label: 'EWS', value: '$ewsScore', band: ewsBand),
        if (painScore != null) (label: 'Pain', value: '$painScore/10', band: painBand),
        if (bradenScore != null) (label: 'Braden', value: '$bradenScore', band: bradenBand),
      ];
}

import 'package:hms_mobile/core/models/json_value.dart';

class IcuChart {
  final int id;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final String? ventilatorMode;
  final int? fio2;
  final int? peep;
  final int? tidalVolume;
  final int? respiratoryRateSet;
  final String? arterialBp;
  final int? cvp;
  final int? heartRate;
  final String? rhythm;
  final String? linesDrains;
  final int? gcsEye;
  final int? gcsVerbal;
  final int? gcsMotor;
  final int? gcsTotal;
  final num? intakeOral;
  final num? intakeIv;
  final num? outputUrine;
  final num? outputDrain;
  final num? fluidBalance;
  final String? notes;
  final String? chartedAt;
  final String? recordedByName;

  const IcuChart({
    required this.id,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    this.ventilatorMode,
    this.fio2,
    this.peep,
    this.tidalVolume,
    this.respiratoryRateSet,
    this.arterialBp,
    this.cvp,
    this.heartRate,
    this.rhythm,
    this.linesDrains,
    this.gcsEye,
    this.gcsVerbal,
    this.gcsMotor,
    this.gcsTotal,
    this.intakeOral,
    this.intakeIv,
    this.outputUrine,
    this.outputDrain,
    this.fluidBalance,
    this.notes,
    this.chartedAt,
    this.recordedByName,
  });

  factory IcuChart.fromJson(Map<String, dynamic> json) => IcuChart(
        id: json['id'] as int,
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        ventilatorMode: json['ventilator_mode']?.toString(),
        fio2: json['fio2'] as int?,
        peep: json['peep'] as int?,
        tidalVolume: json['tidal_volume'] as int?,
        respiratoryRateSet: json['respiratory_rate_set'] as int?,
        arterialBp: json['arterial_bp']?.toString(),
        cvp: json['cvp'] as int?,
        heartRate: json['heart_rate'] as int?,
        rhythm: json['rhythm']?.toString(),
        linesDrains: json['lines_drains']?.toString(),
        gcsEye: json['gcs_eye'] as int?,
        gcsVerbal: json['gcs_verbal'] as int?,
        gcsMotor: json['gcs_motor'] as int?,
        gcsTotal: json['gcs_total'] as int?,
        intakeOral: asNum(json['intake_oral']),
        intakeIv: asNum(json['intake_iv']),
        outputUrine: asNum(json['output_urine']),
        outputDrain: asNum(json['output_drain']),
        fluidBalance: asNum(json['fluid_balance']),
        notes: json['notes']?.toString(),
        chartedAt: json['charted_at']?.toString(),
        recordedByName: json['recorded_by_name']?.toString(),
      );
}

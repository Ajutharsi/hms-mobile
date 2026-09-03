class RoundPatient {
  final int id;
  final String name;
  final String mrn;
  final String bedNo;

  const RoundPatient({required this.id, required this.name, required this.mrn, required this.bedNo});

  factory RoundPatient.fromJson(Map<String, dynamic> json) => RoundPatient(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        mrn: json['mrn']?.toString() ?? '',
        bedNo: json['bed_no']?.toString() ?? 'N/A',
      );
}

class RoundAssignment {
  final int id;
  final String wardName;
  final int wardId;
  final int frequencyHours;
  final String? nextRoundAt;
  final String? lastRoundAt;
  final int? minutesLeft;
  final bool isOverdue;
  final String alertStatus;
  final List<RoundPatient> patients;

  const RoundAssignment({
    required this.id,
    required this.wardName,
    required this.wardId,
    required this.frequencyHours,
    this.nextRoundAt,
    this.lastRoundAt,
    this.minutesLeft,
    required this.isOverdue,
    required this.alertStatus,
    required this.patients,
  });

  factory RoundAssignment.fromJson(Map<String, dynamic> json) => RoundAssignment(
        id: json['id'] as int,
        wardName: json['ward_name']?.toString() ?? 'N/A',
        wardId: json['ward_id'] as int,
        frequencyHours: json['frequency_hours'] as int? ?? 0,
        nextRoundAt: json['next_round_at']?.toString(),
        lastRoundAt: json['last_round_at']?.toString(),
        minutesLeft: json['minutes_left'] as int?,
        isOverdue: json['is_overdue'] == true,
        alertStatus: json['alert_status']?.toString() ?? 'ok',
        patients: (json['patients'] as List? ?? []).map((p) => RoundPatient.fromJson(p as Map<String, dynamic>)).toList(),
      );
}

class StaffRound {
  final int id;
  final String? roundTime;
  final String? bloodPressure;
  final String? temperature;
  final String? pulseRate;
  final String? spo2;
  final String? notes;
  final String? staffName;

  const StaffRound({
    required this.id,
    this.roundTime,
    this.bloodPressure,
    this.temperature,
    this.pulseRate,
    this.spo2,
    this.notes,
    this.staffName,
  });

  factory StaffRound.fromJson(Map<String, dynamic> json) => StaffRound(
        id: json['id'] as int,
        roundTime: json['round_time']?.toString(),
        bloodPressure: json['blood_pressure']?.toString(),
        temperature: json['temperature']?.toString(),
        pulseRate: json['pulse_rate']?.toString(),
        spo2: json['spo2']?.toString(),
        notes: json['notes']?.toString(),
        staffName: json['staff_name']?.toString(),
      );
}

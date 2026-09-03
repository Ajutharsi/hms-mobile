class ErRegistration {
  final int id;
  final String? erNo;
  final int? patientId;
  final String patientName;
  final String? patientMrn;
  final String? patientPhone;
  final int? age;
  final String? gender;
  final String triageLevel;
  final String chiefComplaint;
  final String? presentingSymptoms;
  final String? modeOfArrival;
  final String status;
  final String? attendingDoctorName;
  final String? arrivalTime;
  final String? triageTime;
  final String? dischargeTime;
  final String? notes;

  const ErRegistration({
    required this.id,
    this.erNo,
    this.patientId,
    required this.patientName,
    this.patientMrn,
    this.patientPhone,
    this.age,
    this.gender,
    required this.triageLevel,
    required this.chiefComplaint,
    this.presentingSymptoms,
    this.modeOfArrival,
    required this.status,
    this.attendingDoctorName,
    this.arrivalTime,
    this.triageTime,
    this.dischargeTime,
    this.notes,
  });

  factory ErRegistration.fromJson(Map<String, dynamic> json) => ErRegistration(
        id: json['id'] as int,
        erNo: json['er_no']?.toString(),
        patientId: json['patient_id'] as int?,
        patientName: json['patient_name']?.toString() ?? '',
        patientMrn: json['patient_mrn']?.toString(),
        patientPhone: json['patient_phone']?.toString(),
        age: json['age'] as int?,
        gender: json['gender']?.toString(),
        triageLevel: json['triage_level']?.toString() ?? 'green',
        chiefComplaint: json['chief_complaint']?.toString() ?? '',
        presentingSymptoms: json['presenting_symptoms']?.toString(),
        modeOfArrival: json['mode_of_arrival']?.toString(),
        status: json['status']?.toString() ?? 'waiting',
        attendingDoctorName: json['attending_doctor_name']?.toString(),
        arrivalTime: json['arrival_time']?.toString(),
        triageTime: json['triage_time']?.toString(),
        dischargeTime: json['discharge_time']?.toString(),
        notes: json['notes']?.toString(),
      );
}

class ErStats {
  final int waiting;
  final int underTreatment;
  final int redAlert;
  final int todayTotal;

  const ErStats({required this.waiting, required this.underTreatment, required this.redAlert, required this.todayTotal});

  factory ErStats.fromJson(Map<String, dynamic> json) => ErStats(
        waiting: json['waiting'] as int? ?? 0,
        underTreatment: json['under_treatment'] as int? ?? 0,
        redAlert: json['red_alert'] as int? ?? 0,
        todayTotal: json['today_total'] as int? ?? 0,
      );
}

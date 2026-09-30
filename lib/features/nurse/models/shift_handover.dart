import 'package:hms_mobile/core/models/json_value.dart';

class ShiftHandoverSummary {
  final int id;
  final String? handoverNo;
  final String? wardName;
  final String currentShift;
  final String nextShift;
  final String? handoverDate;
  final String status;
  final String? outgoingNurseName;
  final String? incomingNurseName;

  const ShiftHandoverSummary({
    required this.id,
    this.handoverNo,
    this.wardName,
    required this.currentShift,
    required this.nextShift,
    this.handoverDate,
    required this.status,
    this.outgoingNurseName,
    this.incomingNurseName,
  });

  factory ShiftHandoverSummary.fromJson(Map<String, dynamic> json) => ShiftHandoverSummary(
        id: json['id'] as int,
        handoverNo: json['handover_no']?.toString(),
        wardName: json['ward_name']?.toString(),
        currentShift: json['current_shift']?.toString() ?? '',
        nextShift: json['next_shift']?.toString() ?? '',
        handoverDate: json['handover_date']?.toString(),
        status: json['status']?.toString() ?? '',
        outgoingNurseName: json['outgoing_nurse_name']?.toString(),
        incomingNurseName: json['incoming_nurse_name']?.toString(),
      );
}

class HandoverVitals {
  final String? bloodPressure;
  final num? pulseRate;
  final num? temperature;
  final num? respiratoryRate;
  final num? spo2;
  final String? recordedAt;

  const HandoverVitals({this.bloodPressure, this.pulseRate, this.temperature, this.respiratoryRate, this.spo2, this.recordedAt});

  factory HandoverVitals.fromJson(Map<String, dynamic> json) => HandoverVitals(
        bloodPressure: json['blood_pressure']?.toString(),
        pulseRate: asNum(json['pulse_rate']),
        temperature: asNum(json['temperature']),
        respiratoryRate: asNum(json['respiratory_rate']),
        spo2: asNum(json['spo2']),
        recordedAt: json['recorded_at']?.toString(),
      );
}

/// A patient "card" in the create-handover flow — pulled from
/// `wardPatients`, filled in by the nurse, then posted back in `store`.
class HandoverPatientCard {
  final int patientId;
  final int? admissionId;
  final String name;
  final String mrn;
  final String? photoUrl;
  final String bedNo;
  final String? admissionDate;
  final HandoverVitals? vitals;
  final String suggestedMedStatus;

  String condition;
  String? medicationStatus;
  String? ivFluidStatus;
  String? ivNextChangeTime;
  String? doctorInstructions;
  String? pendingProcedures;
  String? pendingLabReports;
  String? pendingImaging;
  String? specialNotes;
  bool isHighPriority;

  HandoverPatientCard({
    required this.patientId,
    this.admissionId,
    required this.name,
    required this.mrn,
    this.photoUrl,
    required this.bedNo,
    this.admissionDate,
    this.vitals,
    required this.suggestedMedStatus,
    required this.condition,
    this.medicationStatus,
    this.ivFluidStatus,
    this.ivNextChangeTime,
    this.doctorInstructions,
    this.pendingProcedures,
    this.pendingLabReports,
    this.pendingImaging,
    this.specialNotes,
    required this.isHighPriority,
  });

  factory HandoverPatientCard.fromJson(Map<String, dynamic> json) {
    final saved = json['saved'] as Map<String, dynamic>? ?? {};
    return HandoverPatientCard(
      patientId: json['patient_id'] as int,
      admissionId: json['admission_id'] as int?,
      name: json['name']?.toString() ?? 'Unknown',
      mrn: json['mrn']?.toString() ?? 'N/A',
      photoUrl: json['photo_url']?.toString(),
      bedNo: json['bed_no']?.toString() ?? 'N/A',
      admissionDate: json['admission_date']?.toString(),
      vitals: json['vitals'] != null ? HandoverVitals.fromJson(json['vitals'] as Map<String, dynamic>) : null,
      suggestedMedStatus: json['suggested_med_status']?.toString() ?? 'completed',
      condition: saved['condition']?.toString() ?? 'stable',
      medicationStatus: saved['medication_status']?.toString(),
      ivFluidStatus: saved['iv_fluid_status']?.toString(),
      ivNextChangeTime: saved['iv_next_change_time']?.toString(),
      doctorInstructions: saved['doctor_instructions']?.toString(),
      pendingProcedures: saved['pending_procedures']?.toString(),
      pendingLabReports: saved['pending_lab_reports']?.toString(),
      pendingImaging: saved['pending_imaging']?.toString(),
      specialNotes: saved['special_notes']?.toString(),
      isHighPriority: saved['is_high_priority'] == true,
    );
  }

  Map<String, dynamic> toPayload() => {
        'patient_id': patientId,
        if (admissionId != null) 'admission_id': admissionId,
        'condition': condition,
        'medication_status': medicationStatus ?? suggestedMedStatus,
        if (ivFluidStatus != null) 'iv_fluid_status': ivFluidStatus,
        if (ivNextChangeTime != null) 'iv_next_change_time': ivNextChangeTime,
        if (doctorInstructions != null) 'doctor_instructions': doctorInstructions,
        if (pendingProcedures != null) 'pending_procedures': pendingProcedures,
        if (pendingLabReports != null) 'pending_lab_reports': pendingLabReports,
        if (pendingImaging != null) 'pending_imaging': pendingImaging,
        if (specialNotes != null) 'special_notes': specialNotes,
        'is_high_priority': isHighPriority,
      };
}

class HandoverTask {
  final String? patientName;
  final String taskDescription;
  final bool isCompleted;

  const HandoverTask({this.patientName, required this.taskDescription, required this.isCompleted});

  factory HandoverTask.fromJson(Map<String, dynamic> json) => HandoverTask(
        patientName: json['patient_name']?.toString(),
        taskDescription: json['task_description']?.toString() ?? '',
        isCompleted: json['is_completed'] == true,
      );
}

class ShiftHandoverDetail extends ShiftHandoverSummary {
  final String? shiftSummary;
  final String? rejectionReason;
  final bool isEditable;
  final List<HandoverPatientCard> patients;
  final List<HandoverTask> tasks;

  const ShiftHandoverDetail({
    required super.id,
    super.handoverNo,
    super.wardName,
    required super.currentShift,
    required super.nextShift,
    super.handoverDate,
    required super.status,
    super.outgoingNurseName,
    super.incomingNurseName,
    this.shiftSummary,
    this.rejectionReason,
    required this.isEditable,
    required this.patients,
    required this.tasks,
  });

  factory ShiftHandoverDetail.fromJson(Map<String, dynamic> json) => ShiftHandoverDetail(
        id: json['id'] as int,
        handoverNo: json['handover_no']?.toString(),
        wardName: json['ward_name']?.toString(),
        currentShift: json['current_shift']?.toString() ?? '',
        nextShift: json['next_shift']?.toString() ?? '',
        handoverDate: json['handover_date']?.toString(),
        status: json['status']?.toString() ?? '',
        outgoingNurseName: json['outgoing_nurse_name']?.toString(),
        incomingNurseName: json['incoming_nurse_name']?.toString(),
        shiftSummary: json['shift_summary']?.toString(),
        rejectionReason: json['rejection_reason']?.toString(),
        isEditable: json['is_editable'] == true,
        patients: (json['patients'] as List? ?? [])
            .map((p) => HandoverPatientCard.fromJson({...p as Map<String, dynamic>, 'saved': p}))
            .toList(),
        tasks: (json['tasks'] as List? ?? []).map((t) => HandoverTask.fromJson(t as Map<String, dynamic>)).toList(),
      );
}

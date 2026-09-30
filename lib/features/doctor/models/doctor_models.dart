// Models for the doctor app — mirror what
// app/Http/Controllers/Api/DoctorController.php returns.

class DoctorDashboardStats {
  final int myAppointments;
  final int todayAppointments;
  final int prescriptions;
  final int labOrders;
  final int todayOt;
  final int pendingRadiology;
  final int opdQueue;
  final int pendingConsultations;

  const DoctorDashboardStats({
    required this.myAppointments,
    required this.todayAppointments,
    required this.prescriptions,
    required this.labOrders,
    required this.todayOt,
    required this.pendingRadiology,
    required this.opdQueue,
    required this.pendingConsultations,
  });

  factory DoctorDashboardStats.fromJson(Map<String, dynamic> json) => DoctorDashboardStats(
        myAppointments: json['my_appointments'] as int? ?? 0,
        todayAppointments: json['today_appointments'] as int? ?? 0,
        prescriptions: json['prescriptions'] as int? ?? 0,
        labOrders: json['lab_orders'] as int? ?? 0,
        todayOt: json['today_ot'] as int? ?? 0,
        pendingRadiology: json['pending_radiology'] as int? ?? 0,
        opdQueue: json['opd_queue'] as int? ?? 0,
        pendingConsultations: json['pending_consultations'] as int? ?? 0,
      );
}

class DoctorAppointment {
  final int id;
  final String appointmentId;
  final int? patientId;
  final String? patientName;
  final String? patientMrn;
  final String date;
  final String time;
  final String type;
  final String status;
  final int? tokenNumber;
  final String? notes;
  final bool hasConsultation;

  const DoctorAppointment({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.patientMrn,
    required this.date,
    required this.time,
    required this.type,
    required this.status,
    required this.tokenNumber,
    required this.notes,
    required this.hasConsultation,
  });

  factory DoctorAppointment.fromJson(Map<String, dynamic> json) => DoctorAppointment(
        id: json['id'] as int,
        appointmentId: json['appointment_id']?.toString() ?? '',
        patientId: json['patient_id'] as int?,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        date: json['date']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        status: json['status']?.toString() ?? 'scheduled',
        tokenNumber: json['token_number'] as int?,
        notes: json['notes']?.toString(),
        hasConsultation: json['has_consultation'] == true,
      );

  bool get isScheduled => status == 'scheduled';

  /// What the doctor still has to do on this visit.
  bool get needsConsultation => isScheduled && !hasConsultation;
}

class DoctorPatient {
  final int id;
  final String name;
  final String mrn;
  final String? gender;
  final int? age;
  final String? phone;
  final String? bloodGroup;
  final String? status;
  final String? photoUrl;

  const DoctorPatient({
    required this.id,
    required this.name,
    required this.mrn,
    this.gender,
    this.age,
    this.phone,
    this.bloodGroup,
    this.status,
    this.photoUrl,
  });

  factory DoctorPatient.fromJson(Map<String, dynamic> json) => DoctorPatient(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        mrn: json['mrn']?.toString() ?? '',
        gender: json['gender']?.toString(),
        age: json['age'] is int ? json['age'] as int : int.tryParse(json['age']?.toString() ?? ''),
        phone: json['phone']?.toString(),
        bloodGroup: json['blood_group']?.toString(),
        status: json['status']?.toString(),
        photoUrl: json['photo_url']?.toString(),
      );
}

class VitalsSnapshot {
  final String? bloodPressure;
  final String? temperature;
  final String? pulseRate;
  final String? spo2;
  final String? recordedAt;

  const VitalsSnapshot({this.bloodPressure, this.temperature, this.pulseRate, this.spo2, this.recordedAt});

  factory VitalsSnapshot.fromJson(Map<String, dynamic> json) => VitalsSnapshot(
        bloodPressure: json['blood_pressure']?.toString(),
        temperature: json['temperature']?.toString(),
        pulseRate: json['pulse_rate']?.toString(),
        spo2: json['spo2']?.toString(),
        recordedAt: json['recorded_at']?.toString(),
      );

  bool get isEmpty => [bloodPressure, temperature, pulseRate, spo2].every((v) => v == null || v.isEmpty);
}

class PrescribedMedicine {
  final String medicineName;
  final String dosage;
  final String frequency;
  final String duration;
  final String? route;
  final String? instructions;

  const PrescribedMedicine({
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.route,
    this.instructions,
  });

  factory PrescribedMedicine.fromJson(Map<String, dynamic> json) => PrescribedMedicine(
        medicineName: json['medicine_name']?.toString() ?? '',
        dosage: json['dosage']?.toString() ?? '',
        frequency: json['frequency']?.toString() ?? '',
        duration: json['duration']?.toString() ?? '',
        route: json['route']?.toString(),
        instructions: json['instructions']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'medicine_name': medicineName,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        if ((route ?? '').isNotEmpty) 'route': route,
        if ((instructions ?? '').isNotEmpty) 'instructions': instructions,
      };
}

class DoctorPrescription {
  final int id;
  final String prescriptionNo;
  final String? notes;
  final List<PrescribedMedicine> items;

  const DoctorPrescription({required this.id, required this.prescriptionNo, this.notes, required this.items});

  factory DoctorPrescription.fromJson(Map<String, dynamic> json) => DoctorPrescription(
        id: json['id'] as int? ?? 0,
        prescriptionNo: json['prescription_no']?.toString() ?? '',
        notes: json['notes']?.toString(),
        items: (json['items'] as List? ?? [])
            .map((i) => PrescribedMedicine.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class DoctorConsultation {
  final int id;
  final int? appointmentId;
  final String? patientName;
  final String? date;
  final String chiefComplaint;
  final String? diagnosis;
  final String? icd10Code;
  final String? treatmentPlan;
  final String? notes;
  final VitalsSnapshot vitals;
  final DoctorPrescription? prescription;

  const DoctorConsultation({
    required this.id,
    this.appointmentId,
    this.patientName,
    this.date,
    required this.chiefComplaint,
    this.diagnosis,
    this.icd10Code,
    this.treatmentPlan,
    this.notes,
    required this.vitals,
    this.prescription,
  });

  factory DoctorConsultation.fromJson(Map<String, dynamic> json) => DoctorConsultation(
        id: json['id'] as int,
        appointmentId: json['appointment_id'] as int?,
        patientName: json['patient_name']?.toString(),
        date: json['date']?.toString(),
        chiefComplaint: json['chief_complaint']?.toString() ?? '',
        diagnosis: json['diagnosis']?.toString(),
        icd10Code: json['icd10_code']?.toString(),
        treatmentPlan: json['treatment_plan']?.toString(),
        notes: json['notes']?.toString(),
        vitals: VitalsSnapshot.fromJson((json['vitals'] as Map<String, dynamic>?) ?? {}),
        prescription: json['prescription'] == null
            ? null
            : DoctorPrescription.fromJson(json['prescription'] as Map<String, dynamic>),
      );
}

/// A row from the consultation form's diagnosis-code lookup.
class Icd10Suggestion {
  final String code;
  final String description;
  final String? category;

  const Icd10Suggestion({required this.code, required this.description, this.category});

  factory Icd10Suggestion.fromJson(Map<String, dynamic> json) => Icd10Suggestion(
        code: json['code']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        category: json['category']?.toString(),
      );
}

class DoctorProfile {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String? doctorCode;
  final String? specialization;
  final String? qualification;
  final String? consultationFee;

  const DoctorProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.doctorCode,
    this.specialization,
    this.qualification,
    this.consultationFee,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? {};
    final doctor = json['doctor'] as Map<String, dynamic>?;
    return DoctorProfile(
      id: user['id'] as int? ?? 0,
      name: user['name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      phone: user['phone']?.toString(),
      photoUrl: user['profile_photo_url']?.toString(),
      doctorCode: doctor?['doctor_id']?.toString(),
      specialization: doctor?['specialization']?.toString(),
      qualification: doctor?['qualification']?.toString(),
      consultationFee: doctor?['consultation_fee']?.toString(),
    );
  }

  /// A doctor user with no Doctor record owns no appointments — the app
  /// says so rather than showing empty lists with no explanation.
  bool get isLinked => specialization != null || doctorCode != null;
}

/// Everything the appointment screen shows in one call.
class DoctorAppointmentDetail {
  final DoctorAppointment appointment;
  final DoctorPatient? patient;
  final DoctorConsultation? consultation;
  final VitalsSnapshot? latestVitals;

  const DoctorAppointmentDetail({
    required this.appointment,
    this.patient,
    this.consultation,
    this.latestVitals,
  });

  factory DoctorAppointmentDetail.fromJson(Map<String, dynamic> json) => DoctorAppointmentDetail(
        appointment: DoctorAppointment.fromJson(json['appointment'] as Map<String, dynamic>),
        patient: json['patient'] == null ? null : DoctorPatient.fromJson(json['patient'] as Map<String, dynamic>),
        consultation: json['consultation'] == null
            ? null
            : DoctorConsultation.fromJson(json['consultation'] as Map<String, dynamic>),
        latestVitals: json['latest_vitals'] == null
            ? null
            : VitalsSnapshot.fromJson(json['latest_vitals'] as Map<String, dynamic>),
      );
}

class DoctorPatientDetail {
  final DoctorPatient patient;
  final VitalsSnapshot? latestVitals;
  final List<({int id, String? date, String? chiefComplaint, String? diagnosis})> consultations;
  final List<DoctorAppointment> appointments;

  const DoctorPatientDetail({
    required this.patient,
    this.latestVitals,
    required this.consultations,
    required this.appointments,
  });

  factory DoctorPatientDetail.fromJson(Map<String, dynamic> json) => DoctorPatientDetail(
        patient: DoctorPatient.fromJson(json['patient'] as Map<String, dynamic>),
        latestVitals: json['latest_vitals'] == null
            ? null
            : VitalsSnapshot.fromJson(json['latest_vitals'] as Map<String, dynamic>),
        consultations: (json['consultations'] as List? ?? [])
            .map((c) => (
                  id: (c as Map<String, dynamic>)['id'] as int,
                  date: c['date']?.toString(),
                  chiefComplaint: c['chief_complaint']?.toString(),
                  diagnosis: c['diagnosis']?.toString(),
                ))
            .toList(),
        appointments: (json['appointments'] as List? ?? [])
            .map((a) => DoctorAppointment.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
}

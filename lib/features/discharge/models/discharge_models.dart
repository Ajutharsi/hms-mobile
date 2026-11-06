import 'package:hms_mobile/core/models/json_value.dart';

/// A row in the list of stays waiting for a summary.
class DischargeStay {
  final int id;
  final String admissionNo;
  final String? patientName;
  final String? patientMrn;
  final String? wardName;
  final String? bedNo;
  final String? doctorName;
  final String? admissionDate;
  final String? dischargeDate;
  final String status;
  final bool hasSummary;

  const DischargeStay({
    required this.id,
    required this.admissionNo,
    this.patientName,
    this.patientMrn,
    this.wardName,
    this.bedNo,
    this.doctorName,
    this.admissionDate,
    this.dischargeDate,
    required this.status,
    required this.hasSummary,
  });

  factory DischargeStay.fromJson(Map<String, dynamic> j) => DischargeStay(
        id: asIntOr(j['id']),
        admissionNo: j['admission_no']?.toString() ?? '',
        patientName: j['patient_name']?.toString(),
        patientMrn: j['patient_mrn']?.toString(),
        wardName: j['ward_name']?.toString(),
        bedNo: j['bed_no']?.toString(),
        doctorName: j['doctor_name']?.toString(),
        admissionDate: j['admission_date']?.toString(),
        dischargeDate: j['discharge_date']?.toString(),
        status: j['status']?.toString() ?? 'admitted',
        hasSummary: j['has_summary'] == true,
      );

  String get where => [wardName, bedNo].where((s) => (s ?? '').isNotEmpty).join(' · ');
}

/// The whole stay, gathered. Nothing here is new information: it is the
/// consultations, prescriptions and tests of those days in one place.
class DischargeSummary {
  final DischargeStayDetail stay;
  final List<DischargeDiagnosis> diagnoses;
  final List<DischargeMedicine> medicines;
  final List<DischargeTest> tests;
  final Map<String, String>? lastVitals;

  const DischargeSummary({
    required this.stay,
    required this.diagnoses,
    required this.medicines,
    required this.tests,
    this.lastVitals,
  });

  factory DischargeSummary.fromJson(Map<String, dynamic> j) => DischargeSummary(
        stay: DischargeStayDetail.fromJson((j['admission'] as Map?)?.cast<String, dynamic>() ?? const {}),
        diagnoses: ((j['diagnoses'] as List?) ?? const [])
            .map((d) => DischargeDiagnosis.fromJson((d as Map).cast<String, dynamic>()))
            .toList(),
        medicines: ((j['medicines'] as List?) ?? const [])
            .map((m) => DischargeMedicine.fromJson((m as Map).cast<String, dynamic>()))
            .toList(),
        tests: ((j['tests'] as List?) ?? const [])
            .map((t) => DischargeTest.fromJson((t as Map).cast<String, dynamic>()))
            .toList(),
        lastVitals: (j['last_vitals'] as Map?)
            ?.map((k, v) => MapEntry('$k', v?.toString() ?? ''))
            .cast<String, String>(),
      );
}

class DischargeStayDetail {
  final int id;
  final String admissionNo;
  final String? patientName;
  final String? patientMrn;
  final String? wardName;
  final String? bedNo;
  final String? doctorName;
  final String? admissionDate;
  final String? dischargeDate;
  final int? days;
  final String status;
  final String? admissionReason;
  final String? dischargeNotes;

  const DischargeStayDetail({
    required this.id,
    required this.admissionNo,
    this.patientName,
    this.patientMrn,
    this.wardName,
    this.bedNo,
    this.doctorName,
    this.admissionDate,
    this.dischargeDate,
    this.days,
    required this.status,
    this.admissionReason,
    this.dischargeNotes,
  });

  factory DischargeStayDetail.fromJson(Map<String, dynamic> j) => DischargeStayDetail(
        id: asIntOr(j['id']),
        admissionNo: j['admission_no']?.toString() ?? '',
        patientName: j['patient_name']?.toString(),
        patientMrn: j['patient_mrn']?.toString(),
        wardName: j['ward_name']?.toString(),
        bedNo: j['bed_no']?.toString(),
        doctorName: j['doctor_name']?.toString(),
        admissionDate: j['admission_date']?.toString(),
        dischargeDate: j['discharge_date']?.toString(),
        days: j['days'] as int?,
        status: j['status']?.toString() ?? 'admitted',
        admissionReason: j['admission_reason']?.toString(),
        dischargeNotes: j['discharge_notes']?.toString(),
      );

  String get where => [wardName, bedNo].where((s) => (s ?? '').isNotEmpty).join(' · ');
}

class DischargeDiagnosis {
  final String? date;
  final String? doctorName;
  final String? chiefComplaint;
  final String? diagnosis;
  final String? icd10Code;
  final String? treatmentPlan;

  const DischargeDiagnosis({
    this.date,
    this.doctorName,
    this.chiefComplaint,
    this.diagnosis,
    this.icd10Code,
    this.treatmentPlan,
  });

  factory DischargeDiagnosis.fromJson(Map<String, dynamic> j) => DischargeDiagnosis(
        date: j['date']?.toString(),
        doctorName: j['doctor_name']?.toString(),
        chiefComplaint: j['chief_complaint']?.toString(),
        diagnosis: j['diagnosis']?.toString(),
        icd10Code: j['icd10_code']?.toString(),
        treatmentPlan: j['treatment_plan']?.toString(),
      );
}

class DischargeMedicine {
  final String? prescriptionNo;
  final String medicineName;
  final String? dosage;
  final String? frequency;
  final String? duration;

  const DischargeMedicine({
    this.prescriptionNo,
    required this.medicineName,
    this.dosage,
    this.frequency,
    this.duration,
  });

  factory DischargeMedicine.fromJson(Map<String, dynamic> j) => DischargeMedicine(
        prescriptionNo: j['prescription_no']?.toString(),
        medicineName: j['medicine_name']?.toString() ?? '',
        dosage: j['dosage']?.toString(),
        frequency: j['frequency']?.toString(),
        duration: j['duration']?.toString(),
      );

  String get instruction => [dosage, frequency, duration].where((s) => (s ?? '').isNotEmpty).join(' · ');
}

class DischargeTest {
  final String? orderNo;
  final String? testName;
  final String? status;

  const DischargeTest({this.orderNo, this.testName, this.status});

  factory DischargeTest.fromJson(Map<String, dynamic> j) => DischargeTest(
        orderNo: j['order_no']?.toString(),
        testName: j['test_name']?.toString(),
        status: j['status']?.toString(),
      );
}

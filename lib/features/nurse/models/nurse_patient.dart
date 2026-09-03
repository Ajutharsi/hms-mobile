class NursePatient {
  final int id;
  final String mrn;
  final String name;
  final String? phone;
  final String? gender;
  final String? dob;
  final String? bloodGroup;
  final String status;
  final String patientType;
  final String? photoUrl;
  final String? wardName;
  final String? bedNo;

  const NursePatient({
    required this.id,
    required this.mrn,
    required this.name,
    this.phone,
    this.gender,
    this.dob,
    this.bloodGroup,
    required this.status,
    required this.patientType,
    this.photoUrl,
    this.wardName,
    this.bedNo,
  });

  bool get isAdmitted => wardName != null;

  factory NursePatient.fromJson(Map<String, dynamic> json) => NursePatient(
        id: json['id'] as int,
        mrn: json['mrn']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString(),
        gender: json['gender']?.toString(),
        dob: json['dob']?.toString(),
        bloodGroup: json['blood_group']?.toString(),
        status: json['status']?.toString() ?? '',
        patientType: json['patient_type']?.toString() ?? '',
        photoUrl: json['photo_url']?.toString(),
        wardName: json['ward_name']?.toString(),
        bedNo: json['bed_no']?.toString(),
      );
}

class NursePatientAdmission {
  final int id;
  final String? admissionNo;
  final String? wardName;
  final String? bedNo;
  final String? doctorName;
  final String? admissionDate;

  const NursePatientAdmission({
    required this.id,
    this.admissionNo,
    this.wardName,
    this.bedNo,
    this.doctorName,
    this.admissionDate,
  });

  factory NursePatientAdmission.fromJson(Map<String, dynamic> json) => NursePatientAdmission(
        id: json['id'] as int,
        admissionNo: json['admission_no']?.toString(),
        wardName: json['ward_name']?.toString(),
        bedNo: json['bed_no']?.toString(),
        doctorName: json['doctor_name']?.toString(),
        admissionDate: json['admission_date']?.toString(),
      );
}

class NursePatientDetail {
  final int id;
  final String mrn;
  final String name;
  final String? phone;
  final String? email;
  final String? dob;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? emergencyContact;
  final String? emergencyContactName;
  final String status;
  final String patientType;
  final String? photoUrl;
  final NursePatientAdmission? admission;

  const NursePatientDetail({
    required this.id,
    required this.mrn,
    required this.name,
    this.phone,
    this.email,
    this.dob,
    this.gender,
    this.bloodGroup,
    this.address,
    this.emergencyContact,
    this.emergencyContactName,
    required this.status,
    required this.patientType,
    this.photoUrl,
    this.admission,
  });

  factory NursePatientDetail.fromJson(Map<String, dynamic> json) => NursePatientDetail(
        id: json['id'] as int,
        mrn: json['mrn']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString(),
        email: json['email']?.toString(),
        dob: json['dob']?.toString(),
        gender: json['gender']?.toString(),
        bloodGroup: json['blood_group']?.toString(),
        address: json['address']?.toString(),
        emergencyContact: json['emergency_contact']?.toString(),
        emergencyContactName: json['emergency_contact_name']?.toString(),
        status: json['status']?.toString() ?? '',
        patientType: json['patient_type']?.toString() ?? '',
        photoUrl: json['photo_url']?.toString(),
        admission: json['admission'] != null ? NursePatientAdmission.fromJson(json['admission'] as Map<String, dynamic>) : null,
      );
}

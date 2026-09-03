class ReceptionPatient {
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

  const ReceptionPatient({
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
  });

  factory ReceptionPatient.fromJson(Map<String, dynamic> json) => ReceptionPatient(
        id: json['id'] as int,
        mrn: json['mrn']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString(),
        gender: json['gender']?.toString(),
        dob: json['dob']?.toString(),
        bloodGroup: json['blood_group']?.toString(),
        status: json['status']?.toString() ?? 'active',
        patientType: json['patient_type']?.toString() ?? 'op',
        photoUrl: json['photo_url']?.toString(),
      );
}

class ReceptionPatientDetail extends ReceptionPatient {
  final String? email;
  final String? address;
  final String? emergencyContact;
  final String? emergencyContactName;
  final String? nationality;
  final String? maritalStatus;
  final String? occupation;

  const ReceptionPatientDetail({
    required super.id,
    required super.mrn,
    required super.name,
    super.phone,
    super.gender,
    super.dob,
    super.bloodGroup,
    required super.status,
    required super.patientType,
    super.photoUrl,
    this.email,
    this.address,
    this.emergencyContact,
    this.emergencyContactName,
    this.nationality,
    this.maritalStatus,
    this.occupation,
  });

  factory ReceptionPatientDetail.fromJson(Map<String, dynamic> json) => ReceptionPatientDetail(
        id: json['id'] as int,
        mrn: json['mrn']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString(),
        gender: json['gender']?.toString(),
        dob: json['dob']?.toString(),
        bloodGroup: json['blood_group']?.toString(),
        status: json['status']?.toString() ?? 'active',
        patientType: json['patient_type']?.toString() ?? 'op',
        photoUrl: json['photo_url']?.toString(),
        email: json['email']?.toString(),
        address: json['address']?.toString(),
        emergencyContact: json['emergency_contact']?.toString(),
        emergencyContactName: json['emergency_contact_name']?.toString(),
        nationality: json['nationality']?.toString(),
        maritalStatus: json['marital_status']?.toString(),
        occupation: json['occupation']?.toString(),
      );
}

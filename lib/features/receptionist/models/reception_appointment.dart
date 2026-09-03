class ReceptionAppointment {
  final int id;
  final String? appointmentId;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final int doctorId;
  final String? doctorName;
  final String? doctorSpecialization;
  final String date;
  final String time;
  final int? tokenNumber;
  final String type;
  final String status;
  final String? notes;

  const ReceptionAppointment({
    required this.id,
    this.appointmentId,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    required this.doctorId,
    this.doctorName,
    this.doctorSpecialization,
    required this.date,
    required this.time,
    this.tokenNumber,
    required this.type,
    required this.status,
    this.notes,
  });

  factory ReceptionAppointment.fromJson(Map<String, dynamic> json) => ReceptionAppointment(
        id: json['id'] as int,
        appointmentId: json['appointment_id']?.toString(),
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        doctorId: json['doctor_id'] as int,
        doctorName: json['doctor_name']?.toString(),
        doctorSpecialization: json['doctor_specialization']?.toString(),
        date: json['date']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
        tokenNumber: json['token_number'] as int?,
        type: json['type']?.toString() ?? 'consult',
        status: json['status']?.toString() ?? 'scheduled',
        notes: json['notes']?.toString(),
      );
}

class ReceptionDoctor {
  final int id;
  final String name;
  final String? specialization;

  const ReceptionDoctor({required this.id, required this.name, this.specialization});

  factory ReceptionDoctor.fromJson(Map<String, dynamic> json) => ReceptionDoctor(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        specialization: json['specialization']?.toString(),
      );
}

class AppointmentSlot {
  final String time;
  final bool available;

  const AppointmentSlot({required this.time, required this.available});

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) => AppointmentSlot(
        time: json['time']?.toString() ?? '',
        available: json['available'] == true,
      );
}

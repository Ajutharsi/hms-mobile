class Appointment {
  final int id;
  final String appointmentId;
  final String? doctorName;
  final String? doctorSpecialization;
  final String date;
  final String time;
  final String type;
  final String status;
  final int? tokenNumber;
  final String? notes;

  const Appointment({
    required this.id,
    required this.appointmentId,
    this.doctorName,
    this.doctorSpecialization,
    required this.date,
    required this.time,
    required this.type,
    required this.status,
    this.tokenNumber,
    this.notes,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as int,
        appointmentId: json['appointment_id']?.toString() ?? '',
        doctorName: json['doctor_name']?.toString(),
        doctorSpecialization: json['doctor_specialization']?.toString(),
        date: json['date']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        status: json['status']?.toString() ?? 'scheduled',
        tokenNumber: json['token_number'] as int?,
        notes: json['notes']?.toString(),
      );

  bool get isScheduled => status == 'scheduled';
}

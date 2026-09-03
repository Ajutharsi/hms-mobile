class ReceptionDashboardStats {
  final int todayAppointments;
  final int totalPatients;
  final int pendingInvoices;
  final int availableBeds;

  const ReceptionDashboardStats({
    required this.todayAppointments,
    required this.totalPatients,
    required this.pendingInvoices,
    required this.availableBeds,
  });

  factory ReceptionDashboardStats.fromJson(Map<String, dynamic> json) => ReceptionDashboardStats(
        todayAppointments: json['today_appointments'] as int? ?? 0,
        totalPatients: json['total_patients'] as int? ?? 0,
        pendingInvoices: json['pending_invoices'] as int? ?? 0,
        availableBeds: json['available_beds'] as int? ?? 0,
      );
}

class ReceptionDashboardAppointment {
  final int id;
  final String? patientName;
  final String? doctorName;
  final String time;
  final String type;

  const ReceptionDashboardAppointment({required this.id, this.patientName, this.doctorName, required this.time, required this.type});

  factory ReceptionDashboardAppointment.fromJson(Map<String, dynamic> json) => ReceptionDashboardAppointment(
        id: json['id'] as int,
        patientName: json['patient_name']?.toString(),
        doctorName: json['doctor_name']?.toString(),
        time: json['time']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
      );
}

class ReceptionDashboardPatient {
  final int id;
  final String name;
  final String mrn;
  final String status;
  final String? photoUrl;

  const ReceptionDashboardPatient({required this.id, required this.name, required this.mrn, required this.status, this.photoUrl});

  factory ReceptionDashboardPatient.fromJson(Map<String, dynamic> json) => ReceptionDashboardPatient(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        mrn: json['mrn']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        photoUrl: json['photo_url']?.toString(),
      );
}

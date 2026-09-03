class NurseDashboardStats {
  final int ipPatients;
  final int overdueRounds;
  final int foodLogsToday;
  final int fluidLogsToday;
  final int pendingMedications;
  final int needsVitalsCheck;
  final int nursingNotesToday;
  final int pendingHandovers;
  final int todaysHandovers;

  const NurseDashboardStats({
    required this.ipPatients,
    required this.overdueRounds,
    required this.foodLogsToday,
    required this.fluidLogsToday,
    required this.pendingMedications,
    required this.needsVitalsCheck,
    required this.nursingNotesToday,
    required this.pendingHandovers,
    required this.todaysHandovers,
  });

  factory NurseDashboardStats.fromJson(Map<String, dynamic> json) => NurseDashboardStats(
        ipPatients: json['ip_patients'] as int? ?? 0,
        overdueRounds: json['overdue_rounds'] as int? ?? 0,
        foodLogsToday: json['food_logs_today'] as int? ?? 0,
        fluidLogsToday: json['fluid_logs_today'] as int? ?? 0,
        pendingMedications: json['pending_medications'] as int? ?? 0,
        needsVitalsCheck: json['needs_vitals_check'] as int? ?? 0,
        nursingNotesToday: json['nursing_notes_today'] as int? ?? 0,
        pendingHandovers: json['pending_handovers'] as int? ?? 0,
        todaysHandovers: json['todays_handovers'] as int? ?? 0,
      );
}

class DashboardAppointment {
  final int id;
  final String? patientName;
  final String? doctorName;
  final String time;
  final String type;

  const DashboardAppointment({
    required this.id,
    this.patientName,
    this.doctorName,
    required this.time,
    required this.type,
  });

  factory DashboardAppointment.fromJson(Map<String, dynamic> json) => DashboardAppointment(
        id: json['id'] as int,
        patientName: json['patient_name']?.toString(),
        doctorName: json['doctor_name']?.toString(),
        time: json['time']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
      );
}

class DashboardPatient {
  final int id;
  final String name;
  final String mrn;
  final String status;
  final String? photoUrl;

  const DashboardPatient({
    required this.id,
    required this.name,
    required this.mrn,
    required this.status,
    this.photoUrl,
  });

  factory DashboardPatient.fromJson(Map<String, dynamic> json) => DashboardPatient(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        mrn: json['mrn']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        photoUrl: json['photo_url']?.toString(),
      );
}

/// Overview numbers shown at the top of the Profile screen — mirrors what
/// the web patient dashboard shows (App\Http\Controllers\Dashboard\
/// PatientDashboardController).
class ProfileStats {
  final int totalAppointments;
  final int todayAppointments;
  final int labOrders;

  const ProfileStats({
    required this.totalAppointments,
    required this.todayAppointments,
    required this.labOrders,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) => ProfileStats(
        totalAppointments: json['total_appointments'] as int? ?? 0,
        todayAppointments: json['today_appointments'] as int? ?? 0,
        labOrders: json['lab_orders'] as int? ?? 0,
      );
}

/// What `GET /patient/profile` and `POST /patient/profile` both return.
class PatientProfile {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profilePhotoUrl;
  final String? mrn;
  final ProfileStats stats;

  const PatientProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profilePhotoUrl,
    this.mrn,
    required this.stats,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return PatientProfile(
      id: user['id'] as int? ?? 0,
      name: user['name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      phone: user['phone']?.toString(),
      profilePhotoUrl: user['profile_photo_url']?.toString(),
      mrn: json['mrn']?.toString(),
      stats: ProfileStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
    );
  }
}

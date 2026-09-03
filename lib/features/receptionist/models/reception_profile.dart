class ReceptionProfile {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profilePhotoUrl;
  final String? department;

  const ReceptionProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profilePhotoUrl,
    this.department,
  });

  factory ReceptionProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return ReceptionProfile(
      id: user['id'] as int? ?? 0,
      name: user['name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      phone: user['phone']?.toString(),
      profilePhotoUrl: user['profile_photo_url']?.toString(),
      department: user['department']?.toString(),
    );
  }
}

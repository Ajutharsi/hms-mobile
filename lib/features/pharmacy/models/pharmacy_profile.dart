class PharmacyProfile {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profilePhotoUrl;
  final String? department;

  const PharmacyProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profilePhotoUrl,
    this.department,
  });

  factory PharmacyProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return PharmacyProfile(
      id: user['id'] as int? ?? 0,
      name: user['name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      phone: user['phone']?.toString(),
      profilePhotoUrl: user['profile_photo_url']?.toString(),
      department: user['department']?.toString(),
    );
  }
}

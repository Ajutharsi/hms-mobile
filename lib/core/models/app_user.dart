/// The logged-in account — mirrors the `user` object every auth endpoint
/// (`/login`, `/register`, `/me`) returns.
class AppUser {
  final int id;
  final String name;
  final String email;
  final List<String> roles;
  final bool mustChangePassword;
  final String? profilePhotoUrl;

  /// The hospital this account belongs to, as the server reports it.
  /// Carried on the user because only an administrator may read
  /// /admin/settings, and every role needs the currency to show money.
  final String? hospitalName;
  final String? currency;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    required this.mustChangePassword,
    this.profilePhotoUrl,
    this.hospitalName,
    this.currency,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        roles: (json['roles'] as List? ?? []).map((r) => r.toString()).toList(),
        mustChangePassword: json['must_change_password'] == true,
        profilePhotoUrl: json['profile_photo_url']?.toString(),
        hospitalName: (json['hospital'] as Map?)?['name']?.toString(),
        currency: (json['hospital'] as Map?)?['currency']?.toString(),
      );

  String get firstName => name.split(' ').first;
  String get primaryRole => roles.isNotEmpty ? roles.first : 'user';
}

import 'package:hms_mobile/core/models/app_user.dart';

/// What `/login` and `/register` both return: a bearer token plus the
/// account it belongs to.
class AuthResult {
  final String token;
  final AppUser user;

  const AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: json['token'] as String,
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

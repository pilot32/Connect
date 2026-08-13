/// The account record behind a profile.
///
/// [email] is only ever populated for the signed-in user — the API deliberately
/// omits it from other people's profiles, so it is empty for anyone else.
class AuthUser {
  const AuthUser({required this.id, required this.email});

  final String id;
  final String email;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

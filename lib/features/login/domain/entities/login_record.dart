class LoginRecord {
  const LoginRecord({
    required this.id,
    required this.email,
    required this.displayName,
    required this.passwordHash,
  });

  final String id;
  final String email;
  final String displayName;
  final String passwordHash;
}

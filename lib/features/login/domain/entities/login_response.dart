class LoginResponse {
  const LoginResponse({
    required this.refresh,
    required this.access,
    this.userId,
    this.email,
    this.displayName,
  });

  final String refresh;
  final String access;
  final String? userId;
  final String? email;
  final String? displayName;
}

abstract class PasswordConfirmRepository {
  Future<void> confirmPassword({
    required String token,
    required String password,
    String? email,
  });
}

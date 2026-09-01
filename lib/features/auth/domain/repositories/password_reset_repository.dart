abstract class PasswordResetRepository {
  Future<void> requestPasswordReset({required String email});
}

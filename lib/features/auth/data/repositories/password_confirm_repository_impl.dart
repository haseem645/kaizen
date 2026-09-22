import '../../domain/repositories/password_confirm_repository.dart';
import '../datasources/password_confirm_remote_data_source.dart';

class PasswordConfirmRepositoryImpl implements PasswordConfirmRepository {
  const PasswordConfirmRepositoryImpl(this._remoteDataSource);

  final PasswordConfirmRemoteDataSource _remoteDataSource;

  @override
  Future<void> confirmPassword({
    required String token,
    required String password,
    String? email,
  }) {
    return _remoteDataSource.confirmPassword(
      token: token,
      password: password,
      email: email,
    );
  }
}

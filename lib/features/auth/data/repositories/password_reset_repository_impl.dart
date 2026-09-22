import '../../domain/repositories/password_reset_repository.dart';
import '../datasources/password_reset_remote_data_source.dart';

class PasswordResetRepositoryImpl implements PasswordResetRepository {
  const PasswordResetRepositoryImpl(this._remoteDataSource);

  final PasswordResetRemoteDataSource _remoteDataSource;

  @override
  Future<void> requestPasswordReset({required String email}) {
    return _remoteDataSource.requestPasswordReset(email: email);
  }
}

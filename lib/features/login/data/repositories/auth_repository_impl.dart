import 'package:sparrowkaizen/core/preference/app_preference.dart';

import '../../domain/entities/login_response.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<LoginResponse> login({required String email, required String password}) {
    return _remoteDataSource.login(email: email, password: password);
  }

  @override
  Future<User> fetchUserDetail({required String accessToken}) {
    return _remoteDataSource.fetchUserDetail(accessToken: accessToken);
  }

  @override
  Future<void> saveUserProfile(User user) {
    return AppPreference.saveUser(user);
  }
}

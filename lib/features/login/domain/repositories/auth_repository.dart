import '../entities/login_response.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<LoginResponse> login({required String email, required String password});

  Future<User> fetchUserDetail({required String accessToken});

  Future<void> saveUserProfile(User user);
}

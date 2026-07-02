import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/login_record.dart';

class LoginRecordModel extends LoginRecord {
  const LoginRecordModel({
    required super.id,
    required super.email,
    required super.displayName,
    required super.passwordHash,
  });

  factory LoginRecordModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim();
    final email = (json['email'] as String?)?.trim();
    final displayName = (json['name'] as String?)?.trim();
    final passwordHash = (json['passwordHash'] as String?)?.trim();

    if (id == null ||
        id.isEmpty ||
        email == null ||
        email.isEmpty ||
        displayName == null ||
        displayName.isEmpty ||
        passwordHash == null ||
        passwordHash.isEmpty) {
      throw const FormatException(AppStrings.userRecordIncomplete);
    }

    return LoginRecordModel(
      id: id,
      email: email,
      displayName: displayName,
      passwordHash: passwordHash,
    );
  }
}

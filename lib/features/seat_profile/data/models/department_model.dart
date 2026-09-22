import '../../domain/entities/department.dart';

class DepartmentModel extends Department {
  const DepartmentModel({
    required super.id,
    required super.name,
    super.colorHex,
    super.fromSandbox,
    super.driveId,
  });

  factory DepartmentModel.fromApiJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['uuid']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      colorHex: json['color_hex']?.toString().trim(),
      fromSandbox: json.containsKey('from_sandbox')
          ? json['from_sandbox']
          : json['fromSandbox'],
      driveId: json['drive_id']?.toString().trim(),
    );
  }
}

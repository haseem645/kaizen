import '../../domain/entities/department.dart';

class DepartmentModel extends Department {
  const DepartmentModel({required super.id, required super.name});

  factory DepartmentModel.fromApiJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['uuid']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
    );
  }
}

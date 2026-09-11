import 'package:flutter/material.dart';

import '../../../../core/widgets/app_department_filter_strip.dart';
import '../controllers/training_library_controller.dart';

class TrainingLibraryDepartmentFilterStrip extends StatelessWidget {
  const TrainingLibraryDepartmentFilterStrip({
    super.key,
    required this.controller,
    required this.onSeeAll,
  });

  final TrainingLibraryController controller;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return AppDepartmentFilterStrip(
      items: controller.departmentTabs
          .map((item) => AppDepartmentFilterItem(id: item.id, name: item.name))
          .toList(growable: false),
      selectedDepartmentId: controller.selectedDepartmentId,
      onSelected: controller.selectDepartment,
      onSeeAll: onSeeAll,
    );
  }
}

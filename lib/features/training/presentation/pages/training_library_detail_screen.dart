import 'package:flutter/material.dart';

import '../../../../core/managers/app_manager.dart';
import '../../../check_in/data/datasources/audit_remote_data_source.dart';
import '../../../check_in/data/repositories/audit_repository_impl.dart';
import '../../data/datasources/training_library_remote_data_source.dart';
import '../../data/repositories/training_library_repository_impl.dart';
import '../../domain/entities/training_library_module.dart';
import '../../domain/usecases/get_training_library_modules_usecase.dart';
import '../controllers/training_library_detail_controller.dart';
import '../widgets/training_library_detail_view.dart';
import '../widgets/training_library_lesson_actions_sheet.dart';
import '../widgets/training_library_lesson_delete_dialog.dart';
import '../widgets/training_library_lesson_selection_sheet.dart';
import '../widgets/training_library_lesson_visibility_sheet.dart';
import 'edit_training_screen.dart';
import 'view_training_screen.dart';

class TrainingLibraryDetailScreen extends StatefulWidget {
  const TrainingLibraryDetailScreen({super.key, required this.module, required this.view});

  final TrainingLibraryModule module;
  final String view;

  @override
  State<TrainingLibraryDetailScreen> createState() => _TrainingLibraryDetailScreenState();
}

class _TrainingLibraryDetailScreenState extends State<TrainingLibraryDetailScreen> {
  late final TrainingLibraryDetailController _detailController;

  @override
  void initState() {
    super.initState();
    final auditRepository = AuditRepositoryImpl(AuditRemoteDataSource());
    _detailController = TrainingLibraryDetailController(
      initialModule: widget.module,
      getTrainingLibraryModules: GetTrainingLibraryModulesUseCase(
        createTrainingLibraryRepository(createTrainingLibraryRemoteDataSource()),
      ),
      auditRepository: auditRepository,
      canManageSeatTraining: (seatProfileId) => AppManager.instance
          .canCurrentUserManageTrainingForSeatProfile(seatProfileId: seatProfileId),
      view: widget.view,
    );
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _detailController;

    return AnimatedBuilder(
      animation: Listenable.merge([controller, AppManager.instance]),
      builder: (context, _) => TrainingLibraryDetailView(
        controller: controller,
        onBack: () => Navigator.of(context).pop(controller.navigationResult),
        onSelectLesson: () => controller.selectLesson(
          select: (lessons) => showTrainingLibraryLessonSelectionSheet(context, lessons: lessons),
          openViewer: (route) => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => ViewTrainingScreen(trainingRoute: route)),
          ),
        ),
        onLessonTap: (lesson) => controller.openLessonViewer(
          lesson,
          openViewer: (route) => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => ViewTrainingScreen(trainingRoute: route)),
          ),
        ),
        onLessonActions: (lesson) => controller.showLessonActions(
          lesson,
          selectAction: (canEdit, isPubliclyAvailable) => showTrainingLibraryLessonActionsSheet(
            context,
            canEdit: canEdit,
            isPubliclyAvailable: isPubliclyAvailable,
          ),
          openEditor: (route, lessonId, canManageTraining) => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => EditTrainingScreen(
                trainingRoute: route,
                initialModuleId: lessonId,
                canManageTraining: canManageTraining,
                useNonBlockingVideoUpload: true,
              ),
            ),
          ),
          showVisibility: (lesson) => showTrainingLibraryLessonVisibilitySheet(
            context,
            lesson: lesson,
            controller: controller.visibilityController,
            onApply: (value) =>
                controller.updateLessonVisibility(lesson: lesson, isPubliclyAvailable: value),
          ),
          confirmDelete: (lesson) => showTrainingLibraryLessonDeleteDialog(
            context,
            lesson: lesson,
            controller: controller,
          ),
          showMessage: (message) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          },
        ),
      ),
    );
  }
}

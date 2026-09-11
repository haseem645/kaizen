import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/features/check_in/domain/repositories/audit_repository.dart';
import 'package:sparrowkaizen/features/training/domain/entities/seat_description_training.dart';
import 'package:sparrowkaizen/features/training/presentation/controllers/training_module_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _DraftRepository repository;
  late TrainingModuleController controller;

  setUp(() async {
    repository = _DraftRepository();
    controller = TrainingModuleController(repository, canManageTraining: true);
    await controller.initialize(
      jobId: 'seat',
      descriptionId: 'description',
      initialModuleId: 'second',
    );
  });

  tearDown(() => controller.dispose());

  test(
    'cancelling a new lesson clears its title and restores the previously selected lesson',
    () async {
      controller.startCreatingNewLessonDraft();
      controller.newLessonTitleController.text = 'Unsaved lesson';
      expect(controller.isCreatingNewLessonDraft, isTrue);
      expect(controller.hasSelectedModule, isFalse);

      await controller.cancelCreatingNewLessonDraft();

      expect(controller.isCreatingNewLessonDraft, isFalse);
      expect(controller.newLessonTitleController.text, isEmpty);
      expect(controller.selectedModuleId, 'second');
      expect(controller.selectedModuleDetail?.uuid, 'second');
      expect(controller.moduleTitleController.text, 'second');
      expect(controller.canAccessSelectedModuleExtras, isTrue);
      expect(controller.modules, hasLength(2));
      expect(repository.createRequests, 0);
    },
  );

  test('cancelling with no saved lessons returns to the empty state', () async {
    repository.modules.clear();
    await controller.initialize(jobId: 'seat', descriptionId: 'description');
    controller.startCreatingNewLessonDraft();
    controller.newLessonTitleController.text = 'Unsaved first lesson';

    await controller.cancelCreatingNewLessonDraft();

    expect(controller.isCreatingNewLessonDraft, isFalse);
    expect(controller.newLessonTitleController.text, isEmpty);
    expect(controller.hasSelectedModule, isFalse);
    expect(controller.modules, isEmpty);
    expect(controller.errorMessage, isNull);
    expect(repository.createRequests, 0);

    controller.startCreatingNewLessonDraft();
    expect(controller.isCreatingNewLessonDraft, isTrue);
  });

  test('repeated New Lesson taps retain the original selection for cancellation', () async {
    controller.startCreatingNewLessonDraft();
    controller.startCreatingNewLessonDraft();
    await controller.cancelCreatingNewLessonDraft();
    expect(controller.selectedModuleId, 'second');

    await controller.selectModule('first');
    controller.startCreatingNewLessonDraft();
    await controller.cancelCreatingNewLessonDraft();
    expect(controller.selectedModuleId, 'first');
    expect(repository.createRequests, 0);
  });

  test('cancelling outside a draft leaves the current lesson unchanged', () async {
    final detail = controller.selectedModuleDetail;
    final fetchCount = repository.detailRequests;

    await controller.cancelCreatingNewLessonDraft();

    expect(controller.selectedModuleDetail, same(detail));
    expect(controller.selectedModuleId, 'second');
    expect(repository.detailRequests, fetchCount);
  });

  test('Back cannot cancel a lesson while its create request is running', () async {
    repository.pendingCreate = Completer<SeatDescriptionTrainingModule>();
    controller.startCreatingNewLessonDraft();
    controller.newLessonTitleController.text = 'New lesson';
    final creation = controller.createModuleFromDraft();
    expect(controller.isCreatingModule, isTrue);

    await controller.cancelCreatingNewLessonDraft();
    expect(controller.isCreatingNewLessonDraft, isTrue);
    expect(controller.newLessonTitleController.text, 'New lesson');

    repository.pendingCreate!.complete(_lesson('created'));
    expect(await creation, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(controller.isCreatingModule, isFalse);
    expect(controller.isCreatingNewLessonDraft, isFalse);
    expect(controller.selectedModuleId, 'created');
    expect(repository.createRequests, 1);
  });
}

SeatDescriptionTrainingModule _lesson(String id) => SeatDescriptionTrainingModule(
  uuid: id,
  actualId: id,
  title: id,
  thumbnailLink: null,
  isPubliclyAvailable: false,
);

class _DraftRepository extends Fake implements AuditRepository {
  final modules = [_lesson('first'), _lesson('second')];
  int createRequests = 0;
  int detailRequests = 0;
  Completer<SeatDescriptionTrainingModule>? pendingCreate;

  @override
  Future<List<SeatDescriptionTrainingModule>> getSeatDescriptionTrainingModules({
    required String descriptionId,
    bool forceRefresh = false,
  }) async => List<SeatDescriptionTrainingModule>.of(modules);

  @override
  Future<SeatDescriptionTrainingModule> createSeatDescriptionTrainingModule({
    required String jobId,
    required String descriptionId,
    required String title,
  }) async {
    createRequests += 1;
    final module = await pendingCreate!.future;
    modules.add(module);
    return module;
  }

  @override
  Future<SeatDescriptionTrainingModuleDetail> getSeatDescriptionTrainingModuleDetail({
    required String moduleId,
  }) async {
    detailRequests += 1;
    return SeatDescriptionTrainingModuleDetail(
      uuid: moduleId,
      actualId: moduleId,
      title: moduleId,
      thumbnails: const [],
      description: null,
      assignmentTitle: null,
      assignmentInstructions: null,
      questions: const [],
      thumbnailLink: null,
      trainingVideo: null,
      isPubliclyAvailable: false,
      learningTrackCount: 0,
    );
  }
}

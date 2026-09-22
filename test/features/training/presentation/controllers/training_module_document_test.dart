import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/features/check_in/domain/repositories/audit_repository.dart';
import 'package:sparrowkaizen/features/training/domain/entities/seat_description_training.dart';
import 'package:sparrowkaizen/features/training/presentation/controllers/training_module_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _DocumentRepository repository;
  late TrainingModuleController controller;

  setUp(() async {
    repository = _DocumentRepository();
    controller = TrainingModuleController(repository);
    await controller.initialize(jobId: 'seat', descriptionId: 'description');
  });
  tearDown(() => controller.dispose());

  test('an unloaded SOP remains unresolved until the API confirms empty content', () async {
    expect(controller.hasResolvedSelectedModuleDocument, isFalse);
    final loading = controller.loadDocumentForSelectedModule();
    expect(controller.isDocumentLoading, isTrue);
    expect(controller.hasResolvedSelectedModuleDocument, isFalse);
    await controller.loadDocumentForSelectedModule();
    expect(repository.requests, hasLength(1));

    repository.requests.single.complete(
      const SeatDescriptionTrainingDocument(uuid: '', text: null),
    );
    await loading;
    expect(controller.isDocumentLoading, isFalse);
    expect(controller.hasResolvedSelectedModuleDocument, isTrue);
    expect(controller.selectedModuleDocument!.text, isNull);

    await controller.loadDocumentForSelectedModule();
    expect(repository.requests, hasLength(1));
  });

  test('a completed request publishes SOP content and its editor text', () async {
    final loading = controller.loadDocumentForSelectedModule();
    repository.requests.single.complete(
      const SeatDescriptionTrainingDocument(uuid: 'document', text: '<p>Follow the procedure.</p>'),
    );
    await loading;
    expect(controller.hasResolvedSelectedModuleDocument, isTrue);
    expect(controller.isDocumentLoading, isFalse);
    expect(controller.documentController.text, 'Follow the procedure.');
  });

  test('an API failure resolves to an error and a retry returns to loading', () async {
    final loading = controller.loadDocumentForSelectedModule();
    repository.requests.single.completeError(StateError('Unable to load SOP'));
    await loading;
    expect(controller.hasResolvedSelectedModuleDocument, isTrue);
    expect(controller.documentErrorMessage, contains('Unable to load SOP'));
    expect(controller.isDocumentLoading, isFalse);

    final retry = controller.loadDocumentForSelectedModule();
    expect(controller.documentErrorMessage, isNull);
    expect(controller.hasResolvedSelectedModuleDocument, isFalse);
    expect(controller.isDocumentLoading, isTrue);
    repository.requests.last.complete(const SeatDescriptionTrainingDocument(uuid: '', text: null));
    await retry;
  });

  test('a previous lesson response cannot replace the current SOP or stop its loader', () async {
    final firstLoading = controller.loadDocumentForSelectedModule();
    await controller.selectModule('second');
    expect(controller.hasResolvedSelectedModuleDocument, isFalse);
    final secondLoading = controller.loadDocumentForSelectedModule();
    expect(repository.requests, hasLength(2));

    repository.requests.first.complete(
      const SeatDescriptionTrainingDocument(uuid: 'old', text: '<p>Old lesson</p>'),
    );
    await firstLoading;
    expect(controller.selectedModuleDocument, isNull);
    expect(controller.isDocumentLoading, isTrue);
    expect(controller.hasResolvedSelectedModuleDocument, isFalse);

    repository.requests.last.complete(
      const SeatDescriptionTrainingDocument(uuid: 'current', text: '<p>Current lesson</p>'),
    );
    await secondLoading;
    expect(controller.selectedModuleDocument!.uuid, 'current');
    expect(controller.documentController.text, 'Current lesson');
    expect(controller.isDocumentLoading, isFalse);
  });
}

class _DocumentRepository extends Fake implements AuditRepository {
  final requests = <Completer<SeatDescriptionTrainingDocument>>[];

  @override
  Future<SeatDescriptionTrainingDocument> getSeatDescriptionTrainingModuleDocument({
    required String moduleId,
  }) {
    final request = Completer<SeatDescriptionTrainingDocument>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<List<SeatDescriptionTrainingModule>> getSeatDescriptionTrainingModules({
    required String descriptionId,
    bool forceRefresh = false,
  }) async => const [
    SeatDescriptionTrainingModule(
      uuid: 'first',
      actualId: 'first',
      title: 'First lesson',
      thumbnailLink: null,
      isPubliclyAvailable: false,
    ),
    SeatDescriptionTrainingModule(
      uuid: 'second',
      actualId: 'second',
      title: 'Second lesson',
      thumbnailLink: null,
      isPubliclyAvailable: false,
    ),
  ];

  @override
  Future<SeatDescriptionTrainingModuleDetail> getSeatDescriptionTrainingModuleDetail({
    required String moduleId,
  }) async => SeatDescriptionTrainingModuleDetail(
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

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparrowkaizen/core/network/api_processor.dart';
import 'package:sparrowkaizen/core/preference/app_preference.dart';
import 'package:sparrowkaizen/features/check_in/data/datasources/audit_remote_data_source.dart';
import 'package:sparrowkaizen/features/check_in/data/repositories/audit_repository_impl.dart';
import 'package:sparrowkaizen/features/training/presentation/controllers/training_module_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _DescriptionApi api;
  late TrainingModuleController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreference.init();
    api = _DescriptionApi();
    controller = TrainingModuleController(
      AuditRepositoryImpl(AuditRemoteDataSource(apiCallExecutor: api)),
      canManageTraining: true,
    );
    await controller.initialize(jobId: 'seat', descriptionId: 'description');
  });
  tearDown(() => controller.dispose());

  for (final emptyDescription in <String?>[null, '', '   ', '<p><br>&nbsp;</p>']) {
    testWidgets('empty summaries stay blank without saving placeholder text: $emptyDescription', (
      tester,
    ) async {
      api.descriptions['first'] = emptyDescription;
      await controller.initialize(jobId: 'seat', descriptionId: 'description');

      expect(controller.summaryController.text, isEmpty);
      expect(controller.isEditingSummary, isFalse);
      controller.startEditingSummary();
      expect(controller.isEditingSummary, isTrue);
      expect(controller.summaryController.text, isEmpty);
      await tester.pump(const Duration(milliseconds: 700));
      expect(api.patches, isEmpty);
    });
  }

  testWidgets('tapping an already active summary keeps its unsaved text', (tester) async {
    controller.startEditingSummary();
    controller.summaryController.text = 'Unsaved typing';
    controller.startEditingSummary();
    expect(controller.summaryController.text, 'Unsaved typing');
    await tester.pump(const Duration(milliseconds: 700));
    expect(api.patches.single.parameters, {'description': 'Unsaved typing'});
    api.patches.single.complete();
    await tester.pump();
  });

  testWidgets('typing debounces a description-only PATCH to the selected lesson', (tester) async {
    await tester.pump(const Duration(milliseconds: 700));
    expect(api.patches, isEmpty);

    controller.summaryController.text = 'First draft';
    await tester.pump(const Duration(milliseconds: 400));
    controller.summaryController.text = 'Latest draft';
    await tester.pump(const Duration(milliseconds: 699));
    expect(api.patches, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));

    expect(api.patches.single.endpoint, 'training_modules/first/');
    expect(api.patches.single.parameters, {'description': 'Latest draft'});
    api.patches.single.complete();
    await tester.pump();
    expect(controller.selectedModuleDetail!.description, 'Latest draft');
    await tester.pump(const Duration(seconds: 1));
    expect(api.patches, hasLength(1));
  });

  testWidgets('a slow save preserves newer typing and the cursor, then saves it in order', (
    tester,
  ) async {
    controller.summaryController.text = 'First draft';
    await tester.pump(const Duration(milliseconds: 700));
    controller.summaryController.value = const TextEditingValue(
      text: 'More typing',
      selection: TextSelection.collapsed(offset: 4),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(api.patches, hasLength(1));

    api.patches.first.complete();
    await tester.pump();
    expect(controller.summaryController.text, 'More typing');
    expect(controller.summaryController.selection.baseOffset, 4);
    await tester.pump(const Duration(milliseconds: 700));
    expect(api.patches, hasLength(2));
    expect(api.patches.last.parameters, {'description': 'More typing'});
    api.patches.last.complete();
    await tester.pump();
    expect(controller.selectedModuleDetail!.description, 'More typing');
    expect(controller.isSavingSummary, isFalse);
  });

  testWidgets('clearing the description sends an empty description', (tester) async {
    controller.summaryController.clear();
    await tester.pump(const Duration(milliseconds: 700));
    expect(api.patches.single.parameters, {'description': ''});
    api.patches.single.complete();
    await tester.pump();
    expect(controller.summaryController.text, isEmpty);
    expect(controller.selectedModuleDetail!.description, isNull);
  });

  testWidgets('a previous lesson save cannot alter the current description or saving state', (
    tester,
  ) async {
    controller.summaryController.text = 'First lesson edit';
    await tester.pump(const Duration(milliseconds: 700));
    await controller.selectModule('second');
    controller.summaryController.text = 'Second lesson edit';
    await tester.pump(const Duration(milliseconds: 700));
    expect(api.patches, hasLength(2));

    api.patches.first.complete();
    await tester.pump();
    expect(controller.summaryController.text, 'Second lesson edit');
    expect(controller.selectedModuleDetail!.description, 'Original second');
    expect(controller.isSavingSummary, isTrue);
    expect(api.patches.last.endpoint, 'training_modules/second/');
    api.patches.last.complete();
    await tester.pump();
    expect(controller.selectedModuleDetail!.description, 'Second lesson edit');
    expect(controller.isSavingSummary, isFalse);
  });

  testWidgets('failed writes keep the draft and wait for another edit before retrying', (
    tester,
  ) async {
    controller.summaryController.text = 'Unsaved draft';
    await tester.pump(const Duration(milliseconds: 700));
    api.patches.single.completeError(StateError('Unable to save'));
    await tester.pump();
    expect(controller.summaryController.text, 'Unsaved draft');
    expect(controller.summarySnackBarMessage, contains('Unable to save'));
    expect(controller.isSavingSummary, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(api.patches, hasLength(1));

    controller.summaryController.text = 'Revised draft';
    await tester.pump(const Duration(milliseconds: 700));
    expect(api.patches, hasLength(2));
    api.patches.last.complete();
    await tester.pump();
    expect(controller.selectedModuleDetail!.description, 'Revised draft');
  });
}

class _DescriptionPatch {
  _DescriptionPatch(this.endpoint, this.parameters);

  final String endpoint;
  final Map<String, dynamic>? parameters;
  final Completer<void> _response = Completer<void>();

  Future<void> get future => _response.future;
  void complete() => _response.complete();
  void completeError(Object error) => _response.completeError(error);
}

class _DescriptionApi extends ApiCallExecutor {
  final patches = <_DescriptionPatch>[];
  final descriptions = <String, String?>{};

  @override
  Future<Response> processApi<Response>({
    required ApiCallType apiCallType,
    required String endpoint,
    required Response Function(dynamic json) decoder,
    Map<String, dynamic>? parameters,
    Map<String, String>? headers,
    String? authToken,
    bool allowAutoRefresh = true,
    bool allowConflictRetry = true,
    bool invalidateCacheBeforeRequest = false,
  }) async {
    if (apiCallType == ApiCallType.patch) {
      final patch = _DescriptionPatch(endpoint, parameters);
      patches.add(patch);
      await patch.future;
      return decoder(null);
    }
    expect(apiCallType, ApiCallType.get);
    if (endpoint == 'job_category_description/description/training_modules/') {
      return decoder([_module('first'), _module('second')]);
    }
    return decoder(_module(endpoint.split('/')[1]));
  }

  Map<String, dynamic> _module(String id) => {
    'uuid': id,
    'actual_id': 'parent-$id',
    'title': 'Lesson $id',
    'description': descriptions.containsKey(id) ? descriptions[id] : 'Original $id',
    'training_video': {'uuid': 'video-$id', 'url': 'https://example.com/$id.mp4'},
  };
}

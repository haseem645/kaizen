// ignore_for_file: depend_on_referenced_packages

import 'package:sparrowkaizen/core/network/api_processor.dart';
import 'package:sparrowkaizen/features/training/data/datasources/training_library_remote_data_source.dart';
import 'package:sparrowkaizen/features/training/data/models/training_library_page_model.dart';
import 'package:test/test.dart';

void main() {
  group('TrainingLibraryRemoteDataSource.getTrainingLibraryModules', () {
    test('does not send page or page_size query parameters', () async {
      final apiCallExecutor = _CapturingApiCallExecutor();
      final dataSource = TrainingLibraryRemoteDataSource(
        apiCallExecutor: apiCallExecutor,
      );

      await dataSource.getTrainingLibraryModules(
        view: 'list',
        page: 1,
        pageSize: 10,
        searchType: 'category',
        searchText: ' safety ',
      );

      expect(apiCallExecutor.capturedParameters, <String, dynamic>{
        'view': 'list',
        'searchType': 'category',
        'searchText': 'safety',
      });
    });

    test('attaches department when a department filter is selected', () async {
      final apiCallExecutor = _CapturingApiCallExecutor();
      final dataSource = TrainingLibraryRemoteDataSource(
        apiCallExecutor: apiCallExecutor,
      );

      await dataSource.getTrainingLibraryModules(
        view: 'list',
        page: 1,
        pageSize: 10,
        searchType: 'category',
        departmentId: 'department-42',
      );

      expect(apiCallExecutor.capturedParameters, <String, dynamic>{
        'view': 'list',
        'searchType': 'category',
        'department': 'department-42',
      });
    });
  });

  group('TrainingLibraryPageModel.fromApiJson', () {
    test('treats list-style responses as non-paginated without metadata', () {
      final page = TrainingLibraryPageModel.fromApiJson(<String, dynamic>{
        'results': <Map<String, dynamic>>[
          _moduleJson(id: '1'),
          _moduleJson(id: '2'),
          _moduleJson(id: '3'),
          _moduleJson(id: '4'),
          _moduleJson(id: '5'),
          _moduleJson(id: '6'),
          _moduleJson(id: '7'),
          _moduleJson(id: '8'),
          _moduleJson(id: '9'),
          _moduleJson(id: '10'),
        ],
      }, pageSize: 10);

      expect(page.items, hasLength(10));
      expect(page.hasNextPage, isFalse);
    });

    test('keeps honoring explicit next-page metadata', () {
      final page = TrainingLibraryPageModel.fromApiJson(<String, dynamic>{
        'results': <Map<String, dynamic>>[_moduleJson(id: '1')],
        'next':
            'https://dev-api.kaizenteams.ai/api/v1/training_modules/all/?view=list&searchType=category',
      }, pageSize: 10);

      expect(page.hasNextPage, isTrue);
    });
  });
}

class _CapturingApiCallExecutor extends ApiCallExecutor {
  Map<String, dynamic>? capturedParameters;

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
    capturedParameters = parameters;
    return decoder(<String, dynamic>{
      'results': const <Map<String, dynamic>>[],
    });
  }
}

Map<String, dynamic> _moduleJson({required String id}) {
  return <String, dynamic>{
    'id': id,
    'title': 'Module $id',
    'description': 'Description $id',
    'department': <String, dynamic>{'id': 'dep-1', 'name': 'Operations'},
    'seat': <String, dynamic>{'id': 'seat-1', 'title': 'Lead'},
    'category': <String, dynamic>{'id': 'cat-1', 'name': 'Safety'},
    'lessons': const <Map<String, dynamic>>[],
  };
}

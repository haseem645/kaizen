import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/features/seat_profile/domain/entities/seat_profile.dart';
import 'package:sparrowkaizen/features/seat_profile/domain/entities/seat_profile_page.dart';
import 'package:sparrowkaizen/features/seat_profile/domain/repositories/seat_profile_repository.dart';
import 'package:sparrowkaizen/features/seat_profile/domain/usecases/get_seat_profiles_usecase.dart';
import 'package:sparrowkaizen/features/training/domain/entities/training_library_module.dart';
import 'package:sparrowkaizen/features/training/domain/entities/training_library_page.dart';
import 'package:sparrowkaizen/features/training/domain/repositories/training_library_repository.dart';
import 'package:sparrowkaizen/features/training/domain/usecases/get_training_library_modules_usecase.dart';
import 'package:sparrowkaizen/features/training/presentation/controllers/training_library_controller.dart';

void main() {
  late _LibraryRepository repository;
  late _SeatRepository seatRepository;
  late TrainingLibraryController controller;
  late bool canCreateTraining;

  setUp(() async {
    repository = _LibraryRepository();
    seatRepository = _SeatRepository();
    canCreateTraining = false;
    controller = TrainingLibraryController(
      GetTrainingLibraryModulesUseCase(repository),
      getSeatProfilesUseCase: GetSeatProfilesUseCase(seatRepository),
      canCreateTraining: () => canCreateTraining,
    );
    await controller.initialize();
  });

  tearDown(() => controller.dispose());

  test(
    'opening detail refreshes only after a changed result returns',
    () async {
      await controller.changeViewMode(TrainingLibraryViewMode.grid);
      final module = controller.items.first;
      final requestsBeforeOpening = repository.requests;
      for (final result in [null, false]) {
        await controller.openLibraryDetail(
          module,
          openDetail: (selectedModule, view) async {
            expect(selectedModule, same(module));
            expect(view, 'grid');
            return result;
          },
        );
      }
      expect(repository.requests, requestsBeforeOpening);

      final closed = Completer<bool?>();
      final opening = controller.openLibraryDetail(
        module,
        openDetail: (_, __) => closed.future,
      );
      expect(repository.requests, requestsBeforeOpening);
      closed.complete(true);
      await opening;
      expect(repository.requests, requestsBeforeOpening + 1);
    },
  );

  test(
    'a detail result cannot refresh a disposed library controller',
    () async {
      final detached = TrainingLibraryController(
        GetTrainingLibraryModulesUseCase(repository),
        getSeatProfilesUseCase: GetSeatProfilesUseCase(seatRepository),
      );
      final closed = Completer<bool?>();
      final requestsBeforeOpening = repository.requests;
      final opening = detached.openLibraryDetail(
        controller.items.first,
        openDetail: (_, __) => closed.future,
      );
      detached.dispose();
      closed.complete(true);
      await opening;
      expect(repository.requests, requestsBeforeOpening);
    },
  );

  test('create rechecks the current shared permission before opening', () {
    var opened = 0;
    controller.openCreateFlow(onOpen: () => opened++);
    expect(opened, 0);
    canCreateTraining = true;
    expect(controller.canCreateTraining, isTrue);
    controller.openCreateFlow(onOpen: () => opened++);
    expect(opened, 1);
    canCreateTraining = false;
    controller.openCreateFlow(onOpen: () => opened++);
    expect(opened, 1);
  });

  test(
    'selecting All keeps departments visible until the refresh finishes',
    () async {
      await controller.selectDepartment('sales');
      final response = Completer<TrainingLibraryPage>();
      repository.respond = () => response.future;

      final refresh = controller.selectDepartment('all');

      expect(controller.selectedDepartmentId, 'all');
      expect(controller.isRefreshing, isTrue);
      expect(controller.departments.map((department) => department.id), [
        'operations',
        'sales',
      ]);
      expect(controller.departmentOptions, controller.departments);

      response.complete(
        TrainingLibraryPage(
          items: [_module('new', _seatC, 'support')],
          hasNextPage: false,
        ),
      );
      await refresh;

      expect(controller.isRefreshing, isFalse);
      expect(controller.departments.map((department) => department.id), [
        'support',
      ]);
      expect(controller.visibleItems.map((module) => module.id), ['new']);
    },
  );

  test(
    'a failed All refresh preserves the available department choices',
    () async {
      await controller.selectDepartment('sales');
      final response = Completer<TrainingLibraryPage>();
      repository.respond = () => response.future;

      final refresh = controller.selectDepartment('all');
      response.completeError(Exception('API failure'));
      await refresh;

      expect(controller.selectedDepartmentId, 'all');
      expect(controller.isRefreshing, isFalse);
      expect(controller.errorMessage, isNotNull);
      expect(controller.departments.map((department) => department.id), [
        'operations',
        'sales',
      ]);
    },
  );

  test('department search leaves the applied LMS filter unchanged', () async {
    await controller.selectDepartment('sales');

    controller.updateDepartmentSearchQuery('  OPER  ');

    expect(controller.departmentOptions.map((department) => department.id), [
      'operations',
    ]);
    expect(controller.selectedDepartmentId, 'sales');
    expect(controller.visibleItems.map((module) => module.id), ['four']);

    controller.updateDepartmentSearchQuery('missing');
    expect(controller.departmentOptions, isEmpty);

    controller.updateDepartmentSearchQuery('');
    expect(controller.departmentOptions.map((department) => department.id), [
      'operations',
      'sales',
    ]);
  });

  test('opening the picker loads only page one from the seats API', () async {
    expect(seatRepository.requests, isEmpty);

    await controller.openSeatSelection();

    expect(seatRepository.requests, [
      (page: 1, pageSize: 10, departmentId: null, title: ''),
    ]);
    expect(controller.seatOptions.map((seat) => seat.id), ['a', 'b', 'c', 'd']);
    expect(controller.isLoadingSeatOptions, isFalse);
  });

  test('seat API requests include the selected department', () async {
    await controller.selectDepartment('operations');
    await controller.openSeatSelection();

    expect(seatRepository.requests.single.departmentId, 'operations');
    expect(controller.seatOptions.map((seat) => seat.id), ['a', 'b']);
  });

  testWidgets('picker search is debounced and searches page one on the API', (
    tester,
  ) async {
    await controller.openSeatSelection();
    controller.updateSeatSearchQuery('rem');
    await tester.pump(const Duration(milliseconds: 200));
    controller.updateSeatSearchQuery('  REMOTE  ');
    await tester.pump(const Duration(milliseconds: 399));
    expect(seatRepository.requests, hasLength(1));

    await tester.pump(const Duration(milliseconds: 1));

    expect(seatRepository.requests, hasLength(2));
    expect(seatRepository.requests.last.title, 'REMOTE');
    expect(seatRepository.requests.last.page, 1);
    expect(controller.seatOptions.map((seat) => seat.id), ['d']);
    expect(controller.searchQuery, isEmpty);
    expect(controller.visibleItems, hasLength(4));
  });

  test(
    'typing invalidates the old response before the next request starts',
    () async {
      final oldResponse = Completer<SeatProfilePage>();
      seatRepository.respond = (_) => oldResponse.future;
      final firstLoad = controller.openSeatSelection();
      controller.updateSeatSearchQuery('remote');

      oldResponse.complete(
        SeatProfilePage(items: [_profile('a', 'Manager')], hasNextPage: false),
      );
      await firstLoad;

      expect(controller.seatOptions, isEmpty);
      expect(controller.isLoadingSeatOptions, isTrue);
      seatRepository.respond = null;
      await controller.loadSeatOptions();
      expect(controller.seatOptions.map((seat) => seat.id), ['d']);
    },
  );

  test('an older response cannot replace newer search results', () async {
    final oldResponse = Completer<SeatProfilePage>();
    seatRepository.respond = (_) => oldResponse.future;
    final firstLoad = controller.openSeatSelection();
    controller.updateSeatSearchQuery('remote');
    seatRepository.respond = null;
    await controller.loadSeatOptions();

    oldResponse.complete(
      SeatProfilePage(items: [_profile('a', 'Manager')], hasNextPage: false),
    );
    await firstLoad;

    expect(controller.seatOptions.map((seat) => seat.id), ['d']);
  });

  testWidgets('closing the sheet cancels a pending search', (tester) async {
    await controller.openSeatSelection();
    controller.updateSeatSearchQuery('remote');
    controller.closeSeatSelection();
    await tester.pump(const Duration(milliseconds: 400));

    expect(seatRepository.requests, hasLength(1));
    expect(controller.isLoadingSeatOptions, isFalse);
  });

  test('failed seat loads can be retried with the current search', () async {
    controller.updateSeatSearchQuery('remote');
    seatRepository.respond = (_) => Future.error(Exception('API failure'));
    await controller.loadSeatOptions();

    expect(
      controller.seatOptionsError,
      AppStrings.trainingLibraryUnableToLoadSeats,
    );
    expect(controller.isLoadingSeatOptions, isFalse);
    seatRepository.respond = null;
    await controller.loadSeatOptions();

    expect(controller.seatOptionsError, isNull);
    expect(controller.seatOptions.map((seat) => seat.id), ['d']);
    expect(seatRepository.requests.last.title, 'remote');
  });

  test(
    'a selected API seat filters the LMS by UUID even with duplicate titles',
    () async {
      await controller.openSeatSelection();
      await controller.selectSeat(controller.seatOptions.first);

      expect(repository.lastSearchType, 'seat');
      expect(controller.searchQuery, 'Manager');
      expect(controller.visibleItems.map((module) => module.id), [
        'one',
        'two',
      ]);
      expect(controller.selectedSeatId, 'a');
    },
  );

  test(
    'All Seats clears the seat filter while preserving the department',
    () async {
      await controller.selectDepartment('operations');
      await controller.selectSeat(_seatA);

      await controller.selectSeat(null);

      expect(controller.selectedSeatId, isNull);
      expect(controller.searchQuery, isEmpty);
      expect(controller.selectedDepartmentId, 'operations');
      expect(controller.visibleItems, hasLength(3));
    },
  );

  test('changing departments clears the previous seat selection', () async {
    await controller.selectSeat(_seatA);

    await controller.selectDepartment('sales');

    expect(controller.selectedSeatId, isNull);
    expect(controller.searchQuery, isEmpty);
    expect(controller.visibleItems.map((module) => module.id), ['four']);
    await controller.openSeatSelection();
    expect(controller.seatOptions.map((seat) => seat.id), ['c']);
  });

  test('typing a new query releases the exact seat filter', () async {
    await controller.selectSeat(_seatA);

    controller.updateSearchQuery('Sales');

    expect(controller.selectedSeatId, isNull);
    expect(controller.searchQuery, 'Sales');
  });
}

const _seatA = TrainingLibrarySeat(id: 'a', title: 'Manager');
const _seatB = TrainingLibrarySeat(id: 'b', title: 'Manager');
const _seatC = TrainingLibrarySeat(id: 'c', title: 'Sales Lead');

typedef _SeatRequest = ({
  int page,
  int pageSize,
  String? departmentId,
  String title,
});

class _SeatRepository extends Fake implements SeatProfileRepository {
  final List<_SeatRequest> requests = [];
  Future<SeatProfilePage> Function(_SeatRequest)? respond;

  @override
  Future<SeatProfilePage> getSeatProfiles({
    required int page,
    int pageSize = 10,
    String? departmentId,
    String title = '',
  }) async {
    final request = (
      page: page,
      pageSize: pageSize,
      departmentId: departmentId,
      title: title,
    );
    requests.add(request);
    final response = respond;
    if (response != null) {
      return response(request);
    }
    final seats = [
      (profile: _profile('a', 'Manager'), departmentId: 'operations'),
      (profile: _profile('b', 'Manager'), departmentId: 'operations'),
      (profile: _profile('c', 'Sales Lead'), departmentId: 'sales'),
      (profile: _profile('d', 'Remote Seat'), departmentId: 'remote'),
    ];
    return SeatProfilePage(
      items: seats
          .where((seat) {
            return (departmentId == null ||
                    seat.departmentId == departmentId) &&
                seat.profile.name.toLowerCase().contains(title.toLowerCase());
          })
          .map((seat) => seat.profile)
          .toList(),
      hasNextPage: true,
    );
  }
}

SeatProfile _profile(String id, String name) => SeatProfile(
  id: id,
  actualId: 'actual-$id',
  name: name,
  categoriesCount: 0,
  descriptionsCount: 0,
  hasPrimaryPaygrade: false,
  hasAncillaryPaygrade: false,
);

class _LibraryRepository implements TrainingLibraryRepository {
  int requests = 0;
  final List<TrainingLibraryModule> _modules = [
    _module('one', _seatA, 'operations'),
    _module('two', _seatA, 'operations'),
    _module('three', _seatB, 'operations'),
    _module('four', _seatC, 'sales'),
  ];

  String? lastSearchType;
  Future<TrainingLibraryPage> Function()? respond;

  @override
  Future<TrainingLibraryPage> getTrainingLibraryModules({
    required String view,
    required int page,
    int pageSize = 10,
    String searchType = 'category',
    String searchText = '',
    String? departmentId,
  }) async {
    requests++;
    lastSearchType = searchType;
    final response = respond;
    if (response != null) {
      return response();
    }
    return TrainingLibraryPage(
      items: _modules.where((module) {
        return (departmentId == null || module.department.id == departmentId) &&
            module.seat.title.toLowerCase().contains(searchText.toLowerCase());
      }).toList(),
      hasNextPage: false,
    );
  }
}

TrainingLibraryModule _module(
  String id,
  TrainingLibrarySeat seat,
  String departmentId,
) {
  return TrainingLibraryModule(
    id: id,
    title: id,
    description: '',
    department: TrainingLibraryDepartment(id: departmentId, name: departmentId),
    totalDuration: 60,
    seat: seat,
    lessons: const [],
    thumbnailLink: null,
    category: const TrainingLibraryCategory(id: 'category', title: 'Category'),
  );
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/features/seat_profile/domain/entities/department.dart';
import 'package:sparrowkaizen/features/seat_profile/domain/entities/seat_profile_detail.dart';
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

  test(
    'loads the same complete hierarchy as Create Training for view users',
    () async {
      expect(seatRepository.requests, 0);
      expect(controller.canCreateTraining, isFalse);
      await controller.openSeatSelection();
      expect(seatRepository.requests, 1);
      expect(controller.seatOptions.map((seat) => seat.id), [
        'a',
        'b',
        'c',
        'd',
      ]);
      expect(controller.categoryOptions, isEmpty);
      expect(controller.descriptionOptions, isEmpty);
      expect(controller.isLoadingSeatOptions, isFalse);
    },
  );

  test('hierarchy seats respect the selected department', () async {
    await controller.selectDepartment('operations');
    await controller.openSeatSelection();
    expect(controller.seatOptions.map((seat) => seat.id), ['a', 'b']);
  });

  test('closing discards a late hierarchy response', () async {
    final response = Completer<List<SeatProfileDetail>>();
    seatRepository.respond = () => response.future;
    final opening = controller.openSeatSelection();
    controller.closeSeatSelection();
    response.complete([_profile('a', 'Manager', 'operations')]);
    await opening;
    expect(controller.seatOptions, isEmpty);
    expect(controller.isLoadingSeatOptions, isFalse);
  });

  test('an older hierarchy response cannot replace a newer load', () async {
    final response = Completer<List<SeatProfileDetail>>();
    seatRepository.respond = () => response.future;
    final opening = controller.openSeatSelection();
    seatRepository.respond = null;
    await controller.loadSeatOptions();
    response.complete([]);
    await opening;
    expect(controller.seatOptions, hasLength(4));
  });

  test('failed hierarchy loads can be retried', () async {
    seatRepository.respond = () => Future.error(Exception('API failure'));
    await controller.openSeatSelection();
    expect(
      controller.seatOptionsError,
      AppStrings.trainingLibraryUnableToLoadSeats,
    );
    expect(controller.isLoadingSeatOptions, isFalse);
    seatRepository.respond = null;
    await controller.loadSeatOptions();
    expect(controller.seatOptionsError, isNull);
    expect(controller.seatOptions, hasLength(4));
  });

  test(
    'parent selections unlock and reset only their dependent drafts',
    () async {
      await controller.openSeatSelection();
      controller.updatePendingSeatSelection(controller.seatOptions.first);
      expect(controller.categoryOptions.map((item) => item.id), [
        'category',
        'other',
      ]);
      expect(controller.descriptionOptions, isEmpty);
      controller.updatePendingCategorySelection(
        controller.categoryOptions.first,
      );
      expect(controller.descriptionOptions.map((item) => item.id), [
        'one',
        'two',
      ]);
      controller.updatePendingDescriptionSelection(
        controller.descriptionOptions.first,
      );
      controller.updatePendingSeatSelection(controller.seatOptions.first);
      expect(controller.pendingDescriptionSelection?.id, 'one');
      controller.updatePendingCategorySelection(
        controller.categoryOptions.last,
      );
      expect(controller.pendingDescriptionSelection, isNull);
      expect(controller.descriptionOptions.single.id, 'other-description');
      controller.updatePendingDescriptionSelection(_description('one'));
      expect(controller.pendingDescriptionSelection, isNull);
      controller.updatePendingSeatSelection(controller.seatOptions[1]);
      expect(controller.pendingCategorySelection, isNull);
      expect(controller.pendingDescriptionSelection, isNull);
      expect(controller.descriptionOptions, isEmpty);
      expect(controller.selectedSeatId, isNull);
      expect(repository.requests, 1);
    },
  );

  test(
    'Done applies exact hierarchy IDs and reopening preserves the draft',
    () async {
      await controller.openSeatSelection();
      controller.updatePendingSeatSelection(controller.seatOptions.first);
      controller.updatePendingCategorySelection(
        controller.categoryOptions.first,
      );
      expect(await controller.applyPendingSeatSelection(), isTrue);
      expect(controller.visibleItems.map((module) => module.id), [
        'one',
        'two',
      ]);
      controller.updatePendingDescriptionSelection(
        controller.descriptionOptions.last,
      );
      expect(controller.visibleItems, hasLength(2));
      expect(await controller.applyPendingSeatSelection(), isTrue);
      expect(controller.visibleItems.single.id, 'two');
      controller.closeSeatSelection();
      await controller.changeViewMode(TrainingLibraryViewMode.grid);
      await controller.refresh();
      expect(controller.visibleItems.single.id, 'two');
      await controller.openSeatSelection();
      expect(controller.pendingSeatSelectionId, 'a');
      expect(controller.pendingCategorySelection?.id, 'category');
      expect(controller.pendingDescriptionSelection?.id, 'two');
      controller.updatePendingSeatSelection(null);
      controller.closeSeatSelection();
      expect(controller.visibleItems.single.id, 'two');
      expect(controller.selectedCategoryId, 'category');
      expect(controller.selectedDescriptionId, 'two');
    },
  );

  test(
    'failed apply restores every active filter and retains the new draft',
    () async {
      await controller.openSeatSelection();
      controller.updatePendingSeatSelection(controller.seatOptions.first);
      controller.updatePendingCategorySelection(
        controller.categoryOptions.first,
      );
      controller.updatePendingDescriptionSelection(
        controller.descriptionOptions.first,
      );
      await controller.applyPendingSeatSelection();
      controller.updatePendingDescriptionSelection(
        controller.descriptionOptions.last,
      );
      repository.respond = () => Future.error(Exception('API failure'));
      expect(await controller.applyPendingSeatSelection(), isFalse);
      expect(controller.selectedSeatId, 'a');
      expect(controller.selectedCategoryId, 'category');
      expect(controller.selectedDescriptionId, 'one');
      expect(controller.visibleItems.single.id, 'one');
      expect(controller.pendingDescriptionSelection?.id, 'two');
      repository.respond = null;
      expect(await controller.applyPendingSeatSelection(), isTrue);
      expect(controller.visibleItems.single.id, 'two');
    },
  );

  test(
    'exact filters continue loading when the match is on a later page',
    () async {
      await controller.openSeatSelection();
      controller.updatePendingSeatSelection(controller.seatOptions.first);
      controller.updatePendingCategorySelection(
        controller.categoryOptions.first,
      );
      controller.updatePendingDescriptionSelection(
        controller.descriptionOptions.last,
      );
      var page = 0;
      repository.respond = () async => TrainingLibraryPage(
        items: [
          ++page == 1
              ? _module('one', _seatA, 'operations')
              : _module('two', _seatA, 'operations'),
        ],
        hasNextPage: page == 1,
      );
      expect(await controller.applyPendingSeatSelection(), isTrue);
      expect(page, 2);
      expect(controller.visibleItems.single.id, 'two');
    },
  );

  test('repeated pages stop loading when no description matches', () async {
    await controller.openSeatSelection();
    controller.updatePendingSeatSelection(controller.seatOptions.first);
    controller.updatePendingCategorySelection(controller.categoryOptions.first);
    controller.updatePendingDescriptionSelection(
      controller.descriptionOptions.last,
    );
    var page = 0;
    repository.respond = () async {
      page++;
      if (page > 2) throw StateError('Repeated page loop');
      return TrainingLibraryPage(
        items: [_module('one', _seatA, 'operations')],
        hasNextPage: true,
      );
    };
    expect(await controller.applyPendingSeatSelection(), isTrue);
    expect(page, 2);
    expect(controller.visibleItems, isEmpty);
    expect(controller.items, hasLength(1));
  });

  test(
    'reset, department changes, and typed search clear dependent filters',
    () async {
      for (final reset in [
        () => controller.selectSeat(null),
        () => controller.selectDepartment('sales'),
        () async => controller.updateSearchQuery('new query'),
        () => controller.clearSearch(),
      ]) {
        await controller.selectDepartment('all');
        await controller.openSeatSelection();
        controller.updatePendingSeatSelection(controller.seatOptions.first);
        controller.updatePendingCategorySelection(
          controller.categoryOptions.first,
        );
        controller.updatePendingDescriptionSelection(
          controller.descriptionOptions.first,
        );
        await controller.applyPendingSeatSelection();
        await reset();
        expect(controller.selectedSeatId, isNull);
        expect(controller.selectedCategoryId, isNull);
        expect(controller.selectedDescriptionId, isNull);
      }
    },
  );

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
        'other-description',
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
      expect(controller.visibleItems, hasLength(4));
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

class _SeatRepository extends Fake implements SeatProfileRepository {
  int requests = 0;
  Future<List<SeatProfileDetail>> Function()? respond;

  @override
  Future<List<SeatProfileDetail>> seatProfileCategoryTrainings() async {
    requests++;
    return respond?.call() ??
        [
          _profile('a', 'Manager', 'operations'),
          _profile('b', 'Manager', 'operations'),
          _profile('c', 'Sales Lead', 'sales'),
          _profile('d', 'Remote Seat', 'remote'),
        ];
  }
}

SeatProfileDetail _profile(String id, String title, String departmentId) =>
    SeatProfileDetail(
      id: id,
      actualId: 'actual-$id',
      title: title,
      department: Department(id: departmentId, name: departmentId),
      paygradeUnit: '',
      categories: [
        SeatProfileCategory(
          id: 'category',
          title: 'Category',
          weightPercent: 0,
          descriptions: [_description('one'), _description('two')],
        ),
        SeatProfileCategory(
          id: 'other',
          title: 'Category',
          weightPercent: 0,
          descriptions: [_description('other-description')],
        ),
      ],
    );

SeatProfileDescription _description(String id) => SeatProfileDescription(
  id: id,
  actualId: id,
  name: 'Same description title',
  auditSpecifics: '',
  auditFactorType: '',
  milestoneDays: '',
);

class _LibraryRepository implements TrainingLibraryRepository {
  int requests = 0;
  final List<TrainingLibraryModule> _modules = [
    _module('one', _seatA, 'operations'),
    _module('two', _seatA, 'operations'),
    _module('other-description', _seatA, 'operations', categoryId: 'other'),
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
  String departmentId, {
  String categoryId = 'category',
}) {
  return TrainingLibraryModule(
    id: id,
    title: id,
    description: '',
    department: TrainingLibraryDepartment(id: departmentId, name: departmentId),
    totalDuration: 60,
    seat: seat,
    lessons: const [],
    thumbnailLink: null,
    category: TrainingLibraryCategory(id: categoryId, title: 'Category'),
  );
}

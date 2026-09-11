import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../seat_profile/domain/usecases/get_seat_profiles_usecase.dart';
import '../../data/repositories/training_library_repository_impl.dart';
import '../../domain/entities/training_library_module.dart';
import '../../domain/usecases/get_training_library_modules_usecase.dart';

enum TrainingLibraryViewMode { grid, list }

enum TrainingLibrarySearchFilter { category, department, seat }

enum _LibrarySelectionField { department, seat }

extension TrainingLibrarySearchFilterValue on TrainingLibrarySearchFilter {
  String get apiValue => name;
}

class TrainingLibraryController extends ChangeNotifier {
  TrainingLibraryController(
    this._getTrainingLibraryModulesUseCase, {
    required GetSeatProfilesUseCase getSeatProfilesUseCase,
    bool Function()? canCreateTraining,
  }) : _getSeatProfilesUseCase = getSeatProfilesUseCase,
       _canCreateTraining = canCreateTraining {
    scrollController.addListener(_handleScroll);
  }

  final GetTrainingLibraryModulesUseCase _getTrainingLibraryModulesUseCase;
  final GetSeatProfilesUseCase _getSeatProfilesUseCase;
  final bool Function()? _canCreateTraining;
  final ScrollController scrollController = ScrollController();
  bool _isDisposed = false;
  static const int _pageSize = 10;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 400);

  bool _isInitialLoading = false;
  bool _isRefreshing = false;
  bool _isViewSyncing = false;
  bool _isLoadingMore = false;
  bool _hasNextPage = true;
  int _currentPage = 0;
  String? _errorMessage;
  String _selectedDepartmentId = 'all';
  TrainingLibraryViewMode _viewMode = TrainingLibraryViewMode.list;
  TrainingLibrarySearchFilter _searchFilter = TrainingLibrarySearchFilter.seat;
  String _searchQuery = '';
  String? _selectedSeatId;
  TrainingLibrarySeat? _pendingSeatSelection;
  String _seatSearchQuery = '';
  List<TrainingLibrarySeat> _seatOptions = const [];
  bool _isLoadingSeatOptions = false;
  String? _seatOptionsError;
  Timer? _seatSearchDebounceTimer;
  int _seatRequestId = 0;
  List<TrainingLibraryDepartment> _departments =
      const <TrainingLibraryDepartment>[];
  String _departmentSearchQuery = '';
  List<TrainingLibraryModule> _items = const <TrainingLibraryModule>[];
  Timer? _searchDebounceTimer;
  bool _hasPendingSearchRefresh = false;
  _LibrarySelectionField? _applyingSelectionField;
  String? _applyingSelectionId;
  List<TrainingLibraryModule>? _itemsBeforeSelection;
  String? _selectionErrorMessage;

  bool get canCreateTraining => _canCreateTraining?.call() ?? false;
  bool get hasSearchQuery => _hasActiveSearch;
  List<TrainingLibraryDepartment> get departmentTabs => [
    const TrainingLibraryDepartment(
      id: 'all',
      name: AppStrings.trainingLibraryAllFilter,
    ),
    ..._departments.take(3),
  ];

  static String displayModuleTitle(TrainingLibraryModule module) {
    final title = module.title.trim();
    return title.isEmpty ? AppStrings.trainingLibraryUntitledModule : title;
  }

  static String displayModuleValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? AppStrings.trainingLibraryNotAvailable : trimmed;
  }

  static String displayModuleLessonCount(TrainingLibraryModule module) =>
      AppStrings.trainingLibraryVideosCount(module.lessonsCount);

  static String displayModuleDuration(TrainingLibraryModule module) {
    final duration = CustomFunctions.formatDuration(module.totalDuration);
    return module.totalDuration < 3600
        ? AppStrings.trainingLibraryMinutesDuration(duration)
        : duration;
  }

  Future<void> openLibraryDetail(
    TrainingLibraryModule module, {
    required Future<bool?> Function(TrainingLibraryModule module, String view)
    openDetail,
  }) async {
    final shouldRefresh = await openDetail(module, _viewMode.name);
    if (!_isDisposed && shouldRefresh == true) {
      await refresh();
    }
  }

  void openCreateFlow({required VoidCallback onOpen}) {
    if (canCreateTraining) {
      onOpen();
    }
  }

  void _handleScroll() {
    if (scrollController.hasClients &&
        scrollController.position.extentAfter <= 360) {
      unawaited(loadNextPage());
    }
  }

  bool get isInitialLoading => _isInitialLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isViewSyncing => _isViewSyncing;
  bool get isLoadingMore => _isLoadingMore;
  bool get isInlineLoading =>
      !isApplyingSelection && (_isRefreshing || _isViewSyncing);
  bool get isApplyingSelection => _applyingSelectionField != null;
  bool get canApplySelection =>
      !isApplyingSelection &&
      !_isInitialLoading &&
      !_isRefreshing &&
      !_isViewSyncing &&
      !_isLoadingMore;
  String? get selectionErrorMessage => _selectionErrorMessage;

  bool isApplyingSeatSelection(String? seatId) =>
      _applyingSelectionField == _LibrarySelectionField.seat &&
      _applyingSelectionId == seatId;

  bool isApplyingDepartmentSelection(String departmentId) =>
      _applyingSelectionField == _LibrarySelectionField.department &&
      _applyingSelectionId == departmentId;

  void clearSelectionError() {
    _selectionErrorMessage = null;
  }

  Future<bool> applySeatSelection(TrainingLibrarySeat? seat) => _applySelection(
    field: _LibrarySelectionField.seat,
    id: seat?.id,
    apply: () => selectSeat(seat),
  );

  Future<bool> applyDepartmentSelection(String departmentId) => _applySelection(
    field: _LibrarySelectionField.department,
    id: departmentId,
    apply: () => selectDepartment(departmentId),
  );

  Future<bool> _applySelection({
    required _LibrarySelectionField field,
    required String? id,
    required Future<bool> Function() apply,
  }) async {
    if (!canApplySelection) {
      return false;
    }
    final previous = (
      departmentId: _selectedDepartmentId,
      seatId: _selectedSeatId,
      searchQuery: _searchQuery,
      searchFilter: _searchFilter,
      items: _items,
      departments: _departments,
      page: _currentPage,
      hasNextPage: _hasNextPage,
      errorMessage: _errorMessage,
    );
    _itemsBeforeSelection = visibleItems;
    _applyingSelectionField = field;
    _applyingSelectionId = id;
    _selectionErrorMessage = null;
    _searchDebounceTimer?.cancel();
    _hasPendingSearchRefresh = false;
    notifyListeners();
    try {
      final succeeded = await apply();
      if (!succeeded) {
        _selectedDepartmentId = previous.departmentId;
        _selectedSeatId = previous.seatId;
        _searchQuery = previous.searchQuery;
        _searchFilter = previous.searchFilter;
        _items = previous.items;
        _departments = previous.departments;
        _currentPage = previous.page;
        _hasNextPage = previous.hasNextPage;
        _errorMessage = previous.errorMessage;
        _selectionErrorMessage = AppStrings.trainingLibraryUnableToApplyFilter;
      }
      return succeeded;
    } finally {
      _applyingSelectionField = null;
      _applyingSelectionId = null;
      _itemsBeforeSelection = null;
      notifyListeners();
      _flushPendingSearchRefresh();
    }
  }

  bool get isShowingFullscreenLoading => _isInitialLoading && _items.isEmpty;
  String? get errorMessage => _errorMessage;
  String get selectedDepartmentId => _selectedDepartmentId;
  TrainingLibraryViewMode get viewMode => _viewMode;
  TrainingLibrarySearchFilter get searchFilter => _searchFilter;
  String get searchQuery => _searchQuery;
  String? get selectedSeatId => _selectedSeatId;
  String? get pendingSeatSelectionId => _pendingSeatSelection?.id;

  List<TrainingLibrarySeat> get seatOptions =>
      List<TrainingLibrarySeat>.unmodifiable(_seatOptions);
  bool get isLoadingSeatOptions => _isLoadingSeatOptions;
  String? get seatOptionsError => _seatOptionsError;

  List<TrainingLibraryDepartment> get departments =>
      List<TrainingLibraryDepartment>.unmodifiable(_departments);
  List<TrainingLibraryDepartment> get departmentOptions {
    final query = _departmentSearchQuery.trim().toLowerCase();
    return List<TrainingLibraryDepartment>.unmodifiable(
      _departments.where(
        (department) => department.name.toLowerCase().contains(query),
      ),
    );
  }

  void updateDepartmentSearchQuery(String query) {
    if (_departmentSearchQuery == query) {
      return;
    }
    _departmentSearchQuery = query;
    notifyListeners();
  }

  List<TrainingLibraryModule> get items =>
      List<TrainingLibraryModule>.unmodifiable(_items);
  bool get _hasActiveSearch => _searchQuery.trim().isNotEmpty;
  bool get _hasActiveDepartmentFilter => _selectedDepartmentId != 'all';

  List<TrainingLibraryModule> get visibleItems {
    if (_itemsBeforeSelection != null) {
      return _itemsBeforeSelection!;
    }
    final filteredByDepartment = _selectedDepartmentId == 'all'
        ? _items
        : _items
              .where((item) => item.department.id == _selectedDepartmentId)
              .toList(growable: false);

    return List<TrainingLibraryModule>.unmodifiable(
      _selectedSeatId == null
          ? filteredByDepartment
          : filteredByDepartment.where(
              (item) => item.seat.id == _selectedSeatId,
            ),
    );
  }

  void updateSeatSearchQuery(String query) {
    if (_seatSearchQuery == query) {
      return;
    }
    _seatSearchQuery = query;
    _seatSearchDebounceTimer?.cancel();
    // Invalidate the old response as soon as typing starts, before the debounce.
    _seatRequestId++;
    _seatOptions = const [];
    _seatOptionsError = null;
    _isLoadingSeatOptions = true;
    notifyListeners();
    _seatSearchDebounceTimer = Timer(_searchDebounceDuration, () {
      unawaited(loadSeatOptions());
    });
  }

  Future<void> openSeatSelection() {
    _seatSearchQuery = '';
    _pendingSeatSelection = _selectedSeatId == null
        ? null
        : TrainingLibrarySeat(id: _selectedSeatId!, title: _searchQuery);
    return loadSeatOptions();
  }

  void updatePendingSeatSelection(TrainingLibrarySeat? seat) {
    if (isApplyingSelection) {
      return;
    }

    _pendingSeatSelection = seat;
    _selectionErrorMessage = null;
    notifyListeners();
  }

  Future<bool> applyPendingSeatSelection() =>
      applySeatSelection(_pendingSeatSelection);

  void closeSeatSelection() {
    _seatSearchDebounceTimer?.cancel();
    _seatRequestId++;
    _isLoadingSeatOptions = false;
    _pendingSeatSelection = null;
  }

  Future<void> loadSeatOptions() async {
    _seatSearchDebounceTimer?.cancel();
    final requestId = ++_seatRequestId;
    _isLoadingSeatOptions = true;
    _seatOptionsError = null;
    _seatOptions = const [];
    notifyListeners();

    try {
      final response = await _getSeatProfilesUseCase(
        page: 1,
        pageSize: _pageSize,
        departmentId: _hasActiveDepartmentFilter ? _selectedDepartmentId : null,
        title: _seatSearchQuery.trim(),
      );
      if (requestId != _seatRequestId) {
        return;
      }

      final seats = <String, TrainingLibrarySeat>{};
      for (final profile in response.items) {
        final id = profile.id.trim();
        final title = profile.name.trim();
        if (id.isNotEmpty && title.isNotEmpty) {
          seats[id] = TrainingLibrarySeat(id: id, title: title);
        }
      }
      _seatOptions = List<TrainingLibrarySeat>.unmodifiable(seats.values);
    } catch (_) {
      if (requestId == _seatRequestId) {
        _seatOptionsError = AppStrings.trainingLibraryUnableToLoadSeats;
      }
    } finally {
      if (requestId == _seatRequestId) {
        _isLoadingSeatOptions = false;
        notifyListeners();
      }
    }
  }

  Future<bool> selectSeat(TrainingLibrarySeat? seat) async {
    _searchDebounceTimer?.cancel();
    _selectedSeatId = seat?.id;
    _searchQuery = seat?.title.trim() ?? '';
    _searchFilter = TrainingLibrarySearchFilter.seat;
    _errorMessage = null;
    notifyListeners();
    return _reloadModulesForActiveFilters();
  }

  Future<void> initialize() async {
    if (_isInitialLoading) {
      return;
    }

    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reloadModules();
    } catch (error) {
      _errorMessage = error.toString();
    }

    _isInitialLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_isInitialLoading || _isRefreshing) {
      return;
    }

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reloadModules();
    } catch (error) {
      _errorMessage = error.toString();
    }

    _isRefreshing = false;
    notifyListeners();
    _flushPendingSearchRefresh();
  }

  Future<void> changeViewMode(TrainingLibraryViewMode mode) async {
    if (_viewMode == mode || _isViewSyncing) {
      return;
    }

    _viewMode = mode;
    _isViewSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reloadModules();
    } catch (error) {
      _errorMessage = error.toString();
    }

    _isViewSyncing = false;
    notifyListeners();
    _flushPendingSearchRefresh();
  }

  Future<bool> selectDepartment(String departmentId) async {
    if (_selectedDepartmentId == departmentId) {
      return true;
    }

    _searchDebounceTimer?.cancel();
    _selectedDepartmentId = departmentId;
    if (_selectedSeatId != null) {
      _selectedSeatId = null;
      _searchQuery = '';
    }
    _errorMessage = null;
    notifyListeners();
    return _reloadModulesForActiveFilters();
  }

  Future<void> selectSearchFilter(TrainingLibrarySearchFilter filter) async {
    if (_searchFilter == filter) {
      return;
    }

    _searchDebounceTimer?.cancel();
    _searchFilter = filter;
    if (_searchQuery.trim().isEmpty) {
      notifyListeners();
      return;
    }

    notifyListeners();
    await _reloadModulesForActiveFilters();
  }

  void updateSearchQuery(String value) {
    if (_searchQuery == value) {
      return;
    }

    _searchQuery = value;
    _selectedSeatId = null;
    _errorMessage = null;
    notifyListeners();
    _scheduleSearchRefresh();
  }

  Future<void> clearSearch() async {
    final hadSearch = _hasActiveSearch;
    final hadDepartmentFilter = _hasActiveDepartmentFilter;
    if (!hadSearch && !hadDepartmentFilter) {
      return;
    }

    _searchDebounceTimer?.cancel();
    _searchQuery = '';
    _selectedSeatId = null;
    _selectedDepartmentId = 'all';
    _errorMessage = null;
    notifyListeners();
    await _reloadModulesForActiveFilters();
  }

  Future<void> loadNextPage() async {
    if (_isInitialLoading ||
        _isRefreshing ||
        _isViewSyncing ||
        _isLoadingMore ||
        !_hasNextPage) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      await _loadPage(_currentPage + 1);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
      _flushPendingSearchRefresh();
    }
  }

  Future<void> _reloadModules() async {
    _currentPage = 0;
    _hasNextPage = true;
    if (!isApplyingSelection) {
      _items = const <TrainingLibraryModule>[];
    }
    // Keep department choices visible until the replacement page arrives.
    await _loadPage(1, replace: true);
    await _loadUntilDepartmentHasVisibleItems();
  }

  Future<void> _loadPage(int page, {bool replace = false}) async {
    final response = await _getTrainingLibraryModulesUseCase(
      view: _viewMode.name,
      page: page,
      pageSize: _pageSize,
      searchType: _searchFilter.apiValue,
      searchText: _searchQuery.trim(),
      departmentId: _hasActiveDepartmentFilter ? _selectedDepartmentId : null,
    );

    final nextItems = replace
        ? response.items
        : <TrainingLibraryModule>[..._items, ...response.items];
    _currentPage = page;
    _hasNextPage = response.hasNextPage && response.items.isNotEmpty;
    _items = List<TrainingLibraryModule>.unmodifiable(nextItems);
    _departments = List<TrainingLibraryDepartment>.unmodifiable(
      _resolveVisibleDepartments(_items),
    );
    _syncSelectedDepartment();
  }

  Future<void> _loadUntilDepartmentHasVisibleItems() async {
    while (_selectedDepartmentId != 'all' &&
        visibleItems.isEmpty &&
        _hasNextPage &&
        !_isLoadingMore &&
        !_isRefreshing &&
        !_isViewSyncing &&
        !_isInitialLoading) {
      await loadNextPage();
    }
  }

  List<TrainingLibraryDepartment> _resolveDepartments(
    List<TrainingLibraryModule> modules,
  ) {
    final seenDepartmentIds = <String>{};
    final departments = <TrainingLibraryDepartment>[];

    for (final module in modules) {
      final departmentId = module.department.id.trim();
      final departmentName = module.department.name.trim();
      if (departmentId.isEmpty || departmentName.isEmpty) {
        continue;
      }

      if (seenDepartmentIds.add(departmentId)) {
        departments.add(module.department);
      }
    }

    return departments;
  }

  List<TrainingLibraryDepartment> _resolveVisibleDepartments(
    List<TrainingLibraryModule> modules,
  ) {
    final resolvedDepartments = _resolveDepartments(modules);
    if (!_hasActiveSearch && !_hasActiveDepartmentFilter) {
      return resolvedDepartments;
    }

    return _mergeDepartments(_departments, resolvedDepartments);
  }

  Future<bool> _reloadModulesForActiveFilters() async {
    if (_isInitialLoading ||
        _isRefreshing ||
        _isViewSyncing ||
        _isLoadingMore) {
      _hasPendingSearchRefresh = true;
      return false;
    }

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reloadModules();
    } catch (error) {
      _errorMessage = error.toString();
    }

    _isRefreshing = false;
    notifyListeners();
    _flushPendingSearchRefresh();
    return _errorMessage == null;
  }

  List<TrainingLibraryDepartment> _mergeDepartments(
    List<TrainingLibraryDepartment> existingDepartments,
    List<TrainingLibraryDepartment> nextDepartments,
  ) {
    final mergedDepartments = <TrainingLibraryDepartment>[];
    final seenDepartmentIds = <String>{};

    for (final department in <TrainingLibraryDepartment>[
      ...existingDepartments,
      ...nextDepartments,
    ]) {
      final departmentId = department.id.trim();
      final departmentName = department.name.trim();
      if (departmentId.isEmpty || departmentName.isEmpty) {
        continue;
      }

      if (seenDepartmentIds.add(departmentId)) {
        mergedDepartments.add(department);
      }
    }

    return mergedDepartments;
  }

  void _syncSelectedDepartment() {
    if (_selectedDepartmentId == 'all') {
      return;
    }

    if (_hasNextPage) {
      return;
    }

    for (final department in _departments) {
      if (department.id == _selectedDepartmentId) {
        return;
      }
    }

    _selectedDepartmentId = 'all';
  }

  @override
  void dispose() {
    _isDisposed = true;
    scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    closeSeatSelection();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _scheduleSearchRefresh({bool immediate = false}) {
    _searchDebounceTimer?.cancel();

    if (immediate) {
      unawaited(_runDebouncedSearchRefresh());
      return;
    }

    _searchDebounceTimer = Timer(_searchDebounceDuration, () {
      unawaited(_runDebouncedSearchRefresh());
    });
  }

  Future<void> _runDebouncedSearchRefresh() async {
    if (_isInitialLoading ||
        _isRefreshing ||
        _isViewSyncing ||
        _isLoadingMore) {
      _hasPendingSearchRefresh = true;
      return;
    }

    _hasPendingSearchRefresh = false;
    await _reloadModulesForActiveFilters();
  }

  void _flushPendingSearchRefresh() {
    if (!_hasPendingSearchRefresh ||
        isApplyingSelection ||
        _isInitialLoading ||
        _isRefreshing ||
        _isViewSyncing ||
        _isLoadingMore) {
      return;
    }

    _hasPendingSearchRefresh = false;
    _scheduleSearchRefresh(immediate: true);
  }
}

GetTrainingLibraryModulesUseCase createGetTrainingLibraryModulesUseCase(
  TrainingLibraryRepositoryImpl repository,
) {
  return GetTrainingLibraryModulesUseCase(repository);
}

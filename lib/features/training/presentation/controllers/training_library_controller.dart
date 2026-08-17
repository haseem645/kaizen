import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/training_library_repository_impl.dart';
import '../../domain/entities/training_library_module.dart';
import '../../domain/usecases/get_training_library_modules_usecase.dart';

enum TrainingLibraryViewMode { grid, list }

enum TrainingLibrarySearchFilter { category, department, seat }

extension TrainingLibrarySearchFilterValue on TrainingLibrarySearchFilter {
  String get apiValue => name;
}

class TrainingLibraryController extends ChangeNotifier {
  TrainingLibraryController(this._getTrainingLibraryModulesUseCase);

  final GetTrainingLibraryModulesUseCase _getTrainingLibraryModulesUseCase;
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
  TrainingLibrarySearchFilter _searchFilter =
      TrainingLibrarySearchFilter.category;
  String _searchQuery = '';
  List<TrainingLibraryDepartment> _departments =
      const <TrainingLibraryDepartment>[];
  List<TrainingLibraryModule> _items = const <TrainingLibraryModule>[];
  Timer? _searchDebounceTimer;
  bool _hasPendingSearchRefresh = false;

  bool get isInitialLoading => _isInitialLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isViewSyncing => _isViewSyncing;
  bool get isLoadingMore => _isLoadingMore;
  bool get isInlineLoading => _isRefreshing || _isViewSyncing;
  String? get errorMessage => _errorMessage;
  String get selectedDepartmentId => _selectedDepartmentId;
  TrainingLibraryViewMode get viewMode => _viewMode;
  TrainingLibrarySearchFilter get searchFilter => _searchFilter;
  String get searchQuery => _searchQuery;
  List<TrainingLibraryDepartment> get departments =>
      List<TrainingLibraryDepartment>.unmodifiable(_departments);
  List<TrainingLibraryModule> get items =>
      List<TrainingLibraryModule>.unmodifiable(_items);
  bool get _hasActiveSearch => _searchQuery.trim().isNotEmpty;

  List<TrainingLibraryModule> get visibleItems {
    final filteredByDepartment = _selectedDepartmentId == 'all'
        ? _items
        : _items
              .where((item) => item.department.id == _selectedDepartmentId)
              .toList(growable: false);

    return List<TrainingLibraryModule>.unmodifiable(filteredByDepartment);
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

  Future<void> selectDepartment(String departmentId) async {
    if (_selectedDepartmentId == departmentId) {
      return;
    }

    _selectedDepartmentId = departmentId;
    notifyListeners();
    await _loadUntilDepartmentHasVisibleItems();
  }

  Future<void> selectSearchFilter(TrainingLibrarySearchFilter filter) async {
    if (_searchFilter == filter) {
      return;
    }

    _searchFilter = filter;
    if (_searchQuery.trim().isEmpty) {
      notifyListeners();
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

  void updateSearchQuery(String value) {
    if (_searchQuery == value) {
      return;
    }

    _searchQuery = value;
    _scheduleSearchRefresh();
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
    _items = const <TrainingLibraryModule>[];
    if (!_hasActiveSearch) {
      _departments = const <TrainingLibraryDepartment>[];
    }
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
    if (!_hasActiveSearch) {
      return resolvedDepartments;
    }

    return _mergeDepartments(_departments, resolvedDepartments);
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

  void _flushPendingSearchRefresh() {
    if (!_hasPendingSearchRefresh ||
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

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../data/datasources/seat_profile_remote_data_source.dart';
import '../../data/repositories/seat_profile_repository_impl.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/seat_profile.dart';
import '../../domain/usecases/get_seat_profiles_usecase.dart';

enum SeatProfileFilter { all, primaryPaygrade, ancillaryPaygrade }

class SeatProfileController extends ChangeNotifier {
  SeatProfileController(this._getSeatProfilesUseCase);

  final GetSeatProfilesUseCase _getSeatProfilesUseCase;
  final TextEditingController searchController = TextEditingController();

  static const int _pageSize = 10;

  bool _isInitialLoading = false;
  bool _isListLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasNextPage = true;
  int _currentPage = 0;
  String? _errorMessage;
  String _searchQuery = '';
  SeatProfileFilter _selectedFilter = SeatProfileFilter.all;
  String _selectedDepartmentId = 'all';
  List<Department> _departments = const <Department>[];
  List<SeatProfile> _items = const <SeatProfile>[];

  bool get isInitialLoading => _isInitialLoading;
  bool get isListLoading => _isListLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  SeatProfileFilter get selectedFilter => _selectedFilter;
  String get selectedDepartmentId => _selectedDepartmentId;
  List<Department> get departments => List<Department>.unmodifiable(_departments);

  List<SeatProfile> get visibleItems {
    final query = _searchQuery.trim().toLowerCase();

    return _items
        .where((item) {
          final matchesFilter = switch (_selectedFilter) {
            SeatProfileFilter.all => true,
            SeatProfileFilter.primaryPaygrade => item.hasPrimaryPaygrade,
            SeatProfileFilter.ancillaryPaygrade => item.hasAncillaryPaygrade,
          };

          final matchesQuery =
              query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              item.categoriesCount.toString().contains(query) ||
              item.descriptionsCount.toString().contains(query);

          return matchesFilter && matchesQuery;
        })
        .toList(growable: false);
  }

  String get selectedFilterLabel {
    return switch (_selectedFilter) {
      SeatProfileFilter.all => AppStrings.seatProfileFilterAll,
      SeatProfileFilter.primaryPaygrade => AppStrings.seatProfileFilterPrimaryPaygrade,
      SeatProfileFilter.ancillaryPaygrade => AppStrings.seatProfileFilterAncillaryPaygrade,
    };
  }

  Future<void> initialize() async {
    if (_isInitialLoading) {
      return;
    }

    _isInitialLoading = true;
    _errorMessage = null;
    _selectedDepartmentId = 'all';
    _departments = const <Department>[];
    notifyListeners();

    try {
      await _loadDepartments();
      await _reloadSeatProfiles();
    } catch (error) {
      _errorMessage = error.toString();
    }

    _isInitialLoading = false;
    notifyListeners();
  }

  Future<void> refresh() {
    return _refreshSeatProfiles(showLoader: false);
  }

  Future<void> loadNextPage() async {
    if (_isInitialLoading || _isListLoading || _isRefreshing || _isLoadingMore || !_hasNextPage) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      await _loadPage(_currentPage + 1);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _loadDepartments() async {
    _departments = List<Department>.unmodifiable(await _getSeatProfilesUseCase.getDepartments());
  }

  Future<void> _refreshSeatProfiles({required bool showLoader}) async {
    if (_isInitialLoading || _isListLoading || _isRefreshing) {
      return;
    }

    if (showLoader) {
      _isListLoading = true;
    } else {
      _isRefreshing = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      await _reloadSeatProfiles();
    } catch (error) {
      _errorMessage = error.toString();
    }

    if (showLoader) {
      _isListLoading = false;
    } else {
      _isRefreshing = false;
    }
    notifyListeners();
  }

  Future<void> _reloadSeatProfiles() async {
    _currentPage = 0;
    _hasNextPage = true;
    _items = const <SeatProfile>[];
    await _loadPage(1, replace: true);
  }

  Future<void> _loadPage(int page, {bool replace = false}) async {
    final response = await _getSeatProfilesUseCase(
      page: page,
      pageSize: _pageSize,
      departmentId: _selectedDepartmentId == 'all' ? null : _selectedDepartmentId,
    );
    _currentPage = page;
    _hasNextPage = response.hasNextPage && response.items.isNotEmpty;
    _items = replace
        ? List<SeatProfile>.unmodifiable(response.items)
        : List<SeatProfile>.unmodifiable(<SeatProfile>[..._items, ...response.items]);
  }

  void updateSearchQuery(String value) {
    if (_searchQuery == value) {
      return;
    }

    _searchQuery = value;
    notifyListeners();
  }

  void selectFilter(SeatProfileFilter filter) {
    if (_selectedFilter == filter) {
      return;
    }

    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> selectDepartment(String departmentId) async {
    if (_selectedDepartmentId == departmentId) {
      return;
    }

    _selectedDepartmentId = departmentId;
    await _refreshSeatProfiles(showLoader: true);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

SeatProfileRepositoryImpl createSeatProfileRepository(
  SeatProfileRemoteDataSource remoteDataSource,
) {
  return SeatProfileRepositoryImpl(remoteDataSource);
}

GetSeatProfilesUseCase createGetSeatProfilesUseCase(SeatProfileRepositoryImpl repository) {
  return GetSeatProfilesUseCase(repository);
}

import 'package:flutter/material.dart';

import '../../../../core/preference/app_preference.dart';
import '../../../seat_profile/domain/entities/department.dart';
import '../../data/datasources/paygrade_remote_data_source.dart';
import '../../data/repositories/paygrade_repository_impl.dart';
import '../../domain/entities/paygrade.dart';
import '../../domain/usecases/get_paygrades_usecase.dart';

class PaygradesController extends ChangeNotifier {
  PaygradesController(this._getPaygradesUseCase);

  final GetPaygradesUseCase _getPaygradesUseCase;
  final TextEditingController searchController = TextEditingController();

  static const int _pageSize = 10;

  bool _isInitialLoading = false;
  bool _isListLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasNextPage = true;
  int _currentPage = 0;
  bool _isOwner = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedDepartmentId = 'all';
  List<Department> _departments = const <Department>[];
  List<Paygrade> _items = const <Paygrade>[];

  bool get isInitialLoading => _isInitialLoading;
  bool get isListLoading => _isListLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get isOwner => _isOwner;
  String? get errorMessage => _errorMessage;
  String get selectedDepartmentId => _selectedDepartmentId;
  List<Department> get departments =>
      List<Department>.unmodifiable(_departments);
  List<Paygrade> get items => List<Paygrade>.unmodifiable(_items);

  Future<void> initialize() async {
    if (_isInitialLoading) {
      return;
    }

    _isInitialLoading = true;
    _errorMessage = null;
    _isOwner = true;
    _selectedDepartmentId = 'all';
    _searchQuery = '';
    _departments = const <Department>[];
    _items = const <Paygrade>[];
    searchController.clear();
    notifyListeners();

    try {
      final user = await AppPreference.getUser();
      _isOwner = user?.isOwner == true;
      await _loadDepartments();
      if (!_isOwner && _departments.isNotEmpty) {
        _selectedDepartmentId = _departments.first.id;
      }
      await _reloadPaygrades();
    } catch (error) {
      _errorMessage = error.toString();
    }

    _isInitialLoading = false;
    notifyListeners();
  }

  Future<void> refresh() {
    return _refreshPaygrades(showLoader: false);
  }

  Future<void> loadNextPage() async {
    if (_isInitialLoading ||
        _isListLoading ||
        _isRefreshing ||
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
    }
  }

  Future<void> _loadDepartments() async {
    _departments = List<Department>.unmodifiable(
      await _getPaygradesUseCase.getDepartments(isOwner: _isOwner),
    );
  }

  Future<void> _refreshPaygrades({required bool showLoader}) async {
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
      await _reloadPaygrades();
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

  Future<void> _reloadPaygrades() async {
    _currentPage = 0;
    _hasNextPage = true;
    _items = const <Paygrade>[];
    await _loadPage(1, replace: true);
  }

  Future<void> _loadPage(int page, {bool replace = false}) async {
    final response = await _getPaygradesUseCase(
      page: page,
      pageSize: _pageSize,
      departmentId: _selectedDepartmentId == 'all'
          ? null
          : _selectedDepartmentId,
      title: _searchQuery.trim(),
    );
    _currentPage = page;
    _hasNextPage = response.hasNextPage && response.items.isNotEmpty;
    _items = replace
        ? List<Paygrade>.unmodifiable(response.items)
        : List<Paygrade>.unmodifiable(<Paygrade>[..._items, ...response.items]);
  }

  Future<void> updateSearchQuery(String value) async {
    if (_searchQuery == value) {
      return;
    }

    _searchQuery = value;
    await _refreshPaygrades(showLoader: true);
  }

  Future<void> selectDepartment(String departmentId) async {
    if (_selectedDepartmentId == departmentId) {
      return;
    }

    _selectedDepartmentId = departmentId;
    await _refreshPaygrades(showLoader: true);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

PaygradeRepositoryImpl createPaygradeRepository(
  PaygradeRemoteDataSource remoteDataSource,
) {
  return PaygradeRepositoryImpl(remoteDataSource);
}

GetPaygradesUseCase createGetPaygradesUseCase(
  PaygradeRepositoryImpl repository,
) {
  return GetPaygradesUseCase(repository);
}

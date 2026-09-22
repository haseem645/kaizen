import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/managers/app_manager.dart';
import '../../data/datasources/paygrade_remote_data_source.dart';
import '../../data/repositories/paygrade_repository_impl.dart';
import '../../domain/entities/paygrade_detail.dart';
import '../../domain/usecases/get_paygrades_usecase.dart';

enum PaygradeDetailTab { primary, ancillary }

class PaygradeDetailController extends ChangeNotifier {
  PaygradeDetailController(this._getPaygradesUseCase);

  final GetPaygradesUseCase _getPaygradesUseCase;

  bool _isLoading = false;
  bool _isGeneratingPaygrades = false;
  bool _isUpdatingPaygrade = false;
  String? _errorMessage;
  String? _paygradeGenerationErrorMessage;
  String? _deletingPaygradeId;
  String _paygradeId = '';
  PaygradeDetailTab _selectedTab = PaygradeDetailTab.primary;
  final Map<PaygradeDetailTab, PaygradeDetail> _detailsByTab =
      <PaygradeDetailTab, PaygradeDetail>{};

  bool get isLoading => _isLoading;
  bool get isGeneratingPaygrades => _isGeneratingPaygrades;
  bool get isUpdatingPaygrade => _isUpdatingPaygrade;
  String? get errorMessage => _errorMessage;
  String? get paygradeGenerationErrorMessage => _paygradeGenerationErrorMessage;
  bool get isPrimaryTab => _selectedTab == PaygradeDetailTab.primary;
  PaygradeDetailTab get selectedTab => _selectedTab;
  PaygradeDetail? get detail => _detailsByTab[_selectedTab];

  bool isDeletingPaygrade(String paygradeId) {
    return _deletingPaygradeId == paygradeId;
  }

  Future<void> initialize(String paygradeId) async {
    _paygradeId = paygradeId;
    await _loadSelectedTab(forceReload: true);
  }

  Future<void> selectTab(PaygradeDetailTab tab) async {
    if (_selectedTab == tab && _detailsByTab.containsKey(tab)) {
      return;
    }

    _selectedTab = tab;
    notifyListeners();
    await _loadSelectedTab(forceReload: !_detailsByTab.containsKey(tab));
  }

  Future<void> retry() {
    return _loadSelectedTab(forceReload: true);
  }

  Future<bool> generatePaygradesWithAi({required int numPaygrades}) async {
    if (_isGeneratingPaygrades ||
        _isUpdatingPaygrade ||
        _deletingPaygradeId != null) {
      return false;
    }

    final currentDetail = detail;
    final resolvedActualId = currentDetail?.id.trim().isNotEmpty == true
        ? currentDetail!.id
        : _paygradeId.trim();
    if (resolvedActualId.isEmpty) {
      return false;
    }

    _isGeneratingPaygrades = true;
    _paygradeGenerationErrorMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      await _getPaygradesUseCase.generatePaygrades(
        actualId: resolvedActualId,
        numPaygrades: numPaygrades,
      );
      _detailsByTab.clear();
      await _loadSelectedTab(forceReload: true);
      if (!_detailsByTab.containsKey(_selectedTab)) {
        _paygradeGenerationErrorMessage =
            _errorMessage ?? AppStrings.loginSomethingWentWrong;
        return false;
      }

      return true;
    } catch (error) {
      _paygradeGenerationErrorMessage = error.toString();
      return false;
    } finally {
      _isGeneratingPaygrades = false;
      notifyListeners();
    }
  }

  Future<void> createPaygrade({
    required String title,
    required String description,
    required String promotionRequirement,
  }) async {
    if (_isGeneratingPaygrades ||
        _isUpdatingPaygrade ||
        _deletingPaygradeId != null) {
      return;
    }

    final currentDetail = detail;
    if (currentDetail == null) {
      throw StateError(AppStrings.loginSomethingWentWrong);
    }

    final nextPosition = currentDetail.payGrades.length + 1;
    final nextLevel = _resolveNextLevel(currentDetail.payGrades);

    _isUpdatingPaygrade = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdEntry = await _getPaygradesUseCase.createPaygrade(
        jobId: currentDetail.id.trim().isNotEmpty
            ? currentDetail.id
            : _paygradeId,
        type: _selectedTab.apiValue,
        level: nextLevel.toString(),
        title: title,
        description: description,
        promotionRequirement: promotionRequirement,
        position: nextPosition,
        fromSandbox: AppManager.instance.usesParentApiEndpoints,
      );
      if (createdEntry.id.trim().isEmpty) {
        await _loadSelectedTab(forceReload: true);
        return;
      }
      _appendEntry(
        PaygradeEntry(
          id: createdEntry.id,
          type: createdEntry.type.trim().isNotEmpty
              ? createdEntry.type
              : _selectedTab.apiValue,
          title: createdEntry.title.trim().isNotEmpty
              ? createdEntry.title
              : title,
          payRate: createdEntry.payRate,
          level: createdEntry.level > 0 ? createdEntry.level : nextLevel,
          description: createdEntry.description.trim().isNotEmpty
              ? createdEntry.description
              : description,
          promotionRequirement:
              createdEntry.promotionRequirement.trim().isNotEmpty
              ? createdEntry.promotionRequirement
              : promotionRequirement,
        ),
      );
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isUpdatingPaygrade = false;
      notifyListeners();
    }
  }

  Future<void> updatePaygrade({
    required PaygradeEntry entry,
    required String title,
    required String description,
    required String promotionRequirement,
  }) async {
    if (_isGeneratingPaygrades ||
        _isUpdatingPaygrade ||
        _deletingPaygradeId != null) {
      return;
    }

    _isUpdatingPaygrade = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _getPaygradesUseCase.updatePaygrade(
        paygradeId: entry.id,
        title: title,
        description: description,
        promotionRequirement: promotionRequirement,
      );
      _replaceEntry(
        PaygradeEntry(
          id: entry.id,
          type: entry.type,
          title: title,
          payRate: entry.payRate,
          level: entry.level,
          description: description,
          promotionRequirement: promotionRequirement,
        ),
      );
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isUpdatingPaygrade = false;
      notifyListeners();
    }
  }

  Future<bool> deletePaygrade(PaygradeEntry entry) async {
    if (_isGeneratingPaygrades ||
        _isUpdatingPaygrade ||
        _deletingPaygradeId != null) {
      return false;
    }

    _deletingPaygradeId = entry.id;
    _errorMessage = null;
    notifyListeners();

    try {
      await _getPaygradesUseCase.deletePaygrade(entry.id);
      _removeEntry(entry.id);
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _deletingPaygradeId = null;
      notifyListeners();
    }
  }

  Future<void> _loadSelectedTab({required bool forceReload}) async {
    if (_isLoading || _paygradeId.isEmpty) {
      return;
    }

    if (!forceReload && _detailsByTab.containsKey(_selectedTab)) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _detailsByTab[_selectedTab] = await _getPaygradesUseCase
          .getPaygradeDetail(
            paygradeId: _paygradeId,
            type: _selectedTab.apiValue,
          );
    } catch (error) {
      _errorMessage = error.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _replaceEntry(PaygradeEntry updatedEntry) {
    final currentDetail = detail;
    if (currentDetail == null) {
      return;
    }

    final updatedEntries = currentDetail.payGrades
        .map((entry) => entry.id == updatedEntry.id ? updatedEntry : entry)
        .toList(growable: false);

    _detailsByTab[_selectedTab] = PaygradeDetail(
      id: currentDetail.id,
      title: currentDetail.title,
      paygradeUnit: currentDetail.paygradeUnit,
      department: currentDetail.department,
      payGrades: updatedEntries,
    );
  }

  void _appendEntry(PaygradeEntry entry) {
    final currentDetail = detail;
    if (currentDetail == null) {
      return;
    }

    _detailsByTab[_selectedTab] = PaygradeDetail(
      id: currentDetail.id,
      title: currentDetail.title,
      paygradeUnit: currentDetail.paygradeUnit,
      department: currentDetail.department,
      payGrades: <PaygradeEntry>[...currentDetail.payGrades, entry],
    );
  }

  void _removeEntry(String paygradeId) {
    final currentDetail = detail;
    if (currentDetail == null) {
      return;
    }

    _detailsByTab[_selectedTab] = PaygradeDetail(
      id: currentDetail.id,
      title: currentDetail.title,
      paygradeUnit: currentDetail.paygradeUnit,
      department: currentDetail.department,
      payGrades: currentDetail.payGrades
          .where((entry) => entry.id != paygradeId)
          .toList(growable: false),
    );
  }

  int _resolveNextLevel(List<PaygradeEntry> entries) {
    var highestLevel = 0;
    for (final entry in entries) {
      if (entry.level > highestLevel) {
        highestLevel = entry.level;
      }
    }

    return highestLevel + 1;
  }
}

extension on PaygradeDetailTab {
  String get apiValue {
    return switch (this) {
      PaygradeDetailTab.primary => 'primary',
      PaygradeDetailTab.ancillary => 'ancillary',
    };
  }
}

PaygradeRepositoryImpl createPaygradeDetailRepository(
  PaygradeRemoteDataSource remoteDataSource,
) {
  return PaygradeRepositoryImpl(remoteDataSource);
}

GetPaygradesUseCase createGetPaygradeDetailUseCase(
  PaygradeRepositoryImpl repository,
) {
  return GetPaygradesUseCase(repository);
}

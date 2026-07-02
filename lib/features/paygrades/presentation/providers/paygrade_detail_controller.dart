import 'package:flutter/material.dart';

import '../../data/datasources/paygrade_remote_data_source.dart';
import '../../data/repositories/paygrade_repository_impl.dart';
import '../../domain/entities/paygrade_detail.dart';
import '../../domain/usecases/get_paygrades_usecase.dart';

enum PaygradeDetailTab { primary, ancillary }

class PaygradeDetailController extends ChangeNotifier {
  PaygradeDetailController(this._getPaygradesUseCase);

  final GetPaygradesUseCase _getPaygradesUseCase;

  bool _isLoading = false;
  String? _errorMessage;
  String _paygradeId = '';
  PaygradeDetailTab _selectedTab = PaygradeDetailTab.primary;
  final Map<PaygradeDetailTab, PaygradeDetail> _detailsByTab =
      <PaygradeDetailTab, PaygradeDetail>{};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PaygradeDetailTab get selectedTab => _selectedTab;
  PaygradeDetail? get detail => _detailsByTab[_selectedTab];

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

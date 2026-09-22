import 'package:flutter/foundation.dart';

import '../../data/datasources/compliance_remote_data_source.dart';
import '../../data/repositories/compliance_repository_impl.dart';
import '../../domain/entities/compliance_overview.dart';
import '../../domain/entities/compliance_tab_type.dart';
import '../../domain/usecases/get_compliance_overview_usecase.dart';
import 'compliance_state.dart';

class ComplianceController extends ChangeNotifier {
  ComplianceController(this._getComplianceOverviewUseCase);

  final GetComplianceOverviewUseCase _getComplianceOverviewUseCase;
  ComplianceState _state = const ComplianceState();
  Future<void>? _initializeOperation;

  ComplianceState get state => _state;

  Future<void> initialize({
    bool showLoading = true,
    bool forceRefresh = false,
  }) async {
    final existingOperation = _initializeOperation;
    if (existingOperation != null) {
      await existingOperation;
      return;
    }

    final operation = _runInitialize(
      showLoading: showLoading,
      forceRefresh: forceRefresh,
    );
    _initializeOperation = operation;

    try {
      await operation;
    } finally {
      if (identical(_initializeOperation, operation)) {
        _initializeOperation = null;
      }
    }
  }

  Future<void> _runInitialize({
    required bool showLoading,
    required bool forceRefresh,
  }) async {
    if (showLoading && !_state.isLoading) {
      _state = _state.copyWith(isLoading: true);
      notifyListeners();
    }

    try {
      final overview = await _getComplianceOverviewUseCase(
        forceRefresh: forceRefresh,
      );
      _state = _state.copyWith(isLoading: false, overview: overview);
    } catch (error) {
      debugPrint('Compliance initialize failed: $error');
      _state = showLoading
          ? _state.copyWith(
              isLoading: false,
              overview: const ComplianceOverview(
                learningTracks: [],
                documents: [],
              ),
            )
          : _state.copyWith(isLoading: false);
    }
    notifyListeners();
  }

  Future<void> refreshCurrentTab() {
    return initialize(showLoading: false, forceRefresh: true);
  }

  void selectTab(ComplianceTabType tab) {
    if (_state.selectedTab == tab) {
      return;
    }

    _state = _state.copyWith(selectedTab: tab);
    notifyListeners();
  }
}

ComplianceRemoteDataSource createComplianceRemoteDataSource() {
  return ComplianceRemoteDataSource();
}

ComplianceRepositoryImpl createComplianceRepository(
  ComplianceRemoteDataSource remoteDataSource,
) {
  return ComplianceRepositoryImpl(remoteDataSource);
}

GetComplianceOverviewUseCase createGetComplianceOverviewUseCase(
  ComplianceRepositoryImpl repository,
) {
  return GetComplianceOverviewUseCase(repository);
}

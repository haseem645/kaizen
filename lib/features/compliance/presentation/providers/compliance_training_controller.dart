import 'package:flutter/foundation.dart';

import '../../domain/entities/compliance_track_item_detail.dart';
import '../../domain/entities/learning_module_detail_track.dart';
import '../../domain/usecases/get_compliance_track_item_detail_usecase.dart';
import '../../domain/usecases/get_compliance_tracks_usecase.dart';

class ComplianceTrainingController extends ChangeNotifier {
  ComplianceTrainingController(
    this._getComplianceTrackItemDetailUseCase,
    this._getComplianceTracksUseCase,
  );

  final GetComplianceTrackItemDetailUseCase
  _getComplianceTrackItemDetailUseCase;
  final GetComplianceTracksUseCase _getComplianceTracksUseCase;

  bool _isLoading = true;
  ComplianceTrackItemDetail? _detail;
  LearningTrackModuleDetail? _currentTrack;
  int _moduleCount = 0;
  int _currentModuleNumber = 0;
  int _loadGeneration = 0;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;
  ComplianceTrackItemDetail? get detail => _detail;
  LearningTrackModuleDetail? get currentTrack => _currentTrack;
  int get moduleCount => _moduleCount;
  int get currentModuleNumber => _currentModuleNumber;

  Future<bool> initialize({
    required String trackAssignmentUuid,
    required String itemUuid,
  }) async {
    if (_isDisposed) {
      return false;
    }
    final generation = ++_loadGeneration;
    _isLoading = true;
    _detail = null;
    _currentTrack = null;
    _moduleCount = 0;
    _currentModuleNumber = 0;
    notifyListeners();

    // Both reads can start together; quiz requests do not gate video readiness.
    final detailFuture = _loadDetail(
      trackAssignmentUuid: trackAssignmentUuid,
      itemUuid: itemUuid,
    );
    final tracks = await _loadTracks(trackAssignmentUuid);
    final detail = await detailFuture;
    if (_isDisposed || generation != _loadGeneration) {
      return false;
    }

    final modules = tracks.where((track) => !track.isBreakPoint).toList();
    final index = modules.indexWhere(
      (track) => track.trainingModuleItemId == itemUuid,
    );
    _moduleCount = modules.length;
    if (index >= 0) {
      _currentTrack = modules[index];
      _currentModuleNumber = index + 1;
      _detail = detail;
    }
    _isLoading = false;
    notifyListeners();
    return _detail != null;
  }

  Future<ComplianceTrackItemDetail?> _loadDetail({
    required String trackAssignmentUuid,
    required String itemUuid,
  }) async {
    try {
      return await _getComplianceTrackItemDetailUseCase.call(
        trackAssignmentUuid: trackAssignmentUuid,
        itemUuid: itemUuid,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<LearningTrackModuleDetail>> _loadTracks(
    String trackAssignmentUuid,
  ) async {
    try {
      return await _getComplianceTracksUseCase(
        trackAssignmentUuid: trackAssignmentUuid,
      );
    } catch (_) {
      return const [];
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadGeneration++;
    super.dispose();
  }
}

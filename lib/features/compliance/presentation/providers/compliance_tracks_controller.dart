import 'package:flutter/material.dart';

import '../../domain/entities/learning_module_detail_track.dart';
import '../../domain/usecases/get_compliance_tracks_usecase.dart';

class ComplianceTracksController extends ChangeNotifier {
  ComplianceTracksController(this._getComplianceTracksUseCase);

  final GetComplianceTracksUseCase _getComplianceTracksUseCase;
  final TextEditingController searchController = TextEditingController();

  bool _isLoading = true;
  List<LearningTrackModuleDetail> _tracks = const <LearningTrackModuleDetail>[];
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  List<LearningTrackModuleDetail> get allTracks => _tracks;

  List<LearningTrackModuleDetail> get filteredTracks {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _tracks.where((track) => !track.isBreakPoint).toList(growable: false);
    }

    return _tracks
        .where((track) {
          if (track.isBreakPoint) {
            return false;
          }

          return track.displayName.toLowerCase().contains(query) ||
              track.displayStatus.toLowerCase().contains(query) ||
              track.displayJob.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Future<void> initialize(String trackAssignmentUuid) async {
    _isLoading = true;
    notifyListeners();

    try {
      _tracks = await _getComplianceTracksUseCase.call(trackAssignmentUuid: trackAssignmentUuid);
    } catch (_) {
      _tracks = const <LearningTrackModuleDetail>[];
    }

    _isLoading = false;
    notifyListeners();
  }

  void updateSearchQuery(String value) {
    if (_searchQuery == value) {
      return;
    }

    _searchQuery = value;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

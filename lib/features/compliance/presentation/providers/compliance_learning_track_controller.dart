import 'package:flutter/material.dart';

import '../../domain/entities/learning_module_detail_track.dart';

class ComplianceLearningTrackController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();

  List<LearningTrackModuleDetail> _tracks = const <LearningTrackModuleDetail>[];
  String _searchQuery = '';
  Set<String> _selectedSeatProfiles = <String>{};

  List<LearningTrackModuleDetail> get filteredTracks {
    final query = _searchQuery.trim().toLowerCase();

    return _tracks.where((track) {
      final matchesSeatProfile =
          _selectedSeatProfiles.isEmpty || _selectedSeatProfiles.contains(track.displayJob);

      final matchesQuery =
          query.isEmpty ||
          track.displayName.toLowerCase().contains(query) ||
          track.displayJob.toLowerCase().contains(query) ||
          track.displayStatus.toLowerCase().contains(query) ||
          track.displayDeadline.toLowerCase().contains(query) ||
          track.displaySchedule.toLowerCase().contains(query);

      return matchesSeatProfile && matchesQuery;
    }).toList();
  }

  List<String> get seatProfiles {
    final values = _tracks.map((track) => track.displayJob).toSet().toList();
    values.sort();
    return values;
  }

  Set<String> get selectedSeatProfiles => Set<String>.unmodifiable(_selectedSeatProfiles);

  void setTracks(List<LearningTrackModuleDetail> tracks) {
    _tracks = List<LearningTrackModuleDetail>.unmodifiable(tracks);
    notifyListeners();
  }

  void updateSearchQuery(String value, BuildContext context) {
    if (_searchQuery == value) {
      return;
    }
    _searchQuery = value;
    notifyListeners();
  }

  void updateSelectedSeatProfiles(Set<String> seatProfiles) {
    _selectedSeatProfiles = Set<String>.from(seatProfiles);
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

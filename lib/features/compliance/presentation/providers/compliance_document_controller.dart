import 'package:flutter/material.dart';

import '../../domain/entities/compliance_document.dart';
import '../../domain/usecases/get_compliance_documents_usecase.dart';

class ComplianceDocumentController extends ChangeNotifier {
  ComplianceDocumentController(this._getComplianceDocumentsUseCase);

  final GetComplianceDocumentsUseCase _getComplianceDocumentsUseCase;
  final TextEditingController searchController = TextEditingController();

  bool _isLoading = false;
  List<ComplianceDocument> _documents = const <ComplianceDocument>[];
  String _searchQuery = '';
  Set<String> _selectedSeatProfiles = <String>{};
  bool _hasLoaded = false;

  bool get isLoading => _isLoading;

  List<ComplianceDocument> get filteredDocuments {
    final query = _searchQuery.trim().toLowerCase();

    return _documents.where((document) {
      final matchesSeatProfile =
          _selectedSeatProfiles.isEmpty ||
          document.seatProfiles.any(_selectedSeatProfiles.contains) ||
          (_selectedSeatProfiles.contains('All Jobs') &&
              document.seatProfiles.isEmpty);

      final matchesQuery =
          query.isEmpty ||
          document.title.toLowerCase().contains(query) ||
          document.category.toLowerCase().contains(query) ||
          document.status.toLowerCase().contains(query) ||
          document.seatProfiles.any(
            (profile) => profile.toLowerCase().contains(query),
          );

      return matchesSeatProfile && matchesQuery;
    }).toList();
  }

  List<String> get seatProfiles {
    final values = _documents
        .expand((document) => document.seatProfiles)
        .where((profile) => profile.trim().isNotEmpty)
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  Set<String> get selectedSeatProfiles =>
      Set<String>.unmodifiable(_selectedSeatProfiles);

  Future<void> initialize({bool forceRefresh = false}) async {
    if (_isLoading || (_hasLoaded && !forceRefresh)) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _documents = List<ComplianceDocument>.unmodifiable(
        await _getComplianceDocumentsUseCase(forceRefresh: forceRefresh),
      );
      _hasLoaded = true;
    } catch (_) {
      _documents = const <ComplianceDocument>[];
      _hasLoaded = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() {
    return initialize(forceRefresh: true);
  }

  void setDocuments(List<ComplianceDocument> documents) {
    _documents = List<ComplianceDocument>.unmodifiable(documents);
    _hasLoaded = true;
    notifyListeners();
  }

  void updateSearchQuery(String value) {
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

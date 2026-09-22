import 'package:flutter/material.dart';

import '../../../seat_profile/domain/entities/seat_profile_detail.dart';
import '../../../seat_profile/domain/usecases/get_seat_profiles_usecase.dart';

enum TrainingSetupPickerType { seatProfile, category, description }

class TrainingSetupController extends ChangeNotifier {
  TrainingSetupController(
    this._getSeatProfilesUseCase, {
    bool Function(SeatProfileDetail seatProfile)? canManageSeatProfile,
  }) : _canManageSeatProfile = canManageSeatProfile ?? _allowEverySeatProfile;

  static bool _allowEverySeatProfile(SeatProfileDetail seatProfile) => true;

  final GetSeatProfilesUseCase _getSeatProfilesUseCase;
  final bool Function(SeatProfileDetail seatProfile) _canManageSeatProfile;
  final TextEditingController seatProfileSearchController =
      TextEditingController();
  final FocusNode seatProfileSearchFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  List<SeatProfileDetail> _seatProfiles = const <SeatProfileDetail>[];
  String? _selectedSeatProfileId;
  String? _selectedCategoryId;
  String? _selectedDescriptionId;
  String _seatProfileSearchQuery = '';
  TrainingSetupPickerType? _openPickerType;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SeatProfileDetail> get seatProfiles =>
      List<SeatProfileDetail>.unmodifiable(_seatProfiles);
  String? get selectedSeatProfileId => _selectedSeatProfileId;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedDescriptionId => _selectedDescriptionId;
  bool get isSeatProfilePickerOpen =>
      _openPickerType == TrainingSetupPickerType.seatProfile;
  bool get isCategoryPickerOpen =>
      _openPickerType == TrainingSetupPickerType.category;
  bool get isDescriptionPickerOpen =>
      _openPickerType == TrainingSetupPickerType.description;

  List<SeatProfileDetail> get filteredSeatProfiles {
    final normalizedQuery = _seatProfileSearchQuery.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return List<SeatProfileDetail>.unmodifiable(_seatProfiles);
    }

    return List<SeatProfileDetail>.unmodifiable(
      _seatProfiles.where((seatProfile) {
        final title = seatProfile.title.trim().toLowerCase();
        final departmentName =
            seatProfile.department?.name.trim().toLowerCase() ?? '';
        return title.contains(normalizedQuery) ||
            departmentName.contains(normalizedQuery);
      }),
    );
  }

  SeatProfileDetail? get selectedSeatProfile {
    final id = _selectedSeatProfileId;
    if (id == null || id.isEmpty) {
      return null;
    }

    for (final seatProfile in _seatProfiles) {
      if (seatProfile.id == id) {
        return seatProfile;
      }
    }

    return null;
  }

  List<SeatProfileCategory> get categoryOptions =>
      selectedSeatProfile?.categories ?? const <SeatProfileCategory>[];

  SeatProfileCategory? get selectedCategory {
    final id = _selectedCategoryId;
    if (id == null || id.isEmpty) {
      return null;
    }

    for (final category in categoryOptions) {
      if (category.id == id) {
        return category;
      }
    }

    return null;
  }

  List<SeatProfileDescription> get descriptionOptions =>
      selectedCategory?.descriptions ?? const <SeatProfileDescription>[];

  SeatProfileDescription? get selectedDescription {
    final id = _selectedDescriptionId;
    if (id == null || id.isEmpty) {
      return null;
    }

    for (final description in descriptionOptions) {
      if (description.id == id) {
        return description;
      }
    }

    return null;
  }

  bool get canViewTraining {
    return canManageSelectedSeatProfile &&
        (_selectedCategoryId?.trim().isNotEmpty ?? false) &&
        (_selectedDescriptionId?.trim().isNotEmpty ?? false);
  }

  bool get canManageSelectedSeatProfile {
    final seatProfile = selectedSeatProfile;
    return seatProfile != null && _canManageSeatProfile(seatProfile);
  }

  Future<void> initialize({
    String? initialSeatProfileId,
    String? initialCategoryId,
    String? initialDescriptionId,
  }) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loadedSeatProfiles = await _getSeatProfilesUseCase
          .seatProfileCategoryTrainings();
      _seatProfiles = loadedSeatProfiles
          .where(_canManageSeatProfile)
          .toList(growable: false);
      _selectedSeatProfileId = _resolveSeatProfileId(initialSeatProfileId);
      if (_selectedSeatProfileId == null) {
        _selectedCategoryId = null;
        _selectedDescriptionId = null;
      } else {
        _syncCategorySelection(
          preferredCategoryId: initialCategoryId,
          preferredDescriptionId: initialDescriptionId,
        );
      }
      _syncSeatProfileSearchText();
    } catch (error) {
      _errorMessage = error.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectSeatProfile(String? value) {
    final normalizedValue = value?.trim() ?? '';
    if (normalizedValue.isEmpty) {
      if (_selectedSeatProfileId == null &&
          _selectedCategoryId == null &&
          _selectedDescriptionId == null) {
        return;
      }

      _selectedSeatProfileId = null;
      _selectedCategoryId = null;
      _selectedDescriptionId = null;
      _closeAllPickers(unfocusSeatProfile: true);
      notifyListeners();
      return;
    }

    if (normalizedValue.isNotEmpty &&
        !_seatProfiles.any(
          (seatProfile) => seatProfile.id == normalizedValue,
        )) {
      return;
    }

    if (normalizedValue == _selectedSeatProfileId) {
      _closeAllPickers(unfocusSeatProfile: true);
      notifyListeners();
      return;
    }

    _selectedSeatProfileId = normalizedValue;
    _selectedCategoryId = null;
    _selectedDescriptionId = null;
    _closeAllPickers(unfocusSeatProfile: true);
    notifyListeners();
  }

  void selectCategory(String? value) {
    final normalizedValue = value?.trim() ?? '';
    if (normalizedValue.isEmpty) {
      if (_selectedCategoryId == null && _selectedDescriptionId == null) {
        return;
      }

      _selectedCategoryId = null;
      _selectedDescriptionId = null;
      _openPickerType = null;
      notifyListeners();
      return;
    }

    if (normalizedValue == _selectedCategoryId) {
      _openPickerType = null;
      notifyListeners();
      return;
    }

    _selectedCategoryId = normalizedValue;
    _syncDescriptionSelection();
    _openPickerType = null;
    notifyListeners();
  }

  void selectDescription(String? value) {
    final normalizedValue = value?.trim();
    if (normalizedValue == _selectedDescriptionId) {
      _openPickerType = null;
      notifyListeners();
      return;
    }

    _selectedDescriptionId = normalizedValue?.isEmpty ?? true
        ? null
        : normalizedValue;
    _openPickerType = null;
    notifyListeners();
  }

  void openSeatProfilePicker() {
    if (isSeatProfilePickerOpen) {
      return;
    }

    _openPickerType = TrainingSetupPickerType.seatProfile;
    notifyListeners();
  }

  void toggleSeatProfilePicker() {
    if (isSeatProfilePickerOpen) {
      closeSeatProfilePicker();
      seatProfileSearchFocusNode.unfocus();
      return;
    }

    openSeatProfilePicker();
    seatProfileSearchFocusNode.requestFocus();
  }

  void closeSeatProfilePicker() {
    final selectedTitle = selectedSeatProfile?.title.trim() ?? '';
    final needsTextSync = seatProfileSearchController.text != selectedTitle;
    if (!isSeatProfilePickerOpen &&
        _seatProfileSearchQuery.isEmpty &&
        !needsTextSync) {
      return;
    }

    if (isSeatProfilePickerOpen) {
      _openPickerType = null;
    }
    _restoreSeatProfileSearchPresentation();
    notifyListeners();
  }

  void updateSeatProfileSearchQuery(String value) {
    final shouldOpen = !isSeatProfilePickerOpen;
    if (_seatProfileSearchQuery == value && !shouldOpen) {
      return;
    }

    _seatProfileSearchQuery = value;
    _openPickerType = TrainingSetupPickerType.seatProfile;
    notifyListeners();
  }

  void toggleCategoryPicker() {
    if (categoryOptions.isEmpty) {
      return;
    }

    if (isCategoryPickerOpen) {
      _openPickerType = null;
      notifyListeners();
      return;
    }

    _restoreSeatProfileSearchPresentation(unfocus: true);
    _openPickerType = TrainingSetupPickerType.category;
    notifyListeners();
  }

  void closeCategoryPicker() {
    if (!isCategoryPickerOpen) {
      return;
    }

    _openPickerType = null;
    notifyListeners();
  }

  void toggleDescriptionPicker() {
    if (descriptionOptions.isEmpty) {
      return;
    }

    if (isDescriptionPickerOpen) {
      _openPickerType = null;
      notifyListeners();
      return;
    }

    _restoreSeatProfileSearchPresentation(unfocus: true);
    _openPickerType = TrainingSetupPickerType.description;
    notifyListeners();
  }

  void closeDescriptionPicker() {
    if (!isDescriptionPickerOpen) {
      return;
    }

    _openPickerType = null;
    notifyListeners();
  }

  void highlightSeatProfileSearchText() {
    final text = seatProfileSearchController.text;
    if (text.isEmpty) {
      return;
    }

    seatProfileSearchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );
  }

  void _closeAllPickers({bool unfocusSeatProfile = false}) {
    _openPickerType = null;
    _restoreSeatProfileSearchPresentation(unfocus: unfocusSeatProfile);
  }

  void _restoreSeatProfileSearchPresentation({bool unfocus = false}) {
    _seatProfileSearchQuery = '';
    _syncSeatProfileSearchText();
    if (unfocus) {
      seatProfileSearchFocusNode.unfocus();
    }
  }

  String? _resolveSeatProfileId(String? preferredSeatProfileId) {
    final resolvedPreferredId = preferredSeatProfileId?.trim() ?? '';
    if (resolvedPreferredId.isNotEmpty) {
      for (final seatProfile in _seatProfiles) {
        if (seatProfile.id == resolvedPreferredId) {
          return resolvedPreferredId;
        }
      }
    }

    return null;
  }

  void _syncCategorySelection({
    String? preferredCategoryId,
    String? preferredDescriptionId,
  }) {
    final categories = categoryOptions;
    if (categories.isEmpty) {
      _selectedCategoryId = null;
      _selectedDescriptionId = null;
      return;
    }

    final resolvedPreferredCategoryId = preferredCategoryId?.trim() ?? '';
    if (resolvedPreferredCategoryId.isNotEmpty) {
      for (final category in categories) {
        if (category.id == resolvedPreferredCategoryId) {
          _selectedCategoryId = resolvedPreferredCategoryId;
          _syncDescriptionSelection(
            preferredDescriptionId: preferredDescriptionId,
          );
          return;
        }
      }
    }

    final currentCategoryId = _selectedCategoryId?.trim() ?? '';
    if (currentCategoryId.isNotEmpty) {
      for (final category in categories) {
        if (category.id == currentCategoryId) {
          _syncDescriptionSelection(
            preferredDescriptionId: preferredDescriptionId,
          );
          return;
        }
      }
    }

    _selectedCategoryId = null;
    _selectedDescriptionId = null;
  }

  void _syncDescriptionSelection({String? preferredDescriptionId}) {
    final descriptions = descriptionOptions;
    if (descriptions.isEmpty) {
      _selectedDescriptionId = null;
      return;
    }

    final resolvedPreferredDescriptionId = preferredDescriptionId?.trim() ?? '';
    if (resolvedPreferredDescriptionId.isNotEmpty) {
      for (final description in descriptions) {
        if (description.id == resolvedPreferredDescriptionId) {
          _selectedDescriptionId = resolvedPreferredDescriptionId;
          return;
        }
      }
    }

    final currentDescriptionId = _selectedDescriptionId?.trim() ?? '';
    if (currentDescriptionId.isNotEmpty) {
      for (final description in descriptions) {
        if (description.id == currentDescriptionId) {
          return;
        }
      }
    }

    _selectedDescriptionId = null;
  }

  void _syncSeatProfileSearchText() {
    final selectedTitle = selectedSeatProfile?.title.trim() ?? '';
    if (seatProfileSearchController.text == selectedTitle) {
      return;
    }

    seatProfileSearchController.value = TextEditingValue(
      text: selectedTitle,
      selection: TextSelection.collapsed(offset: selectedTitle.length),
    );
  }

  @override
  void dispose() {
    seatProfileSearchController.dispose();
    seatProfileSearchFocusNode.dispose();
    super.dispose();
  }
}

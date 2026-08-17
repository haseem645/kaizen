import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/seat_profile_category_draft.dart';
import '../../domain/entities/seat_profile_creation_result.dart';
import '../../domain/entities/seat_profile_detail.dart';
import '../../domain/usecases/get_seat_profiles_usecase.dart';
import '../models/seat_profile_form_initial_data.dart';

enum SeatProfilePaygradeUnit {
  hourly('hr'),
  monthly('monthly'),
  comission('comission');

  const SeatProfilePaygradeUnit(this.apiValue);

  final String apiValue;

  static SeatProfilePaygradeUnit? fromApiValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    return switch (normalized) {
      'hr' => SeatProfilePaygradeUnit.hourly,
      'monthly' => SeatProfilePaygradeUnit.monthly,
      'comission' || 'commission' => SeatProfilePaygradeUnit.comission,
      _ => null,
    };
  }

  String get label {
    return switch (this) {
      SeatProfilePaygradeUnit.hourly => AppStrings.seatProfilePaygradeHourly,
      SeatProfilePaygradeUnit.monthly => AppStrings.seatProfilePaygradeMonthly,
      SeatProfilePaygradeUnit.comission =>
        AppStrings.seatProfilePaygradeComission,
    };
  }
}

enum SeatContentSpecificity {
  low('low'),
  medium('medium'),
  high('high');

  const SeatContentSpecificity(this.apiValue);

  final String apiValue;

  String get label {
    return switch (this) {
      SeatContentSpecificity.low => AppStrings.seatProfileAiLow,
      SeatContentSpecificity.medium => AppStrings.seatProfileAiMedium,
      SeatContentSpecificity.high => AppStrings.seatProfileAiHigh,
    };
  }
}

enum SeatContentTone {
  layman('layman'),
  professional('professional'),
  technical('technical');

  const SeatContentTone(this.apiValue);

  final String apiValue;

  String get label {
    return switch (this) {
      SeatContentTone.layman => AppStrings.seatProfileAiLayman,
      SeatContentTone.professional => AppStrings.seatProfileAiProfessional,
      SeatContentTone.technical => AppStrings.seatProfileAiTechnical,
    };
  }
}

class SeatProfileCreateController extends ChangeNotifier {
  SeatProfileCreateController(
    this._getSeatProfilesUseCase, {
    SeatProfileFormInitialData? initialData,
  }) : _initialData = initialData {
    nameController.addListener(_handleNameChanged);
    if (_initialData != null) {
      nameController.text = _initialData.name;
      _selectedPaygradeUnit = SeatProfilePaygradeUnit.fromApiValue(
        _initialData.paygradeUnit,
      );
    }
  }

  final GetSeatProfilesUseCase _getSeatProfilesUseCase;
  final SeatProfileFormInitialData? _initialData;
  final TextEditingController nameController = TextEditingController();

  bool _isLoadingDepartments = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<Department> _departments = const <Department>[];
  Department? _selectedDepartment;
  SeatProfilePaygradeUnit? _selectedPaygradeUnit;
  SeatProfileCreationResult? _createdProfile;
  bool _hasUnlockedDescriptionActions = false;
  bool _isGeneratingSeatContent = false;
  String? _seatContentGenerationErrorMessage;
  SeatContentSpecificity _selectedSpecificity = SeatContentSpecificity.medium;
  SeatContentTone _selectedTone = SeatContentTone.professional;
  bool _didUpdateProfile = false;

  bool get isLoadingDepartments => _isLoadingDepartments;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<Department> get departments =>
      List<Department>.unmodifiable(_departments);
  Department? get selectedDepartment => _selectedDepartment;
  SeatProfilePaygradeUnit? get selectedPaygradeUnit => _selectedPaygradeUnit;
  SeatProfileCreationResult? get createdProfile => _createdProfile;
  bool get hasCreatedProfile => _createdProfile != null;
  bool get hasUnlockedDescriptionActions => _hasUnlockedDescriptionActions;
  bool get isGeneratingSeatContent => _isGeneratingSeatContent;
  String? get seatContentGenerationErrorMessage =>
      _seatContentGenerationErrorMessage;
  SeatContentSpecificity get selectedSpecificity => _selectedSpecificity;
  SeatContentTone get selectedTone => _selectedTone;
  String get detailTargetSeatId {
    final createdProfile = _createdProfile;
    if (createdProfile != null) {
      final resolvedActualId = createdProfile.actualId.trim();
      if (resolvedActualId.isNotEmpty) {
        return resolvedActualId;
      }

      return createdProfile.id.trim();
    }

    final initialActualId = _initialData?.actualId?.trim() ?? '';
    if (initialActualId.isNotEmpty) {
      return initialActualId;
    }

    final initialSeatId = _initialData?.seatId.trim() ?? '';
    if (initialSeatId.isNotEmpty) {
      return initialSeatId;
    }

    return _initialData?.updateTargetId ?? '';
  }

  bool get isEditMode => _initialData != null && _initialData.isValid;
  String get title => isEditMode
      ? AppStrings.seatProfileEditTitle
      : AppStrings.seatProfileCreateTitle;
  String get submitActionLabel => isEditMode
      ? AppStrings.seatProfileUpdateAction
      : AppStrings.seatProfileSaveAction;
  bool get didCompleteFlow => hasCreatedProfile || _didUpdateProfile;
  bool get isFormLocked => hasCreatedProfile;
  bool get areSelectionFieldsLocked => hasCreatedProfile || isEditMode;
  bool get showDescriptionActions => hasCreatedProfile || isEditMode;
  bool get canUseDescriptionActions =>
      (((hasCreatedProfile && _hasUnlockedDescriptionActions) || isEditMode) &&
          _actionTargetId.isNotEmpty) &&
      !_isGeneratingSeatContent;
  SeatProfileCategory? get selectedCategoryForDescriptions =>
      _initialData?.initialCategory;
  bool get canSubmit =>
      !_isLoadingDepartments &&
      !_isSubmitting &&
      !isFormLocked &&
      nameController.text.trim().isNotEmpty &&
      _selectedDepartment != null &&
      _selectedPaygradeUnit != null;

  Future<void> initialize() async {
    if (_isLoadingDepartments) {
      return;
    }

    _isLoadingDepartments = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loadedDepartments = await _getSeatProfilesUseCase.getDepartments();
      _departments = List<Department>.unmodifiable(
        _mergeInitialDepartmentIfNeeded(loadedDepartments),
      );
      _applyInitialSelections();
    } catch (error) {
      _errorMessage = error.toString();
    }

    _isLoadingDepartments = false;
    notifyListeners();
  }

  void selectDepartment(String? departmentId) {
    if (departmentId == null || isFormLocked) {
      return;
    }

    Department? selected;
    for (final department in _departments) {
      if (department.id == departmentId) {
        selected = department;
        break;
      }
    }

    if (_selectedDepartment?.id == selected?.id) {
      return;
    }

    _selectedDepartment = selected;
    _errorMessage = null;
    notifyListeners();
  }

  void selectPaygradeUnit(SeatProfilePaygradeUnit? unit) {
    if (unit == null || isFormLocked || _selectedPaygradeUnit == unit) {
      return;
    }

    _selectedPaygradeUnit = unit;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> submit() async {
    if (_isSubmitting || isFormLocked) {
      return false;
    }

    final resolvedName = nameController.text.trim();
    if (resolvedName.isEmpty) {
      _errorMessage = AppStrings.seatProfileNameRequired;
      notifyListeners();
      return false;
    }

    final department = _selectedDepartment;
    if (department == null) {
      _errorMessage = AppStrings.seatProfileDepartmentRequired;
      notifyListeners();
      return false;
    }

    final paygradeUnit = _selectedPaygradeUnit;
    if (paygradeUnit == null) {
      _errorMessage = AppStrings.seatProfilePaygradeRequired;
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isEditMode) {
        final updateTargetId = _initialData?.updateTargetId ?? '';
        if (updateTargetId.isEmpty) {
          _errorMessage = AppStrings.loginSomethingWentWrong;
          return false;
        }

        await _getSeatProfilesUseCase.updateSeatProfile(
          seatId: updateTargetId,
          department: department,
          title: resolvedName,
          paygradeUnit: paygradeUnit.apiValue,
        );
        _didUpdateProfile = true;
      } else {
        _createdProfile = await _getSeatProfilesUseCase.createSeatProfile(
          department: department,
          title: resolvedName,
          paygradeUnit: paygradeUnit.apiValue,
        );
        _hasUnlockedDescriptionActions = true;
        _seatContentGenerationErrorMessage = null;
        _selectedSpecificity = SeatContentSpecificity.medium;
        _selectedTone = SeatContentTone.professional;
      }
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void unlockDescriptionActions() {
    if (!hasCreatedProfile || _hasUnlockedDescriptionActions) {
      return;
    }

    _hasUnlockedDescriptionActions = true;
    notifyListeners();
  }

  void selectSpecificity(SeatContentSpecificity value) {
    if (_selectedSpecificity == value) {
      return;
    }

    _selectedSpecificity = value;
    _seatContentGenerationErrorMessage = null;
    notifyListeners();
  }

  void selectTone(SeatContentTone value) {
    if (_selectedTone == value) {
      return;
    }

    _selectedTone = value;
    _seatContentGenerationErrorMessage = null;
    notifyListeners();
  }

  void clearSeatContentGenerationError() {
    if (_seatContentGenerationErrorMessage == null) {
      return;
    }

    _seatContentGenerationErrorMessage = null;
    notifyListeners();
  }

  Future<bool> generateSeatContentWithAi() async {
    if (!canUseDescriptionActions) {
      return false;
    }

    final jobContentId = _actionTargetId;
    if (jobContentId.isEmpty) {
      return false;
    }

    _isGeneratingSeatContent = true;
    _seatContentGenerationErrorMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      await _getSeatProfilesUseCase.generateSeatProfileJobContent(
        actualId: jobContentId,
        specificity: _selectedSpecificity.apiValue,
        tone: _selectedTone.apiValue,
      );
      final generatedProfile = await _getSeatProfilesUseCase
          .getSeatProfileJobContent(jobContentId);
      if (hasCreatedProfile) {
        _createdProfile = generatedProfile;
      } else if (isEditMode) {
        _didUpdateProfile = true;
      }
      return true;
    } catch (error) {
      _seatContentGenerationErrorMessage = error.toString();
      return false;
    } finally {
      _isGeneratingSeatContent = false;
      notifyListeners();
    }
  }

  Future<List<SeatProfileCategoryDraft>> loadSeatCategoryDrafts() async {
    final jobContentId = _actionTargetId;
    if (jobContentId.isEmpty) {
      return const <SeatProfileCategoryDraft>[];
    }

    final result = await _getSeatProfilesUseCase.getSeatProfileJobContent(
      jobContentId,
    );
    if (hasCreatedProfile) {
      _createdProfile = result;
      notifyListeners();
    }

    return result.categories;
  }

  Future<void> saveSeatCategoryDrafts(
    List<SeatProfileCategoryDraft> categories,
  ) async {
    final jobContentId = _actionTargetId;
    if (jobContentId.isEmpty) {
      throw StateError(AppStrings.loginSomethingWentWrong);
    }

    await _getSeatProfilesUseCase.bulkUpsertSeatProfileCategories(
      actualId: jobContentId,
      categories: categories,
    );
    final refreshed = await _getSeatProfilesUseCase.getSeatProfileJobContent(
      jobContentId,
    );
    if (hasCreatedProfile) {
      _createdProfile = refreshed;
    } else {
      _didUpdateProfile = true;
    }
    notifyListeners();
  }

  void _handleNameChanged() {
    if (isFormLocked) {
      return;
    }

    notifyListeners();
  }

  List<Department> _mergeInitialDepartmentIfNeeded(
    List<Department> departments,
  ) {
    final initialDepartment = _initialData?.department;
    if (initialDepartment == null) {
      return departments;
    }

    final hasMatch = departments.any(
      (department) => department.id == initialDepartment.id,
    );
    if (hasMatch) {
      return departments;
    }

    return <Department>[initialDepartment, ...departments];
  }

  void _applyInitialSelections() {
    final initialData = _initialData;
    if (initialData == null) {
      return;
    }

    final initialDepartment = initialData.department;
    if (initialDepartment != null) {
      for (final department in _departments) {
        if (department.id == initialDepartment.id) {
          _selectedDepartment = department;
          break;
        }
      }

      _selectedDepartment ??= initialDepartment;
    }
  }

  String get _actionTargetId {
    final createdProfile = _createdProfile;
    if (createdProfile != null) {
      return createdProfile.jobContentId;
    }

    return _initialData?.updateTargetId ?? '';
  }

  @override
  void dispose() {
    nameController
      ..removeListener(_handleNameChanged)
      ..dispose();
    super.dispose();
  }
}

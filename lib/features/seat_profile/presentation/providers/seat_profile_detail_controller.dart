import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../data/datasources/seat_profile_remote_data_source.dart';
import '../../data/repositories/seat_profile_repository_impl.dart';
import '../../domain/entities/seat_profile_category_draft.dart';
import '../../domain/entities/seat_profile_detail.dart';
import '../../domain/usecases/get_seat_profiles_usecase.dart';

enum SeatProfileDetailContentSpecificity {
  low('low'),
  medium('medium'),
  high('high');

  const SeatProfileDetailContentSpecificity(this.apiValue);

  final String apiValue;

  String get label {
    return switch (this) {
      SeatProfileDetailContentSpecificity.low => AppStrings.seatProfileAiLow,
      SeatProfileDetailContentSpecificity.medium =>
        AppStrings.seatProfileAiMedium,
      SeatProfileDetailContentSpecificity.high => AppStrings.seatProfileAiHigh,
    };
  }
}

enum SeatProfileDetailContentTone {
  layman('layman'),
  professional('professional'),
  technical('technical');

  const SeatProfileDetailContentTone(this.apiValue);

  final String apiValue;

  String get label {
    return switch (this) {
      SeatProfileDetailContentTone.layman => AppStrings.seatProfileAiLayman,
      SeatProfileDetailContentTone.professional =>
        AppStrings.seatProfileAiProfessional,
      SeatProfileDetailContentTone.technical =>
        AppStrings.seatProfileAiTechnical,
    };
  }
}

class SeatProfileDetailController extends ChangeNotifier {
  SeatProfileDetailController(this._getSeatProfilesUseCase);

  final GetSeatProfilesUseCase _getSeatProfilesUseCase;

  bool _isLoading = false;
  bool _isGeneratingSeatContent = false;
  String? _errorMessage;
  SeatProfileDetail? _detail;
  String _seatId = '';
  String? _seatContentGenerationErrorMessage;
  final Set<String> _expandedCategoryIds = <String>{};
  final Set<String> _deletingDescriptionIds = <String>{};
  SeatProfileDetailContentSpecificity _selectedSpecificity =
      SeatProfileDetailContentSpecificity.medium;
  SeatProfileDetailContentTone _selectedTone =
      SeatProfileDetailContentTone.professional;

  bool get isLoading => _isLoading;
  bool get isGeneratingSeatContent => _isGeneratingSeatContent;
  String? get errorMessage => _errorMessage;
  SeatProfileDetail? get detail => _detail;
  String? get seatContentGenerationErrorMessage =>
      _seatContentGenerationErrorMessage;
  SeatProfileDetailContentSpecificity get selectedSpecificity =>
      _selectedSpecificity;
  SeatProfileDetailContentTone get selectedTone => _selectedTone;
  bool get canGenerateSeatContent =>
      _actionTargetId.isNotEmpty && !_isGeneratingSeatContent;
  List<SeatProfileCategoryDraft> get categoryDrafts {
    final categories = _detail?.categories ?? const <SeatProfileCategory>[];
    return List<SeatProfileCategoryDraft>.unmodifiable(
      categories.map(
        (category) => SeatProfileCategoryDraft(
          uuid: category.id,
          title: category.title,
          weightPercent: category.weightPercent,
        ),
      ),
    );
  }

  Future<void> initialize(String seatId) async {
    if (_isLoading) {
      return;
    }

    _seatId = seatId;
    await _loadDetail(seatId, showBlockingLoader: true);
  }

  Future<void> refresh() async {
    final resolvedSeatId = _seatId.trim();
    if (resolvedSeatId.isEmpty) {
      return;
    }

    await _loadDetail(resolvedSeatId, showBlockingLoader: false);
  }

  Future<void> saveSeatCategoryDrafts(
    List<SeatProfileCategoryDraft> categories,
  ) async {
    final detail = _detail;
    if (detail == null) {
      throw StateError(AppStrings.loginSomethingWentWrong);
    }

    final resolvedSeatId = _actionTargetId;
    if (resolvedSeatId.isEmpty) {
      throw StateError(AppStrings.loginSomethingWentWrong);
    }

    await _getSeatProfilesUseCase.bulkUpsertSeatProfileCategories(
      actualId: resolvedSeatId,
      categories: categories,
    );
    await _getSeatProfilesUseCase.getSeatProfileJobContent(resolvedSeatId);
  }

  Future<void> addSeatDescription({
    required String categoryId,
    required String descriptionName,
    required String auditSpecifics,
    required String auditFactorType,
    String? milestoneDays,
  }) async {
    final resolvedSeatId = _actionTargetId;
    if (resolvedSeatId.isEmpty || categoryId.trim().isEmpty) {
      throw StateError(AppStrings.loginSomethingWentWrong);
    }

    await _getSeatProfilesUseCase.createSeatProfileDescription(
      actualId: resolvedSeatId,
      categoryId: categoryId.trim(),
      descriptionName: descriptionName.trim(),
      auditSpecifics: auditSpecifics.trim(),
      auditFactorType: auditFactorType.trim(),
      milestoneDays: milestoneDays?.trim(),
    );
    await refresh();
  }

  Future<void> updateSeatDescription({
    required SeatProfileDescription description,
    required String descriptionName,
    required String auditSpecifics,
    required String auditFactorType,
    String? milestoneDays,
  }) async {
    final resolvedDescriptionId = description.resolvedDescriptionId;
    if (resolvedDescriptionId.isEmpty) {
      throw StateError(AppStrings.loginSomethingWentWrong);
    }

    await _getSeatProfilesUseCase.updateSeatProfileDescription(
      descriptionId: resolvedDescriptionId,
      descriptionName: descriptionName.trim(),
      auditSpecifics: auditSpecifics.trim(),
      auditFactorType: auditFactorType.trim(),
      milestoneDays: milestoneDays?.trim(),
    );
    await refresh();
  }

  bool isDeletingDescription(SeatProfileDescription description) {
    final resolvedDescriptionId = description.resolvedDescriptionId;
    if (resolvedDescriptionId.isEmpty) {
      return false;
    }

    return _deletingDescriptionIds.contains(resolvedDescriptionId);
  }

  Future<bool> deleteSeatDescription(SeatProfileDescription description) async {
    final resolvedDescriptionId = description.resolvedDescriptionId;
    if (resolvedDescriptionId.isEmpty) {
      throw StateError(AppStrings.loginSomethingWentWrong);
    }

    if (_deletingDescriptionIds.contains(resolvedDescriptionId)) {
      return false;
    }

    _deletingDescriptionIds.add(resolvedDescriptionId);
    notifyListeners();

    try {
      await _getSeatProfilesUseCase.deleteSeatProfileDescription(
        descriptionId: resolvedDescriptionId,
      );
      await refresh();
      return true;
    } finally {
      _deletingDescriptionIds.remove(resolvedDescriptionId);
      notifyListeners();
    }
  }

  bool isCategoryExpanded(String categoryId) {
    return _expandedCategoryIds.contains(categoryId.trim());
  }

  void setCategoryExpanded(String categoryId, bool isExpanded) {
    final resolvedCategoryId = categoryId.trim();
    if (resolvedCategoryId.isEmpty) {
      return;
    }

    final didChange = isExpanded
        ? _expandedCategoryIds.add(resolvedCategoryId)
        : _expandedCategoryIds.remove(resolvedCategoryId);
    if (!didChange) {
      return;
    }

    notifyListeners();
  }

  void selectSpecificity(SeatProfileDetailContentSpecificity value) {
    if (_selectedSpecificity == value) {
      return;
    }

    _selectedSpecificity = value;
    _seatContentGenerationErrorMessage = null;
    notifyListeners();
  }

  void selectTone(SeatProfileDetailContentTone value) {
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
    final detail = _detail;
    if (_isGeneratingSeatContent || detail == null) {
      return false;
    }

    final resolvedSeatId = _actionTargetId;
    if (resolvedSeatId.isEmpty) {
      return false;
    }

    _isGeneratingSeatContent = true;
    _seatContentGenerationErrorMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      await _getSeatProfilesUseCase.generateSeatProfileJobContent(
        actualId: resolvedSeatId,
        specificity: _selectedSpecificity.apiValue,
        tone: _selectedTone.apiValue,
      );
      await refresh();
      return true;
    } catch (error) {
      _seatContentGenerationErrorMessage = error.toString();
      return false;
    } finally {
      _isGeneratingSeatContent = false;
      notifyListeners();
    }
  }

  String get _actionTargetId {
    final resolvedDetailId = _detail?.resolvedSeatId.trim() ?? '';
    if (resolvedDetailId.isNotEmpty) {
      return resolvedDetailId;
    }

    return _seatId.trim();
  }

  Future<void> _loadDetail(
    String seatId, {
    required bool showBlockingLoader,
  }) async {
    final shouldShowBlockingLoader = showBlockingLoader || _detail == null;
    if (shouldShowBlockingLoader) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final loadedDetail = await _getSeatProfilesUseCase.getSeatProfileDetail(
        seatId,
      );
      _detail = _normalizeDetail(loadedDetail, fallbackSeatId: seatId);
      _syncExpandedCategories();
      _errorMessage = null;
    } catch (error) {
      if (_detail == null || shouldShowBlockingLoader) {
        _errorMessage = error.toString();
      }
    } finally {
      if (shouldShowBlockingLoader) {
        _isLoading = false;
      }

      notifyListeners();
    }
  }

  void _syncExpandedCategories() {
    final availableCategoryIds =
        (_detail?.categories ?? const <SeatProfileCategory>[])
            .map((category) => category.id.trim())
            .where((categoryId) => categoryId.isNotEmpty)
            .toSet();
    _expandedCategoryIds.removeWhere(
      (categoryId) => !availableCategoryIds.contains(categoryId),
    );
  }

  SeatProfileDetail _normalizeDetail(
    SeatProfileDetail detail, {
    required String fallbackSeatId,
  }) {
    final resolvedFallbackSeatId = fallbackSeatId.trim();
    final hasId = detail.id.trim().isNotEmpty;
    final hasActualId = detail.actualId.trim().isNotEmpty;

    if (hasId && hasActualId) {
      return detail;
    }

    if (resolvedFallbackSeatId.isEmpty) {
      return detail;
    }

    return SeatProfileDetail(
      id: hasId ? detail.id : resolvedFallbackSeatId,
      actualId: hasActualId ? detail.actualId : resolvedFallbackSeatId,
      title: detail.title,
      department: detail.department,
      paygradeUnit: detail.paygradeUnit,
      categories: detail.categories,
    );
  }
}

SeatProfileRepositoryImpl createSeatProfileDetailRepository(
  SeatProfileRemoteDataSource remoteDataSource,
) {
  return SeatProfileRepositoryImpl(remoteDataSource);
}

GetSeatProfilesUseCase createGetSeatProfileDetailUseCase(
  SeatProfileRepositoryImpl repository,
) {
  return GetSeatProfilesUseCase(repository);
}

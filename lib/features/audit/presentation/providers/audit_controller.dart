import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/preference/app_preference.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../data/datasources/audit_remote_data_source.dart';
import '../../data/repositories/audit_repository_impl.dart';
import '../../domain/entities/audit_description_audit.dart';
import '../../domain/entities/audit_list.dart';
import '../../domain/entities/audit_main_list.dart';
import '../../domain/entities/audit_member.dart';
import '../../domain/entities/audit_member_status.dart';
import '../../domain/entities/audit_profile.dart';
import '../../domain/entities/performance_report.dart';
import '../../domain/entities/quarterly_audit.dart';
import '../../domain/entities/seat_description_audit_report_comments.dart';
import '../../domain/entities/seat_description_final_audit_report.dart';
import '../../domain/entities/single_audit_report_category_details.dart';
import '../../domain/repositories/audit_repository.dart';
import '../../domain/usecases/get_audit_details_usecase.dart';
import '../../domain/usecases/get_audit_evaluation_chart_usecase.dart';
import '../../domain/usecases/get_audit_overview_usecase.dart';
import '../../domain/usecases/get_audit_team_members_usecase.dart';
import '../../domain/usecases/get_quarterly_audit_usecase.dart';
import '../../domain/usecases/mark_favorite_subordinate_usecase.dart';
import '../../domain/usecases/mark_unfavorite_subordinate_usecase.dart';
import '../../../login/domain/entities/user.dart';
import 'audit_state.dart';

class AuditController extends ChangeNotifier {
  static const Duration _certifiedReportPdfUrlCacheTtl = Duration(minutes: 10);

  AuditController(
    this._getAuditOverviewUseCase, [
    this._getAuditDetailsUseCase,
    this._getAuditEvaluationChartUseCase,
    this._getQuarterlyAuditUseCase,
    this._getAuditTeamMembersUseCase,
    this._markFavoriteSubordinateUseCase,
    this._markUnfavoriteSubordinateUseCase,
    this._auditRepository,
  ]);

  var showGraph = false;

  final GetAuditOverviewUseCase _getAuditOverviewUseCase;
  final GetAuditDetailsUseCase? _getAuditDetailsUseCase;
  final GetAuditEvaluationChartUseCase? _getAuditEvaluationChartUseCase;
  final GetQuarterlyAuditUseCase? _getQuarterlyAuditUseCase;
  final GetAuditTeamMembersUseCase? _getAuditTeamMembersUseCase;
  final MarkFavoriteSubordinateUseCase? _markFavoriteSubordinateUseCase;
  final MarkUnfavoriteSubordinateUseCase? _markUnfavoriteSubordinateUseCase;
  final AuditRepository? _auditRepository;
  AuditState _state = const AuditState();
  AuditMainList? _activeMainListCache;
  AuditMainList? _myCheckInMainListCache;
  final Map<String, _CachedCertifiedReportPdfUrl> _certifiedReportPdfUrlCache =
      <String, _CachedCertifiedReportPdfUrl>{};

  AuditState get state => _state;

  int get selectedAuditYear =>
      _state.selectedAuditYear ?? CustomFunctions.currentYearQuarter().year;

  int get selectedAuditQuarter =>
      _state.selectedAuditQuarter ??
      CustomFunctions.currentYearQuarter().quarter;

  String get selectedAuditYearQuarterLabel =>
      '$selectedAuditYear - Q$selectedAuditQuarter';

  List<int> get auditYearOptions {
    final currentYear = CustomFunctions.currentYearQuarter().year;
    return <int>[currentYear - 1, currentYear, currentYear + 1];
  }

  List<int> get auditQuarterOptions => const <int>[1, 2, 3, 4];

  bool isFavoriteUpdating(String profileJobId) {
    return _state.favoriteUpdatingProfileJobs.contains(profileJobId);
  }

  List<AuditMember> get visibleMembers {
    final members = _state.mainList?.results ?? const <AuditProfile>[];
    final query = _state.searchQuery.trim().toLowerCase();

    return members
        .where((member) {
          final matchesStatus =
              _state.isOwner ||
                  _state.selectedStatus == AuditMemberStatus.active
              ? member.status == _state.selectedStatus
              : true;
          final matchesQuery =
              query.isEmpty ||
              member.name.toLowerCase().contains(query) ||
              member.roleTitle.toLowerCase().contains(query);
          final matchesSeatProfile =
              _state.selectedSeatProfile == null ||
              member.seatProfile == _state.selectedSeatProfile;
          return matchesStatus && matchesQuery && matchesSeatProfile;
        })
        .toList(growable: false);
  }

  List<String> get yearQuarterOptions {
    final years = [...auditYearOptions]
      ..sort((left, right) => right.compareTo(left));
    return years
        .expand(
          (year) => List<String>.generate(
            4,
            (index) => '$year - Q${4 - index}',
            growable: false,
          ),
        )
        .toList(growable: false);
  }

  List<String> get seatProfileOptions {
    final members = _state.mainList?.results ?? const <AuditProfile>[];
    final uniqueOptions = members
        .map((member) => member.seatProfile)
        .toSet()
        .toList(growable: false);
    uniqueOptions.sort();
    return uniqueOptions;
  }

  List<AuditMember> get teamMemberOptions {
    final members = _state.mainList?.results ?? const <AuditProfile>[];
    final uniqueOptions = members
        .map((member) => member)
        .toSet()
        .toList(growable: false);
    return uniqueOptions;
  }

  Future<void> initialize() async {
    final user = await AppPreference.getUser();
    final isOwner = _hasTeamMemberTabsAccess(user);
    final selectedStatus = isOwner
        ? AuditMemberStatus.active
        : AuditMemberStatus.deactivated;
    final currentYearQuarter = CustomFunctions.currentYearQuarter();

    _activeMainListCache = null;
    _myCheckInMainListCache = null;

    _state = _state.copyWith(
      isLoading: true,
      isOwner: isOwner,
      selectedStatus: selectedStatus,
      selectedAuditYear: currentYearQuarter.year,
      selectedAuditQuarter: currentYearQuarter.quarter,
      isLoadingMore: false,
      clearMainList: true,
      clearSelectedYearQuarter: true,
    );
    notifyListeners();

    final mainList = isOwner
        ? await _loadTeamMembers(page: 1, pageSize: 12)
        : await _preloadNonOwnerLists(page: 1, pageSize: 12);
    _state = _state.copyWith(isLoading: false, mainList: mainList);
    notifyListeners();
  }

  Future<void> loadNextPage() async {
    final currentList = _state.mainList;
    if (_state.isLoading ||
        _state.isLoadingMore ||
        currentList == null ||
        currentList.next == null) {
      return;
    }

    _state = _state.copyWith(isLoadingMore: true);
    notifyListeners();

    final nextPage = currentList.current + 1;
    final nextList = await _loadListForSelectedStatus(
      page: nextPage,
      pageSize: 12,
    );
    final mergedList = AuditMainList(
      count: nextList.count,
      next: nextList.next,
      previous: nextList.previous,
      current: nextList.current,
      results: [...currentList.results, ...nextList.results],
    );

    _cacheList(_state.selectedStatus, mergedList);

    _state = _state.copyWith(isLoadingMore: false, mainList: mergedList);
    notifyListeners();
  }

  Future<void> initializeDetails(
    String profileJobId, {
    int? year,
    int? quarter,
    bool clearEvaluationCharts = true,
  }) async {
    final user = await AppPreference.getUser();
    final isOwner = _hasTeamMemberTabsAccess(user);
    final currentYearQuarter = CustomFunctions.currentYearQuarter();
    final resolvedYear = year ?? currentYearQuarter.year;
    final resolvedQuarter = quarter ?? currentYearQuarter.quarter;
    final selectedYearQuarterLabel =
        resolvedYear == currentYearQuarter.year &&
            resolvedQuarter == currentYearQuarter.quarter
        ? null
        : '$resolvedYear - Q$resolvedQuarter';

    _state = _state.copyWith(
      isLoading: true,
      isOwner: isOwner,
      selectedAuditYear: resolvedYear,
      selectedAuditQuarter: resolvedQuarter,
      selectedYearQuarter: selectedYearQuarterLabel,
      clearSelectedYearQuarter: selectedYearQuarterLabel == null,
      clearDetails: true,
      clearEvaluationCharts: clearEvaluationCharts,
    );
    notifyListeners();

    final getAuditDetailsUseCase = _getAuditDetailsUseCase;
    if (profileJobId.trim().isEmpty || getAuditDetailsUseCase == null) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return;
    }

    final details = await getAuditDetailsUseCase(
      profileJobId: profileJobId,
      year: resolvedYear,
      quarter: resolvedQuarter,
    );
    _state = _state.copyWith(isLoading: false, details: details);
    notifyListeners();
  }

  Future<void> showEvaluationChart(String profileJobId) async {
    showGraph = true;
    if (_state.evaluationCharts.isNotEmpty ||
        _state.isEvaluationChartLoading ||
        profileJobId.trim().isEmpty ||
        _getAuditEvaluationChartUseCase == null) {
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isEvaluationChartLoading: true);
    notifyListeners();

    final evaluationCharts = await _getAuditEvaluationChartUseCase(
      profileJobId: profileJobId,
    );
    _state = _state.copyWith(
      evaluationCharts: evaluationCharts,
      isEvaluationChartLoading: false,
    );
    notifyListeners();
  }

  Future<void> refreshEvaluationChart(String profileJobId) async {
    if (_state.isEvaluationChartLoading ||
        profileJobId.trim().isEmpty ||
        _getAuditEvaluationChartUseCase == null) {
      return;
    }

    _state = _state.copyWith(isEvaluationChartLoading: true);
    notifyListeners();

    final evaluationCharts = await _getAuditEvaluationChartUseCase(
      profileJobId: profileJobId,
    );
    _state = _state.copyWith(
      evaluationCharts: evaluationCharts,
      isEvaluationChartLoading: false,
    );
    notifyListeners();
  }

  Future<void> initializeQuarterlyAudit({
    required String quarterlyAuditId,
    required String date,
  }) async {
    _state = _state.copyWith(isLoading: true, clearQuarterlyAudit: true);
    notifyListeners();

    final getQuarterlyAuditUseCase = _getQuarterlyAuditUseCase;
    if (quarterlyAuditId.trim().isEmpty ||
        date.trim().isEmpty ||
        getQuarterlyAuditUseCase == null) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return;
    }

    final quarterlyAudit = await getQuarterlyAuditUseCase(
      quarterlyAuditId: quarterlyAuditId,
      date: date,
    );
    _state = _state.copyWith(
      isLoading: false,
      quarterlyAudit: quarterlyAudit,
      selectedQuarterlyAuditDescriptionUuid: quarterlyAudit.descriptions.isEmpty
          ? null
          : quarterlyAudit.descriptions.first.uuid,
      clearSelectedQuarterlyAuditDescription:
          quarterlyAudit.descriptions.isEmpty,
    );
    notifyListeners();
  }

  Future<void> initializeSingleAuditDetails({
    required String quarterlyAuditId,
    required String date,
    int? year,
    int? quarter,
  }) async {
    final user = await AppPreference.getUser();
    final isOwner = _hasTeamMemberTabsAccess(user);
    final currentYearQuarter = CustomFunctions.currentYearQuarter();
    final resolvedYear = year ?? currentYearQuarter.year;
    final resolvedQuarter = quarter ?? currentYearQuarter.quarter;
    final selectedYearQuarterLabel =
        resolvedYear == currentYearQuarter.year &&
            resolvedQuarter == currentYearQuarter.quarter
        ? null
        : '$resolvedYear - Q$resolvedQuarter';

    _state = _state.copyWith(
      isLoading: true,
      isOwner: isOwner,
      selectedAuditYear: resolvedYear,
      selectedAuditQuarter: resolvedQuarter,
      selectedYearQuarter: selectedYearQuarterLabel,
      clearSelectedYearQuarter: selectedYearQuarterLabel == null,
      clearMainList: true,
      clearQuarterlyAudit: true,
    );
    notifyListeners();

    final getQuarterlyAuditUseCase = _getQuarterlyAuditUseCase;
    if (quarterlyAuditId.trim().isEmpty ||
        date.trim().isEmpty ||
        getQuarterlyAuditUseCase == null) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return;
    }

    final teamMembersFuture = _getAuditTeamMembersUseCase?.call(
      page: 1,
      pageSize: 10,
      year: resolvedYear,
      quarter: resolvedQuarter,
    );
    final quarterlyAudit = await getQuarterlyAuditUseCase(
      quarterlyAuditId: quarterlyAuditId,
      date: date,
    );
    final teamMembers = await teamMembersFuture;

    _state = _state.copyWith(
      isLoading: false,
      mainList: _sortedMainList(teamMembers),
      quarterlyAudit: quarterlyAudit,
      selectedQuarterlyAuditDescriptionUuid: quarterlyAudit.descriptions.isEmpty
          ? null
          : quarterlyAudit.descriptions.first.uuid,
      clearSelectedQuarterlyAuditDescription:
          quarterlyAudit.descriptions.isEmpty,
    );
    notifyListeners();
  }

  Future<void> refreshSingleAuditDetails({
    required String quarterlyAuditId,
    required String date,
  }) async {
    final getQuarterlyAuditUseCase = _getQuarterlyAuditUseCase;
    if (quarterlyAuditId.trim().isEmpty ||
        date.trim().isEmpty ||
        getQuarterlyAuditUseCase == null) {
      return;
    }

    final quarterlyAudit = await getQuarterlyAuditUseCase(
      quarterlyAuditId: quarterlyAuditId,
      date: date,
    );

    _state = _state.copyWith(
      quarterlyAudit: quarterlyAudit,
      selectedQuarterlyAuditDescriptionUuid: quarterlyAudit.descriptions.isEmpty
          ? null
          : quarterlyAudit.descriptions.first.uuid,
      clearSelectedQuarterlyAuditDescription:
          quarterlyAudit.descriptions.isEmpty,
    );
    notifyListeners();
  }

  Future<QuarterlyAudit?> loadQuarterlyAuditForDate({
    required String quarterlyAuditId,
    required String date,
  }) async {
    final getQuarterlyAuditUseCase = _getQuarterlyAuditUseCase;
    if (quarterlyAuditId.trim().isEmpty ||
        date.trim().isEmpty ||
        getQuarterlyAuditUseCase == null) {
      return null;
    }

    return getQuarterlyAuditUseCase(
      quarterlyAuditId: quarterlyAuditId,
      date: date,
    );
  }

  Future<AuditDescriptionAudit> loadAuditDescription({
    required String quarterlyAuditId,
    required String descriptionId,
    required String date,
  }) async {
    final auditRepository = _auditRepository;
    if (auditRepository == null) {
      throw StateError('AuditRepository is not configured.');
    }

    return auditRepository.getAuditDescriptionAudit(
      quarterlyAuditId: quarterlyAuditId,
      descriptionId: descriptionId,
      date: date,
    );
  }

  Future<AuditDescriptionAudit> submitAuditDescriptionSelection({
    required String descriptionId,
    required Map<String, int> audit,
  }) async {
    final auditRepository = _auditRepository;
    if (auditRepository == null) {
      throw StateError('AuditRepository is not configured.');
    }

    return auditRepository.submitDescriptionAudit(
      descriptionId: descriptionId,
      audit: audit,
    );
  }

  Future<List<AuditList>> loadAuditReport({
    required int quarter,
    required int year,
    required String profileJobId,
  }) async {
    final auditRepository = _auditRepository;
    if (auditRepository == null) {
      throw StateError('AuditRepository is not configured.');
    }

    return auditRepository.getAuditReport(
      quarter: quarter,
      year: year,
      profileJobId: profileJobId,
    );
  }

  Future<List<SingleAuditReportCategoryDetails>>
  loadAuditReportCategoryDetails({
    required String categoryId,
    required int quarter,
    required int year,
  }) async {
    final auditRepository = _auditRepository;
    if (auditRepository == null) {
      throw StateError('AuditRepository is not configured.');
    }

    return auditRepository.getAuditReportCategoryDetails(
      categoryId: categoryId,
      quarter: quarter,
      year: year,
    );
  }

  Future<SeatDescriptionFinalAuditReport> loadSeatDescriptionFinalAuditReport({
    required String flowFirstId,
    String? profileUuid,
    required String descriptionId,
    int? quarter,
    int? year,
    String? timeRange,
  }) async {
    final auditRepository = _auditRepository;
    if (auditRepository == null) {
      throw StateError('AuditRepository is not configured.');
    }

    return auditRepository.getSeatDescriptionFinalAuditReport(
      flowFirstId: flowFirstId,
      profileUuid: profileUuid,
      descriptionId: descriptionId,
      quarter: quarter,
      year: year,
      timeRange: timeRange,
    );
  }

  Future<SeatDescriptionAuditReportComments>
  loadSeatDescriptionAuditReportComments({
    required String flowFirstId,
    String? profileUuid,
    required String descriptionId,
    int? quarter,
    int? year,
    String? timeRange,
  }) async {
    final auditRepository = _auditRepository;
    if (auditRepository == null) {
      throw StateError('AuditRepository is not configured.');
    }

    return auditRepository.getSeatDescriptionAuditReportComments(
      flowFirstId: flowFirstId,
      profileUuid: profileUuid,
      descriptionId: descriptionId,
      quarter: quarter,
      year: year,
      timeRange: timeRange,
    );
  }

  Future<List<SeatDescriptionFinalAuditProfile>>
  loadSeatDescriptionAuditReportProfiles({
    required String flowFirstId,
    String? profileUuid,
    required String descriptionId,
    int? quarter,
    int? year,
    String? timeRange,
  }) async {
    final auditRepository = _auditRepository;
    if (auditRepository == null) {
      throw StateError('AuditRepository is not configured.');
    }

    return auditRepository.getSeatDescriptionAuditReportProfiles(
      flowFirstId: flowFirstId,
      profileUuid: profileUuid,
      descriptionId: descriptionId,
      quarter: quarter,
      year: year,
      timeRange: timeRange,
    );
  }

  Future<void> createAuditDescriptionComment({
    required String descriptionId,
    required String comment,
  }) async {
    final auditRepository = _auditRepository;
    if (auditRepository == null) {
      throw StateError('AuditRepository is not configured.');
    }

    await auditRepository.createAuditDescriptionComment(
      descriptionId: descriptionId,
      comment: comment,
    );
  }

  Future<void> createAuditDescriptionMediaComment({
    required String descriptionId,
    required String comment,
    File? mediaFile,
    String? mediaType,
  }) async {
    final auditRepository = _auditRepository;
    if (auditRepository == null) {
      throw StateError('AuditRepository is not configured.');
    }

    String? mediaUrl;
    if (mediaFile != null) {
      final fileName = CustomFunctions.fileNameFromPath(mediaFile.path);
      final uploadUrl = await auditRepository
          .generateAuditDescriptionMediaUploadUrl(fileName: fileName);

      await auditRepository.uploadAuditDescriptionMediaFile(
        uploadUrl: uploadUrl,
        fileName: fileName,
        fileBytes: await mediaFile.readAsBytes(),
        contentType: CustomFunctions.contentTypeFromPath(mediaFile.path),
      );

      final querySeparatorIndex = uploadUrl.indexOf('?');
      mediaUrl = querySeparatorIndex == -1
          ? uploadUrl
          : uploadUrl.substring(0, querySeparatorIndex);
    }

    await auditRepository.createAuditDescriptionMedia(
      descriptionId: descriptionId,
      comment: comment,
      mediaUrl: mediaUrl,
      mediaType: mediaUrl == null ? null : mediaType,
    );
  }

  Future<List<AuditProfile>> toggleFavoriteSubordinate({
    required String profileJobId,
    required bool isFavorite,
  }) async {
    final markFavoriteSubordinateUseCase = _markFavoriteSubordinateUseCase;
    final markUnfavoriteSubordinateUseCase = _markUnfavoriteSubordinateUseCase;
    final getAuditTeamMembersUseCase = _getAuditTeamMembersUseCase;
    if (profileJobId.trim().isEmpty ||
        getAuditTeamMembersUseCase == null ||
        (isFavorite
            ? markUnfavoriteSubordinateUseCase == null
            : markFavoriteSubordinateUseCase == null)) {
      return _state.mainList?.results ?? const <AuditProfile>[];
    }

    if (isFavoriteUpdating(profileJobId)) {
      return _state.mainList?.results ?? const <AuditProfile>[];
    }

    _setFavoriteUpdating(profileJobId, true);
    try {
      if (isFavorite) {
        await markUnfavoriteSubordinateUseCase!(profileJobId: profileJobId);
      } else {
        await markFavoriteSubordinateUseCase!(profileJobId: profileJobId);
      }

      final refreshedMembers = await getAuditTeamMembersUseCase(
        page: 1,
        pageSize: _resolvedTeamMembersPageSize(),
        year: selectedAuditYear,
        quarter: selectedAuditQuarter,
      );
      final sortedMembers =
          _sortedMainList(refreshedMembers) ?? refreshedMembers;
      _state = _state.copyWith(mainList: sortedMembers);
      notifyListeners();
      return sortedMembers.results;
    } finally {
      _setFavoriteUpdating(profileJobId, false);
    }
  }

  void setShowGraph(bool value) {
    if (showGraph == value) {
      return;
    }

    showGraph = value;
    notifyListeners();
  }

  Future<void> selectStatus(AuditMemberStatus status) async {
    if (_state.selectedStatus == status) {
      return;
    }

    _state = _state.copyWith(
      selectedStatus: status,
      isLoading: !_state.isOwner,
      isLoadingMore: false,
      clearMainList: !_state.isOwner,
    );
    notifyListeners();

    if (_state.isOwner) {
      return;
    }

    final cachedList = _cachedListFor(status);
    if (cachedList != null) {
      _state = _state.copyWith(isLoading: false, mainList: cachedList);
      notifyListeners();
      return;
    }

    final mainList = await _loadListForSelectedStatus(page: 1, pageSize: 12);
    _cacheList(status, mainList);
    _state = _state.copyWith(isLoading: false, mainList: mainList);
    notifyListeners();
  }

  void selectQuarterlyAuditDescription(String descriptionUuid) {
    if (_state.selectedQuarterlyAuditDescriptionUuid == descriptionUuid) {
      return;
    }

    _state = _state.copyWith(
      selectedQuarterlyAuditDescriptionUuid: descriptionUuid,
    );
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    if (_state.searchQuery == query) {
      return;
    }

    _state = _state.copyWith(searchQuery: query);
    notifyListeners();
  }

  Future<void> selectAuditYear(int year) async {
    await _reloadAuditPeriod(year: year);
  }

  Future<void> selectAuditQuarter(int quarter) async {
    await _reloadAuditPeriod(quarter: quarter);
  }

  Future<void> applyFilters({String? yearQuarter, String? seatProfile}) async {
    final shouldClearSeatProfile = seatProfile == null || seatProfile.isEmpty;
    final resolvedSeatProfile = shouldClearSeatProfile ? null : seatProfile;
    final resolvedYearQuarter = (yearQuarter == null || yearQuarter.isEmpty)
        ? selectedAuditYearQuarterLabel
        : yearQuarter;
    final parsedYearQuarter = _parseYearQuarterLabel(resolvedYearQuarter);
    final currentYearQuarter = CustomFunctions.currentYearQuarter();
    final shouldClearYearQuarterChip =
        parsedYearQuarter == null ||
        (parsedYearQuarter.year == currentYearQuarter.year &&
            parsedYearQuarter.quarter == currentYearQuarter.quarter);
    final resolvedYearQuarterChip = shouldClearYearQuarterChip
        ? null
        : resolvedYearQuarter;
    final isPeriodChanged =
        parsedYearQuarter != null &&
        (parsedYearQuarter.year != selectedAuditYear ||
            parsedYearQuarter.quarter != selectedAuditQuarter);

    if (_state.selectedSeatProfile == resolvedSeatProfile &&
        _state.selectedYearQuarter == resolvedYearQuarterChip &&
        !isPeriodChanged) {
      return;
    }

    if (isPeriodChanged) {
      _activeMainListCache = null;
      _myCheckInMainListCache = null;

      _state = _state.copyWith(
        selectedSeatProfile: resolvedSeatProfile,
        clearSelectedSeatProfile: shouldClearSeatProfile,
        selectedYearQuarter: resolvedYearQuarterChip,
        clearSelectedYearQuarter: shouldClearYearQuarterChip,
        selectedAuditYear: parsedYearQuarter.year,
        selectedAuditQuarter: parsedYearQuarter.quarter,
        isLoading: true,
        isLoadingMore: false,
        clearMainList: true,
      );
      notifyListeners();

      final mainList = await _loadListForSelectedStatus(page: 1, pageSize: 12);
      _cacheList(_state.selectedStatus, mainList);
      _state = _state.copyWith(isLoading: false, mainList: mainList);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      selectedSeatProfile: resolvedSeatProfile,
      clearSelectedSeatProfile: shouldClearSeatProfile,
      selectedYearQuarter: resolvedYearQuarterChip,
      clearSelectedYearQuarter: shouldClearYearQuarterChip,
    );
    notifyListeners();
  }

  Future<void> clearYearQuarterFilter() async {
    final currentYearQuarter = CustomFunctions.currentYearQuarter();
    if (_state.selectedYearQuarter == null &&
        selectedAuditYear == currentYearQuarter.year &&
        selectedAuditQuarter == currentYearQuarter.quarter) {
      return;
    }

    _activeMainListCache = null;
    _myCheckInMainListCache = null;

    _state = _state.copyWith(
      selectedAuditYear: currentYearQuarter.year,
      selectedAuditQuarter: currentYearQuarter.quarter,
      isLoading: true,
      isLoadingMore: false,
      clearMainList: true,
      clearSelectedYearQuarter: true,
    );
    notifyListeners();

    final mainList = await _loadListForSelectedStatus(page: 1, pageSize: 12);
    _cacheList(_state.selectedStatus, mainList);
    _state = _state.copyWith(isLoading: false, mainList: mainList);
    notifyListeners();
  }

  void clearSeatProfileFilter() {
    if (_state.selectedSeatProfile == null) {
      return;
    }

    _state = _state.copyWith(clearSelectedSeatProfile: true);
    notifyListeners();
  }

  void setAuditActionLoading(bool value) {
    if (_state.isAuditActionLoading == value) {
      return;
    }

    _state = _state.copyWith(isAuditActionLoading: value);
    notifyListeners();
  }

  Future<void> initializePerformanceReport(AuditProfile profile) async {
    _state = _state.copyWith(
      isPerformanceReportLoading: true,
      clearPerformanceReport: true,
      performanceReportTimeRange: 'This Quarter',
      clearPerformanceReportStartDate: true,
      clearPerformanceReportEndDate: true,
      clearCertifiedReportOptions: true,
      clearSelectedCertifiedReportUuid: true,
      clearEmployeeSignatureBytes: true,
      clearEmployeeSignatureImageId: true,
      clearFacilitatorSignatureBytes: true,
      clearFacilitatorSignatureImageId: true,
      performanceReportCommitment: '',
    );
    notifyListeners();

    final auditRepository = _auditRepository;
    if (auditRepository == null) {
      _state = _state.copyWith(isPerformanceReportLoading: false);
      notifyListeners();
      return;
    }

    await _loadQuarterPerformanceReport(profile);
  }

  Future<void> selectPerformanceReportTimeRange(String timeRange) async {
    final currentReport = _state.performanceReport;
    if (currentReport == null ||
        _state.performanceReportTimeRange == timeRange) {
      return;
    }

    if (timeRange == 'This Quarter') {
      _state = _state.copyWith(
        isPerformanceReportLoading: true,
        performanceReportTimeRange: timeRange,
        clearPerformanceReportStartDate: true,
        clearPerformanceReportEndDate: true,
      );
      notifyListeners();

      await _loadQuarterPerformanceReport(currentReport.profile);
      return;
    }

    _state = _state.copyWith(
      performanceReportTimeRange: timeRange,
      clearPerformanceReportStartDate: true,
      clearPerformanceReportEndDate: true,
    );
    notifyListeners();
  }

  Future<void> applyPerformanceReportCustomDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final auditRepository = _auditRepository;
    final currentReport = _state.performanceReport;
    if (auditRepository == null || currentReport == null) {
      return;
    }

    _state = _state.copyWith(
      isPerformanceReportLoading: true,
      performanceReportTimeRange: 'Custom Date Range',
      performanceReportStartDate: startDate,
      performanceReportEndDate: endDate,
    );
    notifyListeners();

    late final PerformanceReport report;
    try {
      report = await auditRepository.getPerformanceReportOverview(
        profile: currentReport.profile,
        startDate: startDate,
        endDate: endDate,
      );
    } on ApiError catch (error) {
      if (!_shouldUseOpenSeatFallback(error)) {
        _state = _state.copyWith(isPerformanceReportLoading: false);
        notifyListeners();
        rethrow;
      }

      report = _buildOpenSeatPerformanceReport(currentReport.profile);
    }
    final certifiedReports = await _loadCertifiedReportsForPerformanceReport(
      auditRepository: auditRepository,
      profile: currentReport.profile,
      report: report,
      startDate: startDate,
      endDate: endDate,
    );

    _state = _state.copyWith(
      isPerformanceReportLoading: false,
      performanceReport: report,
      certifiedReportOptions: certifiedReports,
      clearSelectedCertifiedReportUuid: true,
    );
    notifyListeners();
  }

  Future<void> generatePerformanceReportRemarks() async {
    final auditRepository = _auditRepository;
    final currentReport = _state.performanceReport;
    if (auditRepository == null ||
        currentReport == null ||
        _state.isGeneratingPerformanceReportRemarks) {
      return;
    }

    _state = _state.copyWith(isGeneratingPerformanceReportRemarks: true);
    notifyListeners();

    try {
      final remarksByDescription =
          _state.performanceReportTimeRange == 'Custom Date Range' &&
              _state.performanceReportStartDate != null &&
              _state.performanceReportEndDate != null
          ? await auditRepository.getPerformanceReportRemarks(
              profile: currentReport.profile,
              startDate: _state.performanceReportStartDate,
              endDate: _state.performanceReportEndDate,
            )
          : await auditRepository.getPerformanceReportRemarks(
              profile: currentReport.profile,
              year: CustomFunctions.currentYearQuarter().year,
              quarter: CustomFunctions.currentYearQuarter().quarter,
            );

      _state = _state.copyWith(
        performanceReport: _applyRemarksToReport(
          currentReport,
          remarksByDescription,
        ),
        isGeneratingPerformanceReportRemarks: false,
      );
      notifyListeners();
    } catch (_) {
      _state = _state.copyWith(isGeneratingPerformanceReportRemarks: false);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _loadQuarterPerformanceReport(AuditProfile profile) async {
    final auditRepository = _auditRepository;
    if (auditRepository == null) {
      _state = _state.copyWith(isPerformanceReportLoading: false);
      notifyListeners();
      return;
    }

    final currentYearQuarter = CustomFunctions.currentYearQuarter();
    late final PerformanceReport report;
    try {
      report = await auditRepository.getPerformanceReportOverview(
        profile: profile,
        year: currentYearQuarter.year,
        quarter: currentYearQuarter.quarter,
      );
    } on ApiError catch (error) {
      if (!_shouldUseOpenSeatFallback(error)) {
        _state = _state.copyWith(isPerformanceReportLoading: false);
        notifyListeners();
        rethrow;
      }

      report = _buildOpenSeatPerformanceReport(profile);
    }
    final certifiedReports = await _loadCertifiedReportsForPerformanceReport(
      auditRepository: auditRepository,
      profile: profile,
      report: report,
      year: currentYearQuarter.year,
      quarter: currentYearQuarter.quarter,
    );

    _state = _state.copyWith(
      isPerformanceReportLoading: false,
      performanceReport: report,
      certifiedReportOptions: certifiedReports,
      clearSelectedCertifiedReportUuid: true,
    );
    notifyListeners();
  }

  Future<void> selectCertifiedReport(String? uuid) async {
    final currentReport = _state.performanceReport;
    final trimmed = uuid?.trim();
    if (currentReport == null) {
      return;
    }

    if ((trimmed == null || trimmed.isEmpty) &&
        _state.selectedCertifiedReportUuid != null) {
      _state = _state.copyWith(
        clearSelectedCertifiedReportUuid: true,
        isPerformanceReportLoading: true,
      );
      notifyListeners();

      if (_state.performanceReportTimeRange == 'Custom Date Range' &&
          _state.performanceReportStartDate != null &&
          _state.performanceReportEndDate != null) {
        await applyPerformanceReportCustomDateRange(
          startDate: _state.performanceReportStartDate!,
          endDate: _state.performanceReportEndDate!,
        );
        return;
      }

      await _loadQuarterPerformanceReport(currentReport.profile);
      return;
    }

    if (trimmed == null ||
        trimmed.isEmpty ||
        trimmed == _state.selectedCertifiedReportUuid) {
      return;
    }

    final auditRepository = _auditRepository;
    if (auditRepository == null) {
      return;
    }

    _state = _state.copyWith(
      selectedCertifiedReportUuid: trimmed,
      isPerformanceReportLoading: true,
    );
    notifyListeners();

    try {
      final detail = await auditRepository.getCertifiedReportDetail(
        certifiedReportUuid: trimmed,
        fallbackProfile: currentReport.profile,
      );
      _state = _state.copyWith(
        isPerformanceReportLoading: false,
        performanceReport: detail.report,
        performanceReportCommitment: detail.commitmentComment,
      );
    } catch (_) {
      _state = _state.copyWith(
        isPerformanceReportLoading: false,
        clearSelectedCertifiedReportUuid: true,
      );
      rethrow;
    }
    notifyListeners();
  }

  PerformanceReport _applyRemarksToReport(
    PerformanceReport report,
    Map<String, String> remarksByDescription,
  ) {
    List<PerformanceReportRatingRow> updateRows(
      List<PerformanceReportRatingRow> rows,
    ) {
      return rows
          .map(
            (row) => PerformanceReportRatingRow(
              descriptionUuid: row.descriptionUuid,
              title: row.title,
              passCount: row.passCount,
              partialCount: row.partialCount,
              failCount: row.failCount,
              ratingPercent: row.ratingPercent,
              remarks: remarksByDescription[row.descriptionUuid] ?? row.remarks,
            ),
          )
          .toList(growable: false);
    }

    final updatedTabs = report.categoryTabs
        .map(
          (tab) => PerformanceReportCategoryTab(
            label: tab.label,
            score: tab.score,
            rows: updateRows(tab.rows),
          ),
        )
        .toList(growable: false);
    final updatedRatingRows = updateRows(report.ratingRows);
    final updatedReportSnapshot = _applyRemarksToReportSnapshot(
      report.reportSnapshot,
      _collectRemarksByDescription(updatedTabs),
    );

    return PerformanceReport(
      profile: report.profile,
      createdAt: report.createdAt,
      personalityAvatarImagePath: report.personalityAvatarImagePath,
      hasPersonalityData: report.hasPersonalityData,
      isCertified: report.isCertified,
      certifiedAt: report.certifiedAt,
      employeeSignatureName: report.employeeSignatureName,
      selectedProfileSignatureUuid: report.selectedProfileSignatureUuid,
      selectedProfileSignatureUrl: report.selectedProfileSignatureUrl,
      facilitatorSignatureUrl: report.facilitatorSignatureUrl,
      facilitatorName: report.facilitatorName,
      reportSnapshot: updatedReportSnapshot,
      rawPersonalityDescription: report.rawPersonalityDescription,
      overallPerformanceScore: report.overallPerformanceScore,
      confidenceLevel: report.confidenceLevel,
      archetypeTitle: report.archetypeTitle,
      archetypeSubtitle: report.archetypeSubtitle,
      archetypeSummary: report.archetypeSummary,
      guidanceParagraphs: report.guidanceParagraphs,
      categoryTabs: updatedTabs,
      selectedCategoryIndex: report.selectedCategoryIndex,
      ratingRows: updatedRatingRows,
      paygradePipeline: report.paygradePipeline,
      currentPaygrade: report.currentPaygrade,
      paygradeUnit: report.paygradeUnit,
      remarkVersion: report.remarkVersion,
    );
  }

  Map<String, String> _collectRemarksByDescription(
    List<PerformanceReportCategoryTab> categoryTabs,
  ) {
    final remarksByDescription = <String, String>{};
    for (final tab in categoryTabs) {
      for (final row in tab.rows) {
        final descriptionUuid = row.descriptionUuid.trim();
        if (descriptionUuid.isEmpty) {
          continue;
        }

        final remarks = row.remarks?.trim();
        if (remarks == null) {
          continue;
        }

        remarksByDescription[descriptionUuid] = remarks;
      }
    }

    return remarksByDescription;
  }

  Map<String, dynamic> _applyRemarksToReportSnapshot(
    Map<String, dynamic> reportSnapshot,
    Map<String, String> remarksByDescription,
  ) {
    if (remarksByDescription.isEmpty) {
      return Map<String, dynamic>.from(reportSnapshot);
    }

    final updatedSnapshot = Map<String, dynamic>.from(reportSnapshot);
    final rawCategories = updatedSnapshot['categories'];
    if (rawCategories is! List) {
      return updatedSnapshot;
    }

    updatedSnapshot['categories'] = rawCategories
        .map((rawCategory) {
          if (rawCategory is! Map) {
            return rawCategory;
          }

          final category = Map<String, dynamic>.from(rawCategory);
          final rawDescriptions = category['descriptions'];
          if (rawDescriptions is! List) {
            return category;
          }

          category['descriptions'] = rawDescriptions
              .map((rawDescription) {
                if (rawDescription is! Map) {
                  return rawDescription;
                }

                final description = Map<String, dynamic>.from(rawDescription);
                final descriptionUuid =
                    description['uuid']?.toString().trim() ??
                    description['description_uuid']?.toString().trim() ??
                    '';
                if (descriptionUuid.isEmpty) {
                  return description;
                }

                if (!remarksByDescription.containsKey(descriptionUuid)) {
                  return description;
                }

                final remarks = remarksByDescription[descriptionUuid] ?? '';
                description.remove('remarks');
                description['remark'] = remarks;
                return description;
              })
              .toList(growable: false);

          return category;
        })
        .toList(growable: false);

    return updatedSnapshot;
  }

  void updatePerformanceReportCommitment(String value) {
    final trimmedValue = value.length > 2000 ? value.substring(0, 2000) : value;
    if (_state.performanceReportCommitment == trimmedValue) {
      return;
    }

    _state = _state.copyWith(performanceReportCommitment: trimmedValue);
    notifyListeners();
  }

  Future<String?> saveEmployeeSignature(Uint8List bytes) async {
    _state = _state.copyWith(
      employeeSignatureBytes: bytes,
      clearEmployeeSignatureImageId: true,
    );
    notifyListeners();

    final auditRepository = _auditRepository;
    if (auditRepository == null) {
      return null;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final signatureImageId = await auditRepository
          .uploadPerformanceReportSignatureImage(
            fileName: 'employee-signature-$timestamp.png',
            fileBytes: bytes,
            contentType: 'image/png',
          );

      _state = _state.copyWith(
        employeeSignatureBytes: bytes,
        employeeSignatureImageId: signatureImageId,
      );
      notifyListeners();
      return null;
    } catch (error) {
      debugPrint('Unable to upload employee signature: $error');
      return 'Unable to upload employee signature right now. Please try again.';
    }
  }

  Future<String?> saveFacilitatorSignature(Uint8List bytes) async {
    _state = _state.copyWith(
      facilitatorSignatureBytes: bytes,
      isFacilitatorSignatureUploading: true,
      clearFacilitatorSignatureImageId: true,
    );
    notifyListeners();

    final auditRepository = _auditRepository;
    if (auditRepository == null) {
      _state = _state.copyWith(isFacilitatorSignatureUploading: false);
      notifyListeners();
      return null;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final signatureImageId = await auditRepository
          .uploadPerformanceReportSignatureImage(
            fileName: 'facilitator-signature-$timestamp.png',
            fileBytes: bytes,
            contentType: 'image/png',
          );

      _state = _state.copyWith(
        facilitatorSignatureBytes: bytes,
        facilitatorSignatureImageId: signatureImageId,
        isFacilitatorSignatureUploading: false,
      );
      notifyListeners();
      return null;
    } catch (error) {
      debugPrint('Unable to upload facilitator signature: $error');
      _state = _state.copyWith(isFacilitatorSignatureUploading: false);
      notifyListeners();
      return 'Unable to upload facilitator signature right now. Please try again.';
    }
  }

  void clearEmployeeSignature() {
    if (_state.employeeSignatureBytes == null &&
        _state.employeeSignatureImageId == null) {
      return;
    }

    _state = _state.copyWith(
      clearEmployeeSignatureBytes: true,
      clearEmployeeSignatureImageId: true,
    );
    notifyListeners();
  }

  void clearFacilitatorSignature() {
    if (_state.facilitatorSignatureBytes == null &&
        _state.facilitatorSignatureImageId == null) {
      return;
    }

    _state = _state.copyWith(
      clearFacilitatorSignatureBytes: true,
      clearFacilitatorSignatureImageId: true,
      isFacilitatorSignatureUploading: false,
    );
    notifyListeners();
  }

  bool isCertifiedReportPdfDownloading(String certifiedReportUuid) {
    return _state.downloadingCertifiedReportUuids.contains(certifiedReportUuid);
  }

  Future<String> downloadCertifiedReportPdf(String certifiedReportUuid) async {
    final auditRepository = _auditRepository;
    final trimmed = certifiedReportUuid.trim();
    if (auditRepository == null || trimmed.isEmpty) {
      return '';
    }

    final cachedEntry = _certifiedReportPdfUrlCache[trimmed];
    if (cachedEntry != null && !cachedEntry.isExpired) {
      return cachedEntry.url;
    }

    if (_state.downloadingCertifiedReportUuids.contains(trimmed)) {
      return '';
    }

    final downloading = Set<String>.from(_state.downloadingCertifiedReportUuids)
      ..add(trimmed);
    _state = _state.copyWith(downloadingCertifiedReportUuids: downloading);
    notifyListeners();

    try {
      final pdfUrl = await auditRepository.getCertifiedReportPdfUrl(
        certifiedReportUuid: trimmed,
      );
      if (pdfUrl.trim().isNotEmpty) {
        _certifiedReportPdfUrlCache[trimmed] = _CachedCertifiedReportPdfUrl(
          url: pdfUrl,
          expiresAt: DateTime.now().add(_certifiedReportPdfUrlCacheTtl),
        );
      }
      return pdfUrl;
    } catch (error) {
      debugPrint('Unable to download certified report PDF: $error');
      return '';
    } finally {
      final updated = Set<String>.from(_state.downloadingCertifiedReportUuids)
        ..remove(trimmed);
      _state = _state.copyWith(downloadingCertifiedReportUuids: updated);
      notifyListeners();
    }
  }

  Future<String> certifyPerformanceReport() async {
    final currentReport = _state.performanceReport;
    if (currentReport == null) {
      return 'Performance report is not available right now.';
    }

    final hasEmployeeSignature =
        _state.employeeSignatureBytes != null ||
        (_state.employeeSignatureImageId?.trim().isNotEmpty ?? false) ||
        (currentReport.selectedProfileSignatureUuid?.trim().isNotEmpty ??
            false);
    final hasFacilitatorSignature = _state.facilitatorSignatureBytes != null;

    if (!hasEmployeeSignature || !hasFacilitatorSignature) {
      return 'Employee and Facilitator signatures are required before certifying.';
    }

    final employeeSignatureUuid =
        (_state.employeeSignatureImageId?.trim().isNotEmpty ?? false)
        ? _state.employeeSignatureImageId!.trim()
        : currentReport.selectedProfileSignatureUuid?.trim() ?? '';
    if (employeeSignatureUuid.isEmpty) {
      return 'Employee signature UUID is missing from the report data.';
    }

    if (_state.isFacilitatorSignatureUploading) {
      return 'Facilitator signature is still uploading. Please wait a moment.';
    }

    final facilitatorSignatureUuid =
        _state.facilitatorSignatureImageId?.trim() ?? '';
    if (facilitatorSignatureUuid.isEmpty) {
      return 'Facilitator signature upload is required before certifying.';
    }

    final auditRepository = _auditRepository;
    if (auditRepository == null) {
      return 'Unable to certify the performance report right now.';
    }

    final commitmentComment = _state.performanceReportCommitment.trim();

    _state = _state.copyWith(isAuditActionLoading: true);
    notifyListeners();

    try {
      final isCustomRange =
          _state.performanceReportTimeRange == 'Custom Date Range' &&
          _state.performanceReportStartDate != null &&
          _state.performanceReportEndDate != null;
      final currentYearQuarter = CustomFunctions.currentYearQuarter();
      final reportSnapshot = _applyRemarksToReportSnapshot(
        currentReport.reportSnapshot,
        _collectRemarksByDescription(currentReport.categoryTabs),
      );

      final payload = <String, dynamic>{
        'profile_uuid': currentReport.profile.profileUuid,
        'filter_type': isCustomRange ? 'custom_range' : 'quarter',
        'report_snapshot': {'overview': reportSnapshot},
        'commitment_comment': commitmentComment,
        'employee_signature_uuid': employeeSignatureUuid,
        'facilitator_signature_uuid': facilitatorSignatureUuid,
        if (isCustomRange) ...{
          'start': CustomFunctions.apiDateString(
            date: _state.performanceReportStartDate!,
          ),
          'end': CustomFunctions.apiDateString(
            date: _state.performanceReportEndDate!,
          ),
        } else ...{
          'quarter': currentYearQuarter.quarter.toString(),
          'year': currentYearQuarter.year,
        },
      };

      final certifiedReportUuid = await auditRepository
          .certifyPerformanceReport(
            profileJobId: currentReport.profile.profileJob,
            payload: payload,
          );
      final certifiedReports = await _loadCertifiedReportsForPerformanceReport(
        auditRepository: auditRepository,
        profile: currentReport.profile,
        report: currentReport,
        startDate: isCustomRange ? _state.performanceReportStartDate : null,
        endDate: isCustomRange ? _state.performanceReportEndDate : null,
        year: isCustomRange ? null : currentYearQuarter.year,
        quarter: isCustomRange ? null : currentYearQuarter.quarter,
      );

      if (certifiedReportUuid != null &&
          certifiedReportUuid.trim().isNotEmpty) {
        final detail = await auditRepository.getCertifiedReportDetail(
          certifiedReportUuid: certifiedReportUuid.trim(),
          fallbackProfile: currentReport.profile,
        );
        _state = _state.copyWith(
          performanceReport: detail.report,
          performanceReportCommitment: detail.commitmentComment,
          certifiedReportOptions: certifiedReports,
          selectedCertifiedReportUuid: certifiedReportUuid.trim(),
        );
      } else {
        final user = await AppPreference.getUser();
        _state = _state.copyWith(
          performanceReport: PerformanceReport(
            profile: currentReport.profile,
            createdAt: currentReport.createdAt,
            personalityAvatarImagePath:
                currentReport.personalityAvatarImagePath,
            hasPersonalityData: currentReport.hasPersonalityData,
            isCertified: true,
            certifiedAt: DateTime.now().millisecondsSinceEpoch.toString(),
            employeeSignatureName:
                currentReport.employeeSignatureName ??
                currentReport.profile.name,
            selectedProfileSignatureUuid:
                currentReport.selectedProfileSignatureUuid,
            selectedProfileSignatureUrl:
                currentReport.selectedProfileSignatureUrl,
            facilitatorSignatureUrl: currentReport.facilitatorSignatureUrl,
            facilitatorName: user?.name ?? currentReport.facilitatorName,
            reportSnapshot: reportSnapshot,
            rawPersonalityDescription: currentReport.rawPersonalityDescription,
            overallPerformanceScore: currentReport.overallPerformanceScore,
            confidenceLevel: currentReport.confidenceLevel,
            archetypeTitle: currentReport.archetypeTitle,
            archetypeSubtitle: currentReport.archetypeSubtitle,
            archetypeSummary: currentReport.archetypeSummary,
            guidanceParagraphs: currentReport.guidanceParagraphs,
            categoryTabs: currentReport.categoryTabs,
            selectedCategoryIndex: currentReport.selectedCategoryIndex,
            ratingRows: currentReport.ratingRows,
            paygradePipeline: currentReport.paygradePipeline,
            currentPaygrade: currentReport.currentPaygrade,
            paygradeUnit: currentReport.paygradeUnit,
            remarkVersion: currentReport.remarkVersion,
          ),
          certifiedReportOptions: certifiedReports,
        );
      }
      return 'Performance report certified successfully.';
    } catch (error) {
      debugPrint('Unable to certify performance report: $error');
      return 'Unable to certify performance report right now. Please try again.';
    } finally {
      _state = _state.copyWith(isAuditActionLoading: false);
      notifyListeners();
    }
  }

  void _setFavoriteUpdating(String profileJobId, bool isUpdating) {
    final updatedProfileJobs = Set<String>.from(
      _state.favoriteUpdatingProfileJobs,
    );
    if (isUpdating) {
      updatedProfileJobs.add(profileJobId);
    } else {
      updatedProfileJobs.remove(profileJobId);
    }

    _state = _state.copyWith(favoriteUpdatingProfileJobs: updatedProfileJobs);
    notifyListeners();
  }

  int _resolvedTeamMembersPageSize() {
    final currentCount = _state.mainList?.results.length ?? 0;
    return currentCount > 0 ? currentCount : 10;
  }

  Future<List<CertifiedReportOption>>
  _loadCertifiedReportsForPerformanceReport({
    required AuditRepository auditRepository,
    required AuditProfile profile,
    PerformanceReport? report,
    int? year,
    int? quarter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final trimmedProfileUuid = profile.profileUuid.trim();
    final isInvalidProfileUuid =
        trimmedProfileUuid.isEmpty ||
        trimmedProfileUuid.toLowerCase() == 'null';
    if (isInvalidProfileUuid ||
        (report != null && _isOpenSeatPerformanceReport(report))) {
      return const <CertifiedReportOption>[];
    }

    try {
      return await auditRepository.getCertifiedReports(
        profile: profile,
        year: year,
        quarter: quarter,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (error) {
      debugPrint(
        'Unable to load certified reports for performance report: $error',
      );
      return const <CertifiedReportOption>[];
    }
  }

  bool _isOpenSeatPerformanceReport(PerformanceReport report) {
    final selectedProfilePayload = report.reportSnapshot['selected_profile'];
    final hasSelectedProfile = selectedProfilePayload is Map<String, dynamic>
        ? selectedProfilePayload.isNotEmpty
        : selectedProfilePayload != null;

    return !hasSelectedProfile && report.profile.profiles.isEmpty;
  }

  bool _shouldUseOpenSeatFallback(ApiError error) {
    return error.message.trim().toLowerCase() == 'profile uuid is not valid.';
  }

  PerformanceReport _buildOpenSeatPerformanceReport(AuditProfile profile) {
    final openSeatProfile = AuditProfile(
      uuid: profile.uuid,
      profileJob: profile.profileJob,
      profileUuid: '',
      email: '',
      imageUrl: null,
      isFavorite: profile.isFavorite,
      lastAuditDates: profile.lastAuditDates,
      roleTitle: profile.roleTitle,
      name: 'No Profile',
      lastAuditLabel: profile.lastAuditLabel,
      yearQuarter: profile.yearQuarter,
      seatProfile: 'Open Seat',
      overallScore: profile.overallScore,
      confidenceLevel: profile.confidenceLevel,
      status: profile.status,
      reviewerInitials: profile.reviewerInitials,
      avatarLabel: 'N',
      profiles: const <AuditMemberProfile>[],
      avatarImageUrl: null,
    );

    return PerformanceReport(
      profile: openSeatProfile,
      personalityAvatarImagePath: null,
      hasPersonalityData: false,
      isCertified: false,
      certifiedAt: null,
      employeeSignatureName: null,
      selectedProfileSignatureUuid: null,
      selectedProfileSignatureUrl: null,
      facilitatorSignatureUrl: null,
      facilitatorName: null,
      reportSnapshot: const <String, dynamic>{
        'selected_profile': null,
        'profiles': <dynamic>[],
        'categories': <dynamic>[],
        'message': 'No profile is assigned to this seat yet.',
      },
      rawPersonalityDescription: '',
      overallPerformanceScore: profile.overallScore,
      confidenceLevel: profile.confidenceLevel.toDouble(),
      archetypeTitle: 'Performance Overview',
      archetypeSubtitle: profile.roleTitle,
      archetypeSummary: '',
      guidanceParagraphs: const <String>[],
      categoryTabs: const <PerformanceReportCategoryTab>[],
      selectedCategoryIndex: 0,
      ratingRows: const <PerformanceReportRatingRow>[],
      paygradePipeline: const <PerformanceReportPaygradeStep>[],
      currentPaygrade: '--',
      paygradeUnit: '--',
      remarkVersion: 0,
    );
  }

  Future<AuditMainList> _loadListForSelectedStatus({
    required int page,
    required int pageSize,
  }) {
    if (!_state.isOwner &&
        _state.selectedStatus == AuditMemberStatus.deactivated) {
      return _loadMyCheckIns(page: page, pageSize: pageSize);
    }

    return _loadTeamMembers(page: page, pageSize: pageSize);
  }

  Future<AuditMainList> _preloadNonOwnerLists({
    required int page,
    required int pageSize,
  }) async {
    final results = await Future.wait<AuditMainList>(<Future<AuditMainList>>[
      _loadTeamMembers(page: page, pageSize: pageSize),
      _loadMyCheckIns(page: page, pageSize: pageSize),
    ]);

    _activeMainListCache = results[0];
    _myCheckInMainListCache = results[1];

    return _state.selectedStatus == AuditMemberStatus.deactivated
        ? results[1]
        : results[0];
  }

  Future<AuditMainList> _loadTeamMembers({
    required int page,
    required int pageSize,
  }) {
    return _getAuditOverviewUseCase(
      page: page,
      pageSize: pageSize,
      year: selectedAuditYear,
      quarter: selectedAuditQuarter,
    );
  }

  Future<AuditMainList> _loadMyCheckIns({
    required int page,
    required int pageSize,
  }) {
    final auditRepository = _auditRepository;
    if (auditRepository == null) {
      return _loadTeamMembers(page: page, pageSize: pageSize);
    }

    return auditRepository.getMyAudits(
      page: page,
      pageSize: pageSize,
      year: selectedAuditYear,
      quarter: selectedAuditQuarter,
    );
  }

  Future<void> _reloadAuditPeriod({int? year, int? quarter}) async {
    final resolvedYear = year ?? selectedAuditYear;
    final resolvedQuarter = quarter ?? selectedAuditQuarter;
    if (resolvedYear == selectedAuditYear &&
        resolvedQuarter == selectedAuditQuarter) {
      return;
    }

    _activeMainListCache = null;
    _myCheckInMainListCache = null;

    _state = _state.copyWith(
      selectedAuditYear: resolvedYear,
      selectedAuditQuarter: resolvedQuarter,
      isLoading: true,
      isLoadingMore: false,
      clearMainList: true,
      clearSelectedYearQuarter: true,
    );
    notifyListeners();

    final mainList = await _loadListForSelectedStatus(page: 1, pageSize: 12);
    _cacheList(_state.selectedStatus, mainList);
    _state = _state.copyWith(isLoading: false, mainList: mainList);
    notifyListeners();
  }

  AuditMainList? _cachedListFor(AuditMemberStatus status) {
    return status == AuditMemberStatus.deactivated
        ? _myCheckInMainListCache
        : _activeMainListCache;
  }

  void _cacheList(AuditMemberStatus status, AuditMainList list) {
    if (status == AuditMemberStatus.deactivated) {
      _myCheckInMainListCache = list;
      return;
    }

    _activeMainListCache = list;
  }

  _ParsedYearQuarter? _parseYearQuarterLabel(String value) {
    final parts = value.split('-');
    if (parts.length < 2) {
      return null;
    }

    final year = int.tryParse(parts.first.trim());
    final quarter = int.tryParse(
      parts.last.trim().toUpperCase().replaceFirst('Q', ''),
    );
    if (year == null || quarter == null) {
      return null;
    }

    return _ParsedYearQuarter(year: year, quarter: quarter);
  }

  AuditMainList? _sortedMainList(AuditMainList? mainList) {
    if (mainList == null) {
      return null;
    }

    final sortedResults = [...mainList.results]
      ..sort((left, right) {
        if (left.isFavorite == right.isFavorite) {
          return left.name.toLowerCase().compareTo(right.name.toLowerCase());
        }
        return left.isFavorite ? -1 : 1;
      });

    return AuditMainList(
      count: mainList.count,
      next: mainList.next,
      previous: mainList.previous,
      current: mainList.current,
      results: sortedResults,
    );
  }

  bool _hasTeamMemberTabsAccess(User? user) {
    return user?.canAccessAuditTeamMembers ?? false;
  }
}

AuditRemoteDataSource createAuditRemoteDataSource() => AuditRemoteDataSource();

AuditRepositoryImpl createAuditRepository(
  AuditRemoteDataSource remoteDataSource,
) {
  return AuditRepositoryImpl(remoteDataSource);
}

GetAuditOverviewUseCase createGetAuditOverviewUseCase(
  AuditRepositoryImpl repository,
) {
  return GetAuditOverviewUseCase(repository);
}

GetAuditDetailsUseCase createGetAuditDetailsUseCase(
  AuditRepositoryImpl repository,
) {
  return GetAuditDetailsUseCase(repository);
}

GetAuditEvaluationChartUseCase createGetAuditEvaluationChartUseCase(
  AuditRepositoryImpl repository,
) {
  return GetAuditEvaluationChartUseCase(repository);
}

GetQuarterlyAuditUseCase createGetQuarterlyAuditUseCase(
  AuditRepositoryImpl repository,
) {
  return GetQuarterlyAuditUseCase(repository);
}

MarkFavoriteSubordinateUseCase createMarkFavoriteSubordinateUseCase(
  AuditRepositoryImpl repository,
) {
  return MarkFavoriteSubordinateUseCase(repository);
}

MarkUnfavoriteSubordinateUseCase createMarkUnfavoriteSubordinateUseCase(
  AuditRepositoryImpl repository,
) {
  return MarkUnfavoriteSubordinateUseCase(repository);
}

GetAuditTeamMembersUseCase createGetAuditTeamMembersUseCase(
  AuditRepositoryImpl repository,
) {
  return GetAuditTeamMembersUseCase(repository);
}

class _CachedCertifiedReportPdfUrl {
  const _CachedCertifiedReportPdfUrl({
    required this.url,
    required this.expiresAt,
  });

  final String url;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class _ParsedYearQuarter {
  const _ParsedYearQuarter({required this.year, required this.quarter});

  final int year;
  final int quarter;
}

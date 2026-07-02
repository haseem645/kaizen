import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:sparrowkaizen/core/constants/app_colors.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/core/utils/custom_functions.dart';
import 'package:sparrowkaizen/core/widgets/app_text_view.dart';
import 'package:sparrowkaizen/core/widgets/fast_circular_progress.dart';
import 'package:sparrowkaizen/features/audit/data/datasources/audit_remote_data_source.dart';
import 'package:sparrowkaizen/features/audit/data/repositories/audit_repository_impl.dart';
import 'package:sparrowkaizen/features/audit/domain/entities/audit_profile.dart';
import 'package:sparrowkaizen/features/audit/domain/entities/quarterly_audit.dart';
import 'package:sparrowkaizen/features/audit/domain/usecases/get_audit_overview_usecase.dart';
import 'package:sparrowkaizen/features/audit/domain/usecases/get_audit_team_members_usecase.dart';
import 'package:sparrowkaizen/features/audit/domain/usecases/get_quarterly_audit_usecase.dart';
import 'package:sparrowkaizen/features/audit/domain/usecases/mark_favorite_subordinate_usecase.dart';
import 'package:sparrowkaizen/features/audit/domain/usecases/mark_unfavorite_subordinate_usecase.dart';
import 'package:sparrowkaizen/features/audit/presentation/providers/audit_controller.dart';
import 'package:sparrowkaizen/routes/app_router.dart';

import 'View_all_team_members.dart';
import 'audit_single_description.dart';

class SingleAuditDetailsScreen extends StatelessWidget {
  const SingleAuditDetailsScreen({
    super.key,
    required this.quarterlyAuditId,
    required this.date,
    required this.lastAuditDate,
  });

  final String quarterlyAuditId;
  final String date;
  final String lastAuditDate;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuditRemoteDataSource>(create: (_) => createAuditRemoteDataSource()),
        ProxyProvider<AuditRemoteDataSource, AuditRepositoryImpl>(
          update: (_, remoteDataSource, __) => createAuditRepository(remoteDataSource),
        ),
        ProxyProvider<AuditRepositoryImpl, GetAuditOverviewUseCase>(
          update: (_, repository, __) => createGetAuditOverviewUseCase(repository),
        ),
        ProxyProvider<AuditRepositoryImpl, GetQuarterlyAuditUseCase>(
          update: (_, repository, __) => createGetQuarterlyAuditUseCase(repository),
        ),
        ProxyProvider<AuditRepositoryImpl, GetAuditTeamMembersUseCase>(
          update: (_, repository, __) => createGetAuditTeamMembersUseCase(repository),
        ),
        ProxyProvider<AuditRepositoryImpl, MarkFavoriteSubordinateUseCase>(
          update: (_, repository, __) => createMarkFavoriteSubordinateUseCase(repository),
        ),
        ProxyProvider<AuditRepositoryImpl, MarkUnfavoriteSubordinateUseCase>(
          update: (_, repository, __) => createMarkUnfavoriteSubordinateUseCase(repository),
        ),
        ChangeNotifierProvider<AuditController>(
          create: (context) => AuditController(
            context.read<GetAuditOverviewUseCase>(),
            null,
            null,
            context.read<GetQuarterlyAuditUseCase>(),
            context.read<GetAuditTeamMembersUseCase>(),
            context.read<MarkFavoriteSubordinateUseCase>(),
            context.read<MarkUnfavoriteSubordinateUseCase>(),
            context.read<AuditRepositoryImpl>(),
          )..initializeSingleAuditDetails(quarterlyAuditId: quarterlyAuditId, date: date),
        ),
      ],
      child: _SingleAuditDetailsView(
        key: ValueKey('$quarterlyAuditId|$date|$lastAuditDate'),
        quarterlyAuditId: quarterlyAuditId,
        date: date,
        lastAuditDate: lastAuditDate,
      ),
    );
  }
}

class _SingleAuditDetailsView extends StatefulWidget {
  const _SingleAuditDetailsView({
    super.key,
    required this.date,
    required this.lastAuditDate,
    required this.quarterlyAuditId,
  });

  final String date;
  final String lastAuditDate;
  final String quarterlyAuditId;

  @override
  State<_SingleAuditDetailsView> createState() => _SingleAuditDetailsViewState();
}

class _SingleAuditDetailsViewState extends State<_SingleAuditDetailsView> {
  late final ValueNotifier<_SingleAuditFiltersState> _filtersNotifier;

  @override
  void initState() {
    super.initState();
    _filtersNotifier = ValueNotifier<_SingleAuditFiltersState>(const _SingleAuditFiltersState());
  }

  @override
  void didUpdateWidget(covariant _SingleAuditDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final didIdentityChange =
        oldWidget.lastAuditDate != widget.lastAuditDate ||
        oldWidget.date != widget.date ||
        oldWidget.quarterlyAuditId != widget.quarterlyAuditId;
    if (!didIdentityChange) {
      return;
    }

    _clearFiltersSilently();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<AuditController>().initializeSingleAuditDetails(
        quarterlyAuditId: widget.quarterlyAuditId,
        date: widget.date,
      );
    });
  }

  @override
  void dispose() {
    _filtersNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuditController>();
    final state = controller.state;
    final audit = state.quarterlyAudit;
    final profileDescription = audit?.descriptions.isEmpty ?? true
        ? null
        : audit!.descriptions.first;

    return Scaffold(
      backgroundColor: AppColors.mainBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 2, 16, 0), child: _buildHeader(context)),
            const SizedBox(height: 18),
            if (state.isLoading)
              Expanded(child: Center(child: FastCircularProgressIndicator()))
            else if (audit == null)
              const Expanded(
                child: Center(
                  child: AppTextView.body(
                    'No audit details found.',
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    children: [
                      _buildAuditProfileCard(audit, profileDescription),
                      const SizedBox(height: 18),
                      _buildSwitchTeamMembersSection(
                        context,
                        audit,
                        state.mainList?.results ?? const <AuditProfile>[],
                      ),
                      const SizedBox(height: 18),
                      ValueListenableBuilder<_SingleAuditFiltersState>(
                        valueListenable: _filtersNotifier,
                        builder: (context, filtersState, _) {
                          return _buildDescriptionsSection(context, audit, filtersState);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDescriptionDetails(
    BuildContext context,
    QuarterlyAudit audit,
    QuarterlyAuditDescription description,
  ) async {
    final auditController = context.read<AuditController>();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<AuditController>.value(
          value: auditController,
          child: SingleDescriptionDetails(
            audit: audit,
            description: description,
            date: widget.date,
            isOwner: auditController.state.isOwner,
            onAuditUpdated: () async {
              await auditController.refreshSingleAuditDetails(
                quarterlyAuditId: audit.uuid,
                date: widget.date,
              );
            },
          ),
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    await context.read<AuditController>().refreshSingleAuditDetails(
      quarterlyAuditId: audit.uuid,
      date: widget.date,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset(
                  '${AppStrings.imagePath}back.svg',
                  height: 24,
                  width: 24,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          AppTextView.body(
            AppStrings.checkInTitle,
            color: AppColors.secondaryColor,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _buildAuditProfileCard(QuarterlyAudit audit, QuarterlyAuditDescription? description) {
    final lastAuditDate = widget.date;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextView.body1(
                  audit.jobTitle,
                  color: AppColors.secondaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                AppTextView.body(
                  audit.profileName,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13),
                    children: [
                      TextSpan(
                        text: '${AppStrings.lastAudit}: ',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.78),
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      TextSpan(
                        text: CustomFunctions.formatDate(lastAuditDate),
                        style: TextStyle(
                          color: AppColors.secondaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildAvatar(82, audit.profileImage),
        ],
      ),
    );
  }

  Widget _buildSwitchTeamMembersSection(
    BuildContext context,
    QuarterlyAudit audit,
    List<AuditProfile> members,
  ) {
    final previewMembers = members.take(4).toList(growable: false);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextView.body1(
                'Switch Team Member',
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton(
              onPressed: members.isEmpty ? null : () => _openViewAllTeamMembers(context, members),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
              child: const AppTextView.body2(
                'View All',
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: previewMembers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final member = previewMembers[index];
              final isSelected =
                  member.profileUuid == audit.profileUuid || member.profileJob == audit.profileJob;
              return _buildTeamMemberCard(context, member, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openViewAllTeamMembers(BuildContext context, List<AuditProfile> members) {
    final auditController = context.read<AuditController>();
    return showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (_) => ChangeNotifierProvider<AuditController>.value(
        value: auditController,
        child: ViewAllTeamMembers(
          members: members,
          onMemberTap: (member) async {
            Navigator.of(context).pop();
            await _openSelectedTeamMember(context, member);
          },
          onFavoriteTap: (member) async {
            return _markFavorite(context, member);
          },
        ),
      ),
    );
  }

  Widget _buildTeamMemberCard(BuildContext context, AuditProfile member, bool isSelected) {
    return InkWell(
      borderRadius: BorderRadius.circular(5),
      onTap: isSelected ? null : () => _openSelectedTeamMember(context, member),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: isSelected ? AppColors.secondaryColor : Colors.transparent),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -11,
              right: -10,
              child: _FavoriteButton(
                isFavorite: member.isFavorite,
                isLoading: context.watch<AuditController>().isFavoriteUpdating(member.profileJob),
                onPressed: () => _handleFavoriteTap(context, member),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildAvatar(38, member.imageUrl),
                    const SizedBox(height: 8),
                    AppTextView.body3(
                      member.roleTitle,
                      color: AppColors.secondaryColor,
                      fontWeight: FontWeight.w600,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      fontSize: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    AppTextView.body2(
                      member.name,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      fontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSelectedTeamMember(BuildContext context, AuditProfile member) {
    return AppRouter.pushReplacementNamed<void, void>(
      context,
      AppRouter.auditDetails,
      arguments: AuditDetailsRouteArgs(profileJobId: member.profileJob),
    );
  }

  Future<void> _handleFavoriteTap(BuildContext context, AuditProfile member) async {
    try {
      await _markFavorite(context, member);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Unable to update favorite right now.')));
    }
  }

  Future<List<AuditProfile>> _markFavorite(BuildContext context, AuditProfile member) {
    return context.read<AuditController>().toggleFavoriteSubordinate(
      profileJobId: member.profileJob,
      isFavorite: member.isFavorite,
    );
  }

  Widget _buildDescriptionsSection(
    BuildContext context,
    QuarterlyAudit audit,
    _SingleAuditFiltersState filtersState,
  ) {
    final filteredDescriptions = _filteredDescriptions(audit, filtersState);
    if (filteredDescriptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextView.body1(
                filtersState.isFilterOptionsVisible ? 'Filter Options' : 'Descriptions',
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              borderRadius: BorderRadius.circular(filtersState.isFilterOptionsVisible ? 8 : 8),
              onTap: _toggleFilterOptions,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.all(filtersState.isFilterOptionsVisible ? 8 : 8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor,
                  borderRadius: BorderRadius.circular(filtersState.isFilterOptionsVisible ? 8 : 8),
                ),
                child: Icon(
                  filtersState.isFilterOptionsVisible
                      ? Icons.close_rounded
                      : Icons.filter_alt_rounded,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slideAnimation = Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation);

              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: SlideTransition(position: slideAnimation, child: child),
                ),
              );
            },
            layoutBuilder: (currentChild, previousChildren) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final child in previousChildren) child,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            child: filtersState.isFilterOptionsVisible
                ? _buildFilterOptionsView(audit, filtersState)
                : filteredDescriptions.isEmpty
                ? Container(
                    key: const ValueKey('empty-filter-results'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const AppTextView.body2(
                      'No descriptions match the selected filters.',
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : ListView.separated(
                    key: const ValueKey('description-list'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredDescriptions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final description = filteredDescriptions[index];
                      return _buildDescriptionCard(context, audit, description, index);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterOptionsView(QuarterlyAudit audit, _SingleAuditFiltersState filtersState) {
    final categories = _categoryOptions(audit, filtersState);
    final milestoneOptions = _milestoneOptions(audit, filtersState);
    final auditTimingOptions = _auditTimingOptions(audit, filtersState);
    final auditTypeOptions = _auditTypeOptions(audit, filtersState);

    return Container(
      key: const ValueKey('filter-options'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuditedOnlyRow(filtersState),
          const SizedBox(height: 16),
          _buildFilterGroup(
            label: 'Categories',
            options: categories,
            selectedValues: filtersState.selectedCategories,
            onTap: _toggleCategory,
          ),
          const SizedBox(height: 16),
          _buildFilterGroup(
            label: 'Milestons',
            options: milestoneOptions,
            selectedValues: filtersState.selectedMilestones,
            onTap: _toggleMilestone,
          ),
          const SizedBox(height: 16),
          _buildFilterGroup(
            label: 'Audit Timing',
            options: auditTimingOptions,
            selectedValues: filtersState.selectedAuditTimings,
            onTap: _toggleAuditTiming,
          ),
          const SizedBox(height: 16),
          _buildFilterGroup(
            label: 'Audit Type',
            options: auditTypeOptions,
            selectedValues: filtersState.selectedAuditTypes,
            onTap: _toggleAuditType,
          ),
          if (_hasActiveFilters(filtersState)) ...[
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _clearFilters,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const AppTextView.body2(
                  'Clear All',
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditedOnlyRow(_SingleAuditFiltersState filtersState) {
    return Row(
      children: [
        const Expanded(
          child: AppTextView.body2(
            'Show Audited Only',
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        GestureDetector(
          onTap: _toggleShowAuditedOnly,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 30,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: filtersState.showAuditedOnly
                  ? AppColors.secondaryColor
                  : AppColors.surfaceDark2,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: filtersState.showAuditedOnly
                    ? AppColors.secondaryColor
                    : AppColors.fieldBorder.withValues(alpha: 0.5),
              ),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              alignment: filtersState.showAuditedOnly
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.textPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterGroup({
    required String label,
    required List<String> options,
    required Set<String> selectedValues,
    required ValueChanged<String> onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextView.body2(label, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        const SizedBox(height: 10),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selectedValues.contains(option);
              return InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () => onTap(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.orange2 : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: isSelected ? AppColors.orange2 : AppColors.textPrimary,
                    ),
                  ),
                  child: Center(
                    child: AppTextView.body3(
                      option,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<QuarterlyAuditDescription> _filteredDescriptions(
    QuarterlyAudit audit,
    _SingleAuditFiltersState filtersState,
  ) {
    return audit.descriptions
        .where((description) {
          if (!_isDescriptionEligibleForDisplay(description, filtersState)) {
            return false;
          }

          final categoryTitle = CustomFunctions.resolveAuditCategoryOption(
            audit: audit,
            description: description,
          );
          final milestone = CustomFunctions.normalizeAuditMilestone(description.milestoneDay);
          final auditTiming = CustomFunctions.resolveAuditTiming(description);
          final auditType = CustomFunctions.normalizeAuditType(description.auditFactorType);

          final matchesCategory =
              filtersState.selectedCategories.isEmpty ||
              filtersState.selectedCategories.contains(categoryTitle);
          final matchesMilestone =
              filtersState.selectedMilestones.isEmpty ||
              filtersState.selectedMilestones.contains(milestone);
          final matchesAuditTiming =
              filtersState.selectedAuditTimings.isEmpty ||
              filtersState.selectedAuditTimings.contains(auditTiming);
          final matchesAuditType =
              filtersState.selectedAuditTypes.isEmpty ||
              filtersState.selectedAuditTypes.contains(auditType);

          return matchesCategory && matchesMilestone && matchesAuditTiming && matchesAuditType;
        })
        .toList(growable: false);
  }

  bool _isDescriptionAudited(QuarterlyAuditDescription description) {
    return description.hasAudit || description.totalRatings > 0;
  }

  bool _isDescriptionEligibleForDisplay(
    QuarterlyAuditDescription description,
    _SingleAuditFiltersState filtersState,
  ) {
    if (!_isDescriptionEligibleForFilterOptions(description, filtersState)) {
      return false;
    }

    final isAudited = _isDescriptionAudited(description);
    if (filtersState.showAuditedOnly && !isAudited) {
      return false;
    }

    return true;
  }

  bool _isDescriptionEligibleForFilterOptions(
    QuarterlyAuditDescription description,
    _SingleAuditFiltersState filtersState,
  ) {
    final isAudited = _isDescriptionAudited(description);
    final isSelectedAuditDateBeforeToday = CustomFunctions.isDateBeforeToday(widget.date);

    if (isSelectedAuditDateBeforeToday && !isAudited) {
      return false;
    }

    return true;
  }

  List<String> _categoryOptions(QuarterlyAudit audit, _SingleAuditFiltersState filtersState) {
    final options =
        audit.descriptions
            .where(
              (description) => _isDescriptionEligibleForFilterOptions(description, filtersState),
            )
            .map(
              (description) => CustomFunctions.resolveAuditCategoryOption(
                audit: audit,
                description: description,
              ),
            )
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return options;
  }

  List<String> _milestoneOptions(QuarterlyAudit audit, _SingleAuditFiltersState filtersState) {
    final options =
        audit.descriptions
            .where(
              (description) => _isDescriptionEligibleForFilterOptions(description, filtersState),
            )
            .map((description) => CustomFunctions.normalizeAuditMilestone(description.milestoneDay))
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return options;
  }

  List<String> _auditTimingOptions(QuarterlyAudit audit, _SingleAuditFiltersState filtersState) {
    final preferredOrder = AppStrings.auditTimingOptions;
    final availableOptions = audit.descriptions
        .where((description) => _isDescriptionEligibleForFilterOptions(description, filtersState))
        .map(CustomFunctions.resolveAuditTiming)
        .where((value) => value.isNotEmpty)
        .toSet();

    return preferredOrder.where(availableOptions.contains).toList(growable: false);
  }

  List<String> _auditTypeOptions(QuarterlyAudit audit, _SingleAuditFiltersState filtersState) {
    final preferredOrder = AppStrings.auditTypeOptions;
    final availableOptions = audit.descriptions
        .where((description) => _isDescriptionEligibleForFilterOptions(description, filtersState))
        .map((description) => CustomFunctions.normalizeAuditType(description.auditFactorType))
        .where((value) => value.isNotEmpty)
        .toSet();

    return preferredOrder.where(availableOptions.contains).toList(growable: false);
  }

  bool _hasActiveFilters(_SingleAuditFiltersState filtersState) =>
      filtersState.showAuditedOnly ||
      filtersState.selectedCategories.isNotEmpty ||
      filtersState.selectedMilestones.isNotEmpty ||
      filtersState.selectedAuditTimings.isNotEmpty ||
      filtersState.selectedAuditTypes.isNotEmpty;

  void _toggleFilterOptions() {
    final currentState = _filtersNotifier.value;
    _filtersNotifier.value = currentState.copyWith(
      isFilterOptionsVisible: !currentState.isFilterOptionsVisible,
    );
  }

  void _toggleCategory(String value) {
    _filtersNotifier.value = _filtersNotifier.value.toggleCategory(value);
  }

  void _toggleShowAuditedOnly() {
    final currentState = _filtersNotifier.value;
    _filtersNotifier.value = currentState.copyWith(showAuditedOnly: !currentState.showAuditedOnly);
  }

  void _toggleMilestone(String value) {
    _filtersNotifier.value = _filtersNotifier.value.toggleMilestone(value);
  }

  void _toggleAuditTiming(String value) {
    _filtersNotifier.value = _filtersNotifier.value.toggleAuditTiming(value);
  }

  void _toggleAuditType(String value) {
    _filtersNotifier.value = _filtersNotifier.value.toggleAuditType(value);
  }

  void _clearFilters() {
    _clearFiltersSilently();
  }

  void _clearFiltersSilently() {
    _filtersNotifier.value = const _SingleAuditFiltersState();
  }

  Widget _buildDescriptionCard(
    BuildContext context,
    QuarterlyAudit audit,
    QuarterlyAuditDescription description,
    int index,
  ) {
    final categoryTitle = CustomFunctions.resolveAuditCategoryTitle(
      audit: audit,
      description: description,
    );
    final title = categoryTitle.isEmpty ? 'Description ${index + 1}' : categoryTitle;
    final auditFactorType = CustomFunctions.capitalizeFirstLetter(description.auditFactorType);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openDescriptionDetails(context, audit, description),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 8, 12, 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.transparent, width: 1.4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppTextView.body1(
                          title,
                          color: AppColors.secondaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildPillLabel(
                        auditFactorType.isEmpty ? 'Audit' : auditFactorType,
                        isCompact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AppTextView.body3(
                    description.description.isEmpty
                        ? 'No description available.'
                        : description.description,
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AppTextView.body3(
                        'Confidence: ${_formatConfidence(description.confidenceLevel)}%',
                        fontSize: 11,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),

                      SizedBox(width: 8),
                      _buildDescriptionRatingBadge(
                        value: description.great,
                        color: AppColors.green1,
                      ),
                      SizedBox(width: 5),
                      _buildDescriptionRatingBadge(
                        value: description.almostThere,
                        color: AppColors.orange1,
                      ),
                      SizedBox(width: 5),
                      _buildDescriptionRatingBadge(
                        value: description.needsImprovement,
                        color: AppColors.red1,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 30,
              height: 30,
              margin: EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.secondaryColor,
                size: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionRatingBadge({required int value, required Color color}) {
    return Container(
      alignment: Alignment.center,
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: AppTextView.body4('$value', color: AppColors.textPrimary, fontWeight: FontWeight.w700),
    );
  }

  String _formatConfidence(double value) {
    final rounded = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
    return rounded;
  }

  Widget _buildPillLabel(String text, {bool isCompact = false}) {
    return Container(
      constraints: isCompact ? const BoxConstraints(maxWidth: 88) : null,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 9 : 18, vertical: isCompact ? 5 : 7),
      decoration: BoxDecoration(color: AppColors.orange1, borderRadius: BorderRadius.circular(50)),
      child: AppTextView.body2(
        text,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: isCompact ? 10 : 12,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildAvatar(double size, String? imageUrl) {
    final resolvedImageUrl = CustomFunctions.resolveImageUrl(imageUrl);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: resolvedImageUrl == null
              ? const AssetImage('${AppStrings.imagePath}dumy_pic.png')
              : NetworkImage(resolvedImageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _SingleAuditFiltersState {
  const _SingleAuditFiltersState({
    this.isFilterOptionsVisible = false,
    this.showAuditedOnly = false,
    this.selectedCategories = const <String>{},
    this.selectedMilestones = const <String>{},
    this.selectedAuditTimings = const <String>{},
    this.selectedAuditTypes = const <String>{},
  });

  final bool isFilterOptionsVisible;
  final bool showAuditedOnly;
  final Set<String> selectedCategories;
  final Set<String> selectedMilestones;
  final Set<String> selectedAuditTimings;
  final Set<String> selectedAuditTypes;

  _SingleAuditFiltersState copyWith({
    bool? isFilterOptionsVisible,
    bool? showAuditedOnly,
    Set<String>? selectedCategories,
    Set<String>? selectedMilestones,
    Set<String>? selectedAuditTimings,
    Set<String>? selectedAuditTypes,
  }) {
    return _SingleAuditFiltersState(
      isFilterOptionsVisible: isFilterOptionsVisible ?? this.isFilterOptionsVisible,
      showAuditedOnly: showAuditedOnly ?? this.showAuditedOnly,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedMilestones: selectedMilestones ?? this.selectedMilestones,
      selectedAuditTimings: selectedAuditTimings ?? this.selectedAuditTimings,
      selectedAuditTypes: selectedAuditTypes ?? this.selectedAuditTypes,
    );
  }

  _SingleAuditFiltersState toggleCategory(String value) {
    return copyWith(selectedCategories: _toggleSetValue(selectedCategories, value));
  }

  _SingleAuditFiltersState toggleMilestone(String value) {
    return copyWith(selectedMilestones: _toggleSetValue(selectedMilestones, value));
  }

  _SingleAuditFiltersState toggleAuditTiming(String value) {
    return copyWith(selectedAuditTimings: _toggleSetValue(selectedAuditTimings, value));
  }

  _SingleAuditFiltersState toggleAuditType(String value) {
    return copyWith(selectedAuditTypes: _toggleSetValue(selectedAuditTypes, value));
  }

  static Set<String> _toggleSetValue(Set<String> values, String value) {
    final updatedValues = Set<String>.from(values);
    if (updatedValues.contains(value)) {
      updatedValues.remove(value);
    } else {
      updatedValues.add(value);
    }
    return updatedValues;
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isFavorite;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isLoading ? null : onPressed,
      splashRadius: 18,
      icon: isLoading
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
            )
          : Icon(
              Icons.star_rounded,
              color: isFavorite ? AppColors.yellow : AppColors.grey2,
              size: 17,
            ),
    );
  }
}

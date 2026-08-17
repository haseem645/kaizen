import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/navigation/app_menu_type.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/drawer_main_screen.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../../../routes/app_router.dart';
import '../../data/datasources/training_library_remote_data_source.dart';
import '../../data/repositories/training_library_repository_impl.dart';
import '../../domain/entities/training_library_module.dart';
import '../../domain/usecases/get_training_library_modules_usecase.dart';
import '../controllers/training_library_controller.dart';
import 'training_library_detail_screen.dart';

class TrainingLibraryScreen extends StatelessWidget {
  const TrainingLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TrainingLibraryRemoteDataSource>(
          create: (_) => createTrainingLibraryRemoteDataSource(),
        ),
        ProxyProvider<
          TrainingLibraryRemoteDataSource,
          TrainingLibraryRepositoryImpl
        >(
          update: (_, remoteDataSource, __) =>
              createTrainingLibraryRepository(remoteDataSource),
        ),
        ProxyProvider<
          TrainingLibraryRepositoryImpl,
          GetTrainingLibraryModulesUseCase
        >(
          update: (_, repository, __) =>
              createGetTrainingLibraryModulesUseCase(repository),
        ),
        ChangeNotifierProvider<TrainingLibraryController>(
          create: (context) => TrainingLibraryController(
            context.read<GetTrainingLibraryModulesUseCase>(),
          )..initialize(),
        ),
      ],
      child: const _TrainingLibraryScreenView(),
    );
  }
}

class _TrainingLibraryScreenView extends StatefulWidget {
  const _TrainingLibraryScreenView();

  @override
  State<_TrainingLibraryScreenView> createState() =>
      _TrainingLibraryScreenViewState();
}

class _TrainingLibraryScreenViewState
    extends State<_TrainingLibraryScreenView> {
  late final ScrollController _scrollController;
  late final TrainingLibraryController _controller;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _controller = context.read<TrainingLibraryController>();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 360) {
      return;
    }

    _controller.loadNextPage();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingLibraryController>();

    return DrawerMainScreen(
      title: AppStrings.trainingLibraryTitle,
      selectedMenu: AppMenuType.library,
      centerTitle: true,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: controller.isInitialLoading && controller.items.isEmpty
                  ? Center(child: FastCircularProgressIndicator())
                  : _TrainingLibraryContent(
                      controller: controller,
                      scrollController: _scrollController,
                    ),
            ),
            const _TrainingLibraryCreateAction(),
          ],
        ),
      ),
    );
  }
}

class _TrainingLibraryContent extends StatelessWidget {
  const _TrainingLibraryContent({
    required this.controller,
    required this.scrollController,
  });

  final TrainingLibraryController controller;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final items = controller.visibleItems;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.isInlineLoading && controller.items.isNotEmpty) ...[
            Center(child: FastCircularProgressIndicator(width: 28, height: 28)),
            const SizedBox(height: 14),
          ],
          _TrainingLibrarySearchBar(controller: controller),
          const SizedBox(height: 12),
          _DepartmentFilterStrip(controller: controller),
          const SizedBox(height: 14),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: _TrainingLibraryResultArea(
                controller: controller,
                items: items,
                scrollController: scrollController,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingLibrarySearchBar extends StatelessWidget {
  const _TrainingLibrarySearchBar({required this.controller});

  final TrainingLibraryController controller;

  @override
  Widget build(BuildContext context) {
    final selectedFilterLabel = _searchFilterLabel(controller.searchFilter);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 370;
        final filterWidth = isCompact ? 74.0 : 112.0;

        return Container(
          height: 52,
          padding: const EdgeInsets.only(left: 14, right: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark3,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.fieldBorder.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: controller.updateSearchQuery,
                  textInputAction: TextInputAction.search,
                  cursorHeight: 18,
                  cursorColor: AppColors.textPrimary,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.trainingLibrarySearchHint(
                      selectedFilterLabel,
                    ),
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: AppColors.fieldBorder.withValues(alpha: 0.35),
              ),
              PopupMenuButton<TrainingLibrarySearchFilter>(
                tooltip: AppStrings.trainingLibrarySearchFieldTooltip,
                color: AppColors.surfaceDark3,
                surfaceTintColor: AppColors.surfaceDark3,
                onSelected: controller.selectSearchFilter,
                itemBuilder: (_) => TrainingLibrarySearchFilter.values
                    .map(
                      (filter) => PopupMenuItem<TrainingLibrarySearchFilter>(
                        value: filter,
                        child: AppTextView.body3(
                          _searchFilterLabel(filter),
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(growable: false),
                child: Container(
                  width: filterWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.purple1.withValues(alpha: 0.26),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.secondaryColor.withValues(alpha: 0.34),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppTextView.body3(
                          _searchFilterChipLabel(
                            controller.searchFilter,
                            compact: isCompact,
                          ),
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DepartmentFilterStrip extends StatelessWidget {
  const _DepartmentFilterStrip({required this.controller});

  final TrainingLibraryController controller;

  @override
  Widget build(BuildContext context) {
    final items = <TrainingLibraryDepartment>[
      const TrainingLibraryDepartment(
        id: 'all',
        name: AppStrings.trainingLibraryAllFilter,
      ),
      ...controller.departments,
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, index) => index == 0
            ? Row(
                children: [
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 36,
                    color: AppColors.fieldBorder.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 8),
                ],
              )
            : const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = controller.selectedDepartmentId == item.id;

          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => controller.selectDepartment(item.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondaryColor
                    : AppColors.surfaceDark3,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? AppColors.secondaryColor
                      : AppColors.fieldBorder.withValues(alpha: 0.35),
                ),
              ),
              child: Center(
                child: AppTextView.body3(
                  item.name,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrainingLibraryResultArea extends StatelessWidget {
  const _TrainingLibraryResultArea({
    required this.controller,
    required this.items,
    required this.scrollController,
  });

  final TrainingLibraryController controller;
  final List<TrainingLibraryModule> items;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (controller.errorMessage != null && controller.items.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _LibraryStatusState(
            message: controller.errorMessage!,
            actionLabel: AppStrings.trainingLibraryRetry,
            onActionTap: controller.initialize,
          ),
        ],
      );
    }

    if (items.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          _LibraryStatusState(
            message: AppStrings.trainingLibraryNoModulesFound,
          ),
        ],
      );
    }

    return switch (controller.viewMode) {
      TrainingLibraryViewMode.grid => _TrainingLibraryGrid(
        items: items,
        isLoadingMore: controller.isLoadingMore,
        scrollController: scrollController,
      ),
      TrainingLibraryViewMode.list => _TrainingLibraryList(
        items: items,
        isLoadingMore: controller.isLoadingMore,
        scrollController: scrollController,
      ),
    };
  }
}

class _TrainingLibraryGrid extends StatelessWidget {
  const _TrainingLibraryGrid({
    required this.items,
    required this.isLoadingMore,
    required this.scrollController,
  });

  final List<TrainingLibraryModule> items;
  final bool isLoadingMore;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final crossAxisCount = constraints.maxWidth >= 1020
            ? 3
            : (constraints.maxWidth >= 620 ? 2 : 1);
        final mainAxisExtent = crossAxisCount == 1 ? 360.0 : 320.0;

        return GridView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: mainAxisExtent,
          ),
          itemCount: items.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return Center(child: FastCircularProgressIndicator());
            }
            return _TrainingLibraryGridCard(module: items[index]);
          },
        );
      },
    );
  }
}

class _TrainingLibraryList extends StatelessWidget {
  const _TrainingLibraryList({
    required this.items,
    required this.isLoadingMore,
    required this.scrollController,
  });

  final List<TrainingLibraryModule> items;
  final bool isLoadingMore;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 18),
            child: Center(child: FastCircularProgressIndicator()),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 14),
          child: _TrainingLibraryListCard(module: items[index]),
        );
      },
    );
  }
}

class _TrainingLibraryGridCard extends StatelessWidget {
  const _TrainingLibraryGridCard({required this.module});

  final TrainingLibraryModule module;

  @override
  Widget build(BuildContext context) {
    return _TrainingLibraryCardShell(
      onTap: () => _openLibraryDetail(context, module),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageHeight = (constraints.maxWidth / 1.8).clamp(112.0, 148.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ModuleThumbnail(
                thumbnailLink: module.thumbnailLink,
                height: imageHeight,
                emptyIcon: Icons.video_library_rounded,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextView.body(
                      _displayModuleTitle(module),
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _CardMetaRow(module: module),
                    const SizedBox(height: 10),
                    _CardFieldLine(
                      label: AppStrings.trainingLibraryDepartment,
                      value: _displayModuleValue(module.department.name),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 6),
                    _CardFieldLine(
                      label: AppStrings.trainingLibrarySeat,
                      value: _displayModuleValue(module.seat.title),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 6),
                    _CardFieldLine(
                      label: AppStrings.trainingLibraryCategory,
                      value: _displayModuleValue(module.category.title),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrainingLibraryListCard extends StatelessWidget {
  const _TrainingLibraryListCard({required this.module});

  final TrainingLibraryModule module;

  @override
  Widget build(BuildContext context) {
    return _TrainingLibraryCardShell(
      onTap: () => _openLibraryDetail(context, module),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModuleThumbnail(
            thumbnailLink: module.thumbnailLink,
            height: 176,
            emptyIcon: Icons.video_library_rounded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextView.body(
                  _displayModuleTitle(module),
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _CardMetaRow(module: module),
                const SizedBox(height: 12),
                _CardFieldLine(
                  label: AppStrings.trainingLibraryDepartment,
                  value: _displayModuleValue(module.department.name),
                  maxLines: 2,
                ),
                const SizedBox(height: 6),
                _CardFieldLine(
                  label: AppStrings.trainingLibrarySeat,
                  value: _displayModuleValue(module.seat.title),
                  maxLines: 2,
                ),
                const SizedBox(height: 6),
                _CardFieldLine(
                  label: AppStrings.trainingLibraryCategory,
                  value: _displayModuleValue(module.category.title),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingLibraryCardShell extends StatelessWidget {
  const _TrainingLibraryCardShell({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark3,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.fieldBorder.withValues(alpha: 0.16),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ModuleThumbnail extends StatelessWidget {
  const _ModuleThumbnail({
    required this.thumbnailLink,
    required this.height,
    required this.emptyIcon,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final String? thumbnailLink;
  final double height;
  final IconData emptyIcon;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = CustomFunctions.resolveImageUrl(thumbnailLink);

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: imageUrl == null
            ? _ImagePlaceholder(icon: emptyIcon)
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _ImagePlaceholder(icon: emptyIcon),
                errorWidget: (_, __, ___) => _ImagePlaceholder(icon: emptyIcon),
              ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'lib/assets/images/fallback_image.png',
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Center(
          child: Icon(icon, color: AppColors.textSecondary, size: 30),
        );
      },
    );
  }
}

class _CardMetaRow extends StatelessWidget {
  const _CardMetaRow({required this.module});

  final TrainingLibraryModule module;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        AppTextView.body3(
          AppStrings.trainingLibraryLessonsCount(module.lessonsCount),
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        const _MetaDot(),
        AppTextView.body3(
          CustomFunctions.formatDuration(module.totalDuration),
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}

class _MetaDot extends StatelessWidget {
  const _MetaDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: AppColors.textSecondary,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _CardFieldLine extends StatelessWidget {
  const _CardFieldLine({
    required this.label,
    required this.value,
    this.maxLines = 2,
  });

  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextView.body4(
          label,
          color: AppColors.purple1,
          fontWeight: FontWeight.w700,
        ),
        const SizedBox(height: 2),
        AppTextView.body3(
          value,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _LibraryStatusState extends StatelessWidget {
  const _LibraryStatusState({
    required this.message,
    this.actionLabel,
    this.onActionTap,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark3,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            AppTextView.body(
              message,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onActionTap != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onActionTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondaryColor,
                  side: const BorderSide(color: AppColors.secondaryColor),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrainingLibraryCreateAction extends StatelessWidget {
  const _TrainingLibraryCreateAction();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppManager.instance,
      builder: (context, _) {
        if (!AppManager.instance.currentUserCanManageAnyTrainingModules) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.mainBg,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                spreadRadius: 20,
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Align(
            alignment: Alignment.topCenter,
            child: AppButton(
              text: AppStrings.trainingLibraryCreate,
              minimumHeight: 40,
              onPressed: () => AppRouter.pushNamed(
                context,
                AppRouter.seatProfileTrainingSetup,
              ),
            ),
          ),
        );
      },
    );
  }
}

String _searchFilterLabel(TrainingLibrarySearchFilter filter) {
  return switch (filter) {
    TrainingLibrarySearchFilter.category => AppStrings.trainingLibraryCategory,
    TrainingLibrarySearchFilter.department =>
      AppStrings.trainingLibraryDepartment,
    TrainingLibrarySearchFilter.seat => AppStrings.trainingLibrarySeat,
  };
}

String _searchFilterChipLabel(
  TrainingLibrarySearchFilter filter, {
  required bool compact,
}) {
  if (!compact) {
    return _searchFilterLabel(filter);
  }

  return switch (filter) {
    TrainingLibrarySearchFilter.category => 'Cat',
    TrainingLibrarySearchFilter.department => 'Dept',
    TrainingLibrarySearchFilter.seat => AppStrings.trainingLibrarySeat,
  };
}

Future<void> _openLibraryDetail(
  BuildContext context,
  TrainingLibraryModule module,
) async {
  final shouldRefresh = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => TrainingLibraryDetailScreen(module: module),
    ),
  );
  if (shouldRefresh != true || !context.mounted) {
    return;
  }

  await context.read<TrainingLibraryController>().refresh();
}

String _displayModuleTitle(TrainingLibraryModule module) {
  final title = module.title.trim();
  if (title.isNotEmpty) {
    return title;
  }

  return AppStrings.trainingLibraryUntitledModule;
}

String _displayModuleValue(String value) {
  final trimmed = value.trim();
  if (trimmed.isNotEmpty) {
    return trimmed;
  }

  return AppStrings.trainingLibraryNotAvailable;
}

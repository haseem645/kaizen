import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparrowkaizen/core/widgets/app_dot_divider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_full_screen.dart';
import '../../../../core/widgets/app_gradient_action_button.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../../../routes/app_router.dart';
import '../../data/datasources/feedback_remote_data_source.dart';
import '../../data/repositories/feedback_repository_impl.dart';
import '../../domain/entities/feedback_post.dart';
import '../../domain/usecases/get_feedback_posts_usecase.dart';
import '../providers/questions_feedback_controller.dart';
import '../widgets/feedback_post_card.dart';
import '../widgets/feedback_post_create_sheet.dart';

class QuestionsFeedbackScreen extends StatelessWidget {
  const QuestionsFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FeedbackRemoteDataSource>(create: (_) => createFeedbackRemoteDataSource()),
        ProxyProvider<FeedbackRemoteDataSource, FeedbackRepositoryImpl>(
          update: (_, remoteDataSource, __) => createFeedbackRepository(remoteDataSource),
        ),
        ProxyProvider<FeedbackRepositoryImpl, GetFeedbackPostsUseCase>(
          update: (_, repository, __) => createGetFeedbackPostsUseCase(repository),
        ),
        ChangeNotifierProvider<QuestionsFeedbackController>(
          create: (context) => QuestionsFeedbackController(context.read<GetFeedbackPostsUseCase>()),
        ),
      ],
      child: const _QuestionsFeedbackView(),
    );
  }
}

class _QuestionsFeedbackView extends StatefulWidget {
  const _QuestionsFeedbackView();

  @override
  State<_QuestionsFeedbackView> createState() => _QuestionsFeedbackViewState();
}

class _QuestionsFeedbackViewState extends State<_QuestionsFeedbackView> {
  late final ScrollController _scrollController;
  late final FocusNode _searchFocusNode;
  late final QuestionsFeedbackController _controller;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _searchFocusNode = FocusNode();
    _controller = context.read<QuestionsFeedbackController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.initialize());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _scrollController.position.extentAfter > 320) {
      return;
    }

    _controller.loadNextPage();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<QuestionsFeedbackController>();

    return AppFullScreen(
      backgroundColor: AppColors.hex111317,
      useSafeArea: false,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 7),
          child: Stack(
            children: [
              _QuestionsFeedbackTopBar(
                controller: controller,
                searchFocusNode: _searchFocusNode,
                onSearchTap: _openSearch,
                onSearchBack: _closeSearch,
                onSearchSubmit: controller.submitSearch,
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    AppDotDivider(),
                    const SizedBox(height: 16),
                    _CommunityPostsHeading(
                      totalCount: controller.totalCount,
                      searchQuery: controller.isShowingSearchResults
                          ? controller.searchQuery
                          : null,
                      onClearSearch: controller.clearSearch,
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: _buildPostList(controller)),
                    _QuestionsFeedbackAddAction(onTap: _openCreateSheet),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostList(QuestionsFeedbackController controller) {
    if (controller.isInitialLoading || controller.isSearchLoading) {
      return Center(child: FastCircularProgressIndicator());
    }

    if (controller.errorMessage != null && controller.posts.isEmpty) {
      return _FeedbackMessageView(
        message: AppStrings.questionsFeedbackLoadFailed,
        actionLabel: AppStrings.questionsFeedbackRetryAction,
        onActionTap: controller.refresh,
      );
    }

    if (controller.posts.isEmpty && controller.isShowingSearchResults) {
      return _NoSearchResultsView(
        onClearSearch: controller.clearSearch,
        onAskQuestion: _openCreateSheet,
      );
    }

    if (controller.posts.isEmpty) {
      return const _FeedbackMessageView(message: AppStrings.questionsFeedbackNoPosts);
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: controller.posts.length + (controller.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == controller.posts.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(child: FastCircularProgressIndicator()),
            );
          }

          final post = controller.posts[index];
          return FeedbackPostCard(
            post: post,
            onTap: () => _openPostDetail(post),
            isUpdatingLike: controller.isUpdatingLike(post.id),
            onLikeTap: () => _handleLikeTap(post.id),
          );
        },
      ),
    );
  }

  Future<void> _openPostDetail(FeedbackPost post) async {
    await Navigator.of(context).pushNamed<void>(
      AppRouter.questionsFeedbackDetail,
      arguments: QuestionsFeedbackDetailRouteArgs(post: post),
    );

    if (!mounted) {
      return;
    }

    await _controller.refresh();
  }

  Future<void> _handleLikeTap(String postId) async {
    final didUpdate = await _controller.toggleLike(postId);
    if (!mounted || didUpdate) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.questionsFeedbackLikeUpdateFailed)));
  }

  void _openSearch() {
    _controller.openSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  Future<void> _closeSearch() async {
    _searchFocusNode.unfocus();
    await _controller.closeSearch();
  }

  Future<void> _openCreateSheet() {
    return FeedbackPostCreateSheet.show(context);
  }
}

class _QuestionsFeedbackTopBar extends StatelessWidget {
  const _QuestionsFeedbackTopBar({
    required this.controller,
    required this.searchFocusNode,
    required this.onSearchTap,
    required this.onSearchBack,
    required this.onSearchSubmit,
  });

  final QuestionsFeedbackController controller;
  final FocusNode searchFocusNode;
  final VoidCallback onSearchTap;
  final Future<void> Function() onSearchBack;
  final Future<void> Function() onSearchSubmit;

  @override
  Widget build(BuildContext context) {
    if (controller.isSearchActive) {
      return Row(
        children: [
          AppBackButton(onPressed: onSearchBack),
          Expanded(
            child: TextField(
              controller: controller.searchController,
              focusNode: searchFocusNode,
              onChanged: controller.updateSearchQuery,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: AppColors.textPrimary,
              cursorHeight: 16,
              decoration: const InputDecoration(
                hintText: AppStrings.questionsFeedbackSearchHint,
                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.hasSearchText)
            _SearchSubmitButton(isLoading: controller.isSearchLoading, onTap: onSearchSubmit),
        ],
      );
    }

    return Row(
      children: [
        const AppBackButton(),
        const SizedBox(width: 4),
        const Expanded(
          child: AppTextView.title(
            AppStrings.questionsFeedbackScreenTitle,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        _HeaderIconButton(
          icon: Icons.search_rounded,
          tooltip: AppStrings.questionsFeedbackSearchTooltip,
          onTap: onSearchTap,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: AppColors.hex252a40,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, color: AppColors.textPrimary, size: 20),
          ),
        ),
      ),
    );
  }
}

class _SearchSubmitButton extends StatelessWidget {
  const _SearchSubmitButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.purple1,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isLoading ? null : onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                  )
                : const Icon(Icons.search_rounded, color: AppColors.textPrimary, size: 21),
          ),
        ),
      ),
    );
  }
}

class _QuestionsFeedbackAddAction extends StatelessWidget {
  const _QuestionsFeedbackAddAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      decoration: BoxDecoration(
        color: AppColors.hex111317,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            spreadRadius: 14,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: AppGradientActionButton(
          label: AppStrings.questionsFeedbackAddAction,
          icon: Icons.add_rounded,
          showIcon: false,
          iconSize: 16,
          textSize: 14,
          minHeight: 40,
          borderRadius: 10,
          iconSpacing: 8,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _CommunityPostsHeading extends StatelessWidget {
  const _CommunityPostsHeading({required this.totalCount, this.searchQuery, this.onClearSearch});

  final int totalCount;
  final String? searchQuery;
  final Future<void> Function()? onClearSearch;

  @override
  Widget build(BuildContext context) {
    final isShowingSearchResults = searchQuery != null;
    final postLabel = totalCount == 1
        ? AppStrings.questionsFeedbackPostSingular
        : AppStrings.questionsFeedbackPostPlural;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextView.title1(
                isShowingSearchResults
                    ? AppStrings.questionsFeedbackSearchResults
                    : AppStrings.questionsFeedbackCommunityPosts,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            AppTextView.body(
              '$totalCount $postLabel',
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ],
        ),
        if (isShowingSearchResults) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.hex252a40,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.purple1.withValues(alpha: 0.55)),
                  ),
                  child: AppTextView.body(
                    AppStrings.questionsFeedbackShowingResultsFor(searchQuery!),
                    color: AppColors.lightPurple1,
                    fontSize: 12,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.hex252a40,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onClearSearch,
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _NoSearchResultsView extends StatelessWidget {
  const _NoSearchResultsView({required this.onClearSearch, required this.onAskQuestion});

  final Future<void> Function() onClearSearch;
  final VoidCallback onAskQuestion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: CustomPaint(
          foregroundPainter: const _DashedRoundedBorderPainter(),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.hex252a40,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search_rounded, color: AppColors.lightPurple1, size: 34),
                ),
                const SizedBox(height: 22),
                const AppTextView.title(
                  AppStrings.questionsFeedbackNoMatchingFeedback,
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const AppTextView.body(
                  AppStrings.questionsFeedbackNoMatchingFeedbackMessage,
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: onClearSearch,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.lightPurple1,
                          side: const BorderSide(color: AppColors.lightPurple1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: const Text(AppStrings.clearSearch),
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: <Color>[AppColors.purple1, AppColors.secondaryColor],
                          ),
                        ),
                        child: TextButton(
                          onPressed: onAskQuestion,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          child: const Text(AppStrings.questionsFeedbackAskQuestionAction),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)));
    final paint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 12) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + 6).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) => false;
}

class _FeedbackMessageView extends StatelessWidget {
  const _FeedbackMessageView({required this.message, this.actionLabel, this.onActionTap});

  final String message;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextView.body(
              message,
              color: AppColors.textSecondary,
              fontSize: 13,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onActionTap != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onActionTap, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

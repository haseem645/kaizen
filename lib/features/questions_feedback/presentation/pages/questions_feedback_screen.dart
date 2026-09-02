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
        Provider<FeedbackRemoteDataSource>(
          create: (_) => createFeedbackRemoteDataSource(),
        ),
        ProxyProvider<FeedbackRemoteDataSource, FeedbackRepositoryImpl>(
          update: (_, remoteDataSource, __) =>
              createFeedbackRepository(remoteDataSource),
        ),
        ProxyProvider<FeedbackRepositoryImpl, GetFeedbackPostsUseCase>(
          update: (_, repository, __) =>
              createGetFeedbackPostsUseCase(repository),
        ),
        ChangeNotifierProvider<QuestionsFeedbackController>(
          create: (context) => QuestionsFeedbackController(
            context.read<GetFeedbackPostsUseCase>(),
          ),
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _controller.initialize(),
    );
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
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 320) {
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
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    AppDotDivider(),
                    const SizedBox(height: 16),
                    _CommunityPostsHeading(totalCount: controller.totalCount),
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

    if (controller.posts.isEmpty) {
      return const _FeedbackMessageView(
        message: AppStrings.questionsFeedbackNoPosts,
      );
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
      ..showSnackBar(
        const SnackBar(
          content: Text(AppStrings.questionsFeedbackLikeUpdateFailed),
        ),
      );
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
  });

  final QuestionsFeedbackController controller;
  final FocusNode searchFocusNode;
  final VoidCallback onSearchTap;
  final Future<void> Function() onSearchBack;

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
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.hasSearchText)
            IconButton(
              onPressed: controller.clearSearch,
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
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
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

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
  const _CommunityPostsHeading({required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final postLabel = totalCount == 1
        ? AppStrings.questionsFeedbackPostSingular
        : AppStrings.questionsFeedbackPostPlural;
    return Row(
      children: [
        const Expanded(
          child: AppTextView.title1(
            AppStrings.questionsFeedbackCommunityPosts,
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
    );
  }
}

class _FeedbackMessageView extends StatelessWidget {
  const _FeedbackMessageView({
    required this.message,
    this.actionLabel,
    this.onActionTap,
  });

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

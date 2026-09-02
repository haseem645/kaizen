import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparrowkaizen/core/widgets/fast_circular_progress.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_confirmation_dialog.dart';
import '../../../../core/widgets/app_dot_divider.dart';
import '../../../../core/widgets/app_full_screen.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../data/datasources/feedback_remote_data_source.dart';
import '../../data/repositories/feedback_repository_impl.dart';
import '../../domain/entities/feedback_comment.dart';
import '../../domain/entities/feedback_post.dart';
import '../../domain/usecases/get_feedback_posts_usecase.dart';
import '../providers/questions_feedback_detail_controller.dart';
import '../widgets/feedback_post_attachment_pager.dart';

class QuestionsFeedbackDetailScreen extends StatelessWidget {
  const QuestionsFeedbackDetailScreen({super.key, required this.post});
  final FeedbackPost post;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<FeedbackRemoteDataSource>(create: (_) => createFeedbackRemoteDataSource()),
      ProxyProvider<FeedbackRemoteDataSource, FeedbackRepositoryImpl>(
        update: (_, source, __) => FeedbackRepositoryImpl(source),
      ),
      ProxyProvider<FeedbackRepositoryImpl, GetFeedbackPostsUseCase>(
        update: (_, repository, __) => GetFeedbackPostsUseCase(repository),
      ),
      ChangeNotifierProvider<QuestionsFeedbackDetailController>(
        create: (context) => QuestionsFeedbackDetailController(
          context.read<GetFeedbackPostsUseCase>(),
          post,
          currentUser: AppManager.instance.currentUser,
        ),
      ),
    ],
    child: const _DetailView(),
  );
}

class _DetailView extends StatefulWidget {
  const _DetailView();
  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<QuestionsFeedbackDetailController>().initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<QuestionsFeedbackDetailController>();
    final post = controller.post;
    return AppFullScreen(
      backgroundColor: AppColors.hex111317,
      useSafeArea: false,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            if (post.attachments.isNotEmpty)
              FeedbackPostAttachmentPager(imageUrls: post.attachments),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (event) {
                  if (event.metrics.extentAfter < 200) {
                    controller.loadMoreComments();
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PostSummary(post: post),
                      const SizedBox(height: 14),
                      const AppDotDivider(color: AppColors.hex51597a, opacity: .55),
                      _ActionRow(controller: controller),
                      const SizedBox(height: 12),
                      _Comments(controller: controller),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      const Align(alignment: Alignment.centerLeft, child: AppBackButton()),
      const AppTextView.title(
        AppStrings.questionsFeedbackDetailTitle,
        color: AppColors.textPrimary,
        fontSize: 18,
      ),
    ],
  );
}

class _PostSummary extends StatelessWidget {
  const _PostSummary({required this.post});
  final FeedbackPost post;
  @override
  Widget build(BuildContext context) {
    final status = post.status.isEmpty
        ? AppStrings.questionsFeedbackRequestedStatus
        : '${post.status[0].toUpperCase()}${post.status.substring(1)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextView.title1(post.title, color: AppColors.textPrimary, fontSize: 18),
            ),
            const SizedBox(width: 10),
            _Status(label: status),
          ],
        ),
        if (post.description.isNotEmpty) ...[
          const SizedBox(height: 10),
          AppTextView.body(
            post.description,
            color: AppColors.textPrimary,
            fontSize: 13,
            height: 1.4,
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(
              post.isLiked ? Icons.favorite : Icons.favorite_border,
              color: post.isLiked ? AppColors.red1 : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 6),
            AppTextView.body1(
              '${post.likeCount} ${post.likeCount == 1 ? AppStrings.questionsFeedbackLikeSingular : AppStrings.questionsFeedbackLikePlural}',
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            const Spacer(),
            AppTextView.body1(
              '${post.commentCount} ${post.commentCount == 1 ? AppStrings.questionsFeedbackCommentSingular : AppStrings.questionsFeedbackCommentPlural}',
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.controller});
  final QuestionsFeedbackDetailController controller;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: TextButton.icon(
          onPressed: () => _like(context),
          icon: Icon(
            controller.post.isLiked ? Icons.favorite : Icons.favorite_border,
            color: controller.post.isLiked ? AppColors.red1 : AppColors.textSecondary,
            size: 20,
          ),
          label: AppTextView.body1(
            controller.post.isLiked
                ? AppStrings.questionsFeedbackLikedAction
                : AppStrings.questionsFeedbackLikeAction,
            color: controller.post.isLiked ? AppColors.red1 : AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
      Expanded(
        child: TextButton.icon(
          onPressed: controller.showComposer,
          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          label: const AppTextView.body1(
            AppStrings.questionsFeedbackCommentAction,
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
      if (controller.canModifyPost)
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          color: AppColors.hex252a40,
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
          onSelected: (value) {
            if (value == AppStrings.questionsFeedbackEditAction) {
              _showPostEditSheet(context);
            } else if (value == AppStrings.questionsFeedbackDeleteAction) {
              _confirmPostDelete(context);
            }
          },
          itemBuilder: (_) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: AppStrings.questionsFeedbackEditAction,
              child: _CommentMenuItem(
                icon: Icons.edit_outlined,
                label: AppStrings.questionsFeedbackEditAction,
              ),
            ),
            PopupMenuItem<String>(
              value: AppStrings.questionsFeedbackDeleteAction,
              child: _CommentMenuItem(
                icon: Icons.delete_outline_rounded,
                label: AppStrings.questionsFeedbackDeleteAction,
                color: AppColors.red1,
              ),
            ),
          ],
        ),
    ],
  );
  Future<void> _like(BuildContext context) async {
    final ok = await controller.toggleLike();
    if (!context.mounted || ok) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.questionsFeedbackLikeUpdateFailed)));
  }

  Future<void> _showPostEditSheet(BuildContext context) async {
    controller.startEditingPost();
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditPostBottomSheet(controller: controller),
    );

    if (didSave != true) {
      controller.cancelPostEditing();
    }
  }

  Future<void> _confirmPostDelete(BuildContext context) async {
    final didDelete = await showDialog<bool>(
      context: context,
      builder: (_) => _DeletePostDialog(controller: controller),
    );
    if (!context.mounted) {
      return;
    }
    if (didDelete == true) {
      Navigator.of(context).pop();
      return;
    }
    if (didDelete == false) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.questionsFeedbackPostDeleteFailed)));
    }
  }
}

class _Comments extends StatelessWidget {
  const _Comments({required this.controller});
  final QuestionsFeedbackDetailController controller;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textPrimary, size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: AppTextView.title1(
              AppStrings.questionsFeedbackCommentsTitle,
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
          AppTextView.body(
            '${controller.post.commentCount} ${controller.post.commentCount == 1 ? AppStrings.questionsFeedbackCommentSingular : AppStrings.questionsFeedbackCommentPlural}',
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ],
      ),
      if (controller.isComposerVisible && controller.replyParentId == null) ...[
        const SizedBox(height: 12),
        _Composer(controller: controller),
      ],
      if (controller.isCommentsLoading)
        Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: FastCircularProgressIndicator()),
        ),
      for (final comment in controller.comments)
        _Comment(
          comment: comment,
          onReply: () =>
              controller.showComposer(parentId: comment.id, parentAuthorName: comment.author?.name),
          isReplyComposerVisible:
              controller.isComposerVisible && controller.replyParentId == comment.id,
          controller: controller,
          showReplyAction: true,
        ),
      if (controller.isLoadingMoreComments)
        Padding(
          padding: EdgeInsets.all(14),
          child: Center(child: FastCircularProgressIndicator()),
        ),
    ],
  );
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller});
  final QuestionsFeedbackDetailController controller;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Avatar(
        imageUrl: CustomFunctions.resolveImageUrl(
          AppManager.instance.currentUser?.imageUrl ?? AppManager.instance.currentUser?.image,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 5),
          decoration: BoxDecoration(
            color: AppColors.hex252a40,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: controller.commentController,
                onChanged: (_) => controller.onCommentChanged(),
                minLines: 1,
                maxLines: 3,
                cursorColor: AppColors.textPrimary,
                cursorHeight: 15,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: controller.replyAuthorName == null
                      ? AppStrings.questionsFeedbackAddCommentHint
                      : AppStrings.questionsFeedbackReplyToHint(controller.replyAuthorName!),
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: controller.isSendingComment ? null : controller.cancelComposer,
                    style: _compactCommentActionStyle,
                    child: const Text(AppStrings.questionsFeedbackCancelAction),
                  ),
                  IconButton(
                    onPressed: controller.canSendComment ? () => _send(context) : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                    visualDensity: VisualDensity.compact,
                    icon: controller.isSendingComment
                        ? SizedBox(width: 18, height: 18, child: FastCircularProgressIndicator())
                        : const Icon(Icons.send_rounded, color: AppColors.secondaryColor, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );
  Future<void> _send(BuildContext context) async {
    final ok = await controller.sendComment();
    if (!context.mounted || ok) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.questionsFeedbackCommentSendFailed)));
  }
}

class _Comment extends StatelessWidget {
  const _Comment({
    required this.comment,
    required this.onReply,
    required this.isReplyComposerVisible,
    required this.controller,
    required this.showReplyAction,
  });
  final FeedbackComment comment;
  final VoidCallback onReply;
  final bool isReplyComposerVisible;
  final QuestionsFeedbackDetailController controller;
  final bool showReplyAction;
  @override
  Widget build(BuildContext context) {
    final isDeletedComment = comment.author == null;
    final canModifyComment = controller.canModifyComment(comment);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(imageUrl: CustomFunctions.resolveImageUrl(comment.author?.imageUrl)),
          const SizedBox(width: 8),
          Flexible(
            child: FractionallySizedBox(
              widthFactor: 0.8,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onLongPressStart: canModifyComment
                        ? (details) => _showCommentActions(context, details.globalPosition)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.hex252a40,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isDeletedComment) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextView.body1(
                                    comment.author!.name,
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                AppTextView.body(
                                  _timeAgo(comment.createdAt),
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                          ],
                          if (controller.isEditingComment(comment.id))
                            TextField(
                              controller: controller.editCommentController,
                              minLines: 1,
                              maxLines: 3,
                              cursorColor: AppColors.textPrimary,
                              cursorHeight: 15,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            )
                          else if (isDeletedComment)
                            Text(
                              comment.content,
                              style: const TextStyle(
                                color: AppColors.grey1,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            AppTextView.body(
                              comment.content,
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          if (controller.isEditingComment(comment.id))
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: controller.isSavingEdit
                                      ? null
                                      : controller.cancelEditing,
                                  style: _compactCommentActionStyle,
                                  child: const Text(AppStrings.questionsFeedbackCancelAction),
                                ),
                                IconButton(
                                  onPressed: controller.isSavingEdit
                                      ? null
                                      : () => _saveCommentEdit(context),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                                  icon: controller.isSavingEdit
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: FastCircularProgressIndicator(),
                                        )
                                      : const Icon(
                                          Icons.check_rounded,
                                          color: AppColors.secondaryColor,
                                          size: 20,
                                        ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (showReplyAction) const SizedBox(height: 6),
                  if (showReplyAction)
                    TextButton.icon(
                      onPressed: onReply,
                      style: _compactCommentActionStyle,
                      icon: const Icon(
                        Icons.reply_rounded,
                        color: AppColors.textSecondary,
                        size: 15,
                      ),
                      label: const AppTextView.body1(
                        AppStrings.questionsFeedbackReplyAction,
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  if (showReplyAction && isReplyComposerVisible) ...[
                    const SizedBox(height: 6),
                    _Composer(controller: controller),
                  ],
                  if (comment.replyCount > 0) const SizedBox(height: 6),
                  if (comment.replyCount > 0)
                    TextButton.icon(
                      onPressed: controller.isLoadingReplies(comment.id)
                          ? null
                          : () => controller.toggleReplies(comment.id),
                      style: _compactCommentActionStyle,
                      icon: Icon(
                        controller.isRepliesVisible(comment.id)
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                      label: AppTextView.body1(
                        controller.isRepliesVisible(comment.id)
                            ? AppStrings.questionsFeedbackHideRepliesAction
                            : AppStrings.questionsFeedbackViewRepliesAction,
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  if (controller.isRepliesVisible(comment.id) &&
                      controller.isLoadingReplies(comment.id))
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: FastCircularProgressIndicator(),
                      ),
                    ),
                  if (controller.isRepliesVisible(comment.id))
                    for (final reply in controller.repliesFor(comment.id))
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _Comment(
                          comment: reply,
                          onReply: () => controller.showComposer(parentId: reply.id),
                          isReplyComposerVisible:
                              controller.isComposerVisible && controller.replyParentId == reply.id,
                          controller: controller,
                          showReplyAction: false,
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCommentActions(BuildContext context, Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final selectedAction = await showMenu<String>(
      context: context,
      color: AppColors.hex252a40,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: const <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: AppStrings.questionsFeedbackEditAction,
          child: _CommentMenuItem(
            icon: Icons.edit_outlined,
            label: AppStrings.questionsFeedbackEditAction,
          ),
        ),
        PopupMenuItem<String>(
          value: AppStrings.questionsFeedbackDeleteAction,
          child: _CommentMenuItem(
            icon: Icons.delete_outline_rounded,
            label: AppStrings.questionsFeedbackDeleteAction,
            color: AppColors.red1,
          ),
        ),
      ],
    );

    if (!context.mounted || selectedAction == null) {
      return;
    }
    if (selectedAction == AppStrings.questionsFeedbackEditAction) {
      controller.startEditing(comment);
    } else if (selectedAction == AppStrings.questionsFeedbackDeleteAction) {
      _confirmDelete(context, controller, comment.id);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    QuestionsFeedbackDetailController controller,
    String commentId,
  ) async {
    final didDelete = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteCommentDialog(controller: controller, commentId: commentId),
    );
    if (!context.mounted || didDelete != false) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(AppStrings.questionsFeedbackCommentDeleteFailed)),
      );
  }

  Future<void> _saveCommentEdit(BuildContext context) async {
    final didSave = await controller.saveEditing();
    if (!context.mounted || didSave) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.questionsFeedbackCommentEditFailed)));
  }
}

class _CommentMenuItem extends StatelessWidget {
  const _CommentMenuItem({
    required this.icon,
    required this.label,
    this.color = AppColors.textPrimary,
  });
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      AppTextView.body1(label, color: color, fontSize: 13),
    ],
  );
}

class _EditPostBottomSheet extends StatelessWidget {
  const _EditPostBottomSheet({required this.controller});

  final QuestionsFeedbackDetailController controller;

  Future<void> _save(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final didSave = await controller.savePostEditing();
    if (!context.mounted) {
      return;
    }
    if (didSave) {
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.questionsFeedbackPostEditFailed)));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
      return PopScope<Object?>(
        canPop: !controller.isSavingPostEdit,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.fieldBorder.withValues(alpha: .32),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const AppTextView.body1(
                      AppStrings.questionsFeedbackEditPostTitle,
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 14),
                    _PostEditField(
                      controller: controller.editPostTitleController,
                      label: AppStrings.questionsFeedbackPostTitleLabel,
                      maxLines: 1,
                      onChanged: controller.onPostEditChanged,
                    ),
                    const SizedBox(height: 12),
                    _PostEditField(
                      controller: controller.editPostDescriptionController,
                      label: AppStrings.questionsFeedbackDescriptionLabel,
                      minLines: 3,
                      maxLines: 5,
                      onChanged: controller.onPostEditChanged,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: controller.isSavingPostEdit
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: const AppTextView.body1(
                            AppStrings.questionsFeedbackCancelAction,
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: controller.canSavePostEdit ? () => _save(context) : null,
                          child: controller.isSavingPostEdit
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: FastCircularProgressIndicator(),
                                )
                              : const AppTextView.body1(
                                  AppStrings.questionsFeedbackSaveAction,
                                  color: AppColors.secondaryColor,
                                  fontSize: 13,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _PostEditField extends StatelessWidget {
  const _PostEditField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.minLines,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final int? minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    minLines: minLines,
    maxLines: maxLines,
    cursorColor: AppColors.textPrimary,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      filled: true,
      fillColor: AppColors.hex252a40,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

class _DeleteCommentDialog extends StatelessWidget {
  const _DeleteCommentDialog({required this.controller, required this.commentId});

  final QuestionsFeedbackDetailController controller;
  final String commentId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return AppConfirmationDialog(
          title: AppStrings.questionsFeedbackDeleteCommentTitle,
          description: AppStrings.questionsFeedbackDeleteCommentMessage,
          confirmText: AppStrings.questionsFeedbackConfirmDeleteAction,
          cancelText: AppStrings.questionsFeedbackCancelAction,
          isConfirmLoading: controller.isDeletingComment(commentId),
          onCancelCallback: () async {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          onConfirmCallback: () async {
            final didDelete = await controller.deleteComment(commentId);
            if (context.mounted) {
              Navigator.of(context).pop(didDelete);
            }
          },
        );
      },
    );
  }
}

class _DeletePostDialog extends StatelessWidget {
  const _DeletePostDialog({required this.controller});

  final QuestionsFeedbackDetailController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => AppConfirmationDialog(
      title: AppStrings.questionsFeedbackDeletePostTitle,
      description: AppStrings.questionsFeedbackDeletePostMessage,
      confirmText: AppStrings.questionsFeedbackConfirmDeleteAction,
      cancelText: AppStrings.questionsFeedbackCancelAction,
      isConfirmLoading: controller.isDeletingPost,
      onCancelCallback: () async {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      onConfirmCallback: () async {
        final didDelete = await controller.deletePost();
        if (context.mounted) {
          Navigator.of(context).pop(didDelete);
        }
      },
    ),
  );
}

String _timeAgo(String createdAt) {
  final milliseconds = int.tryParse(createdAt);
  if (milliseconds == null) {
    return AppStrings.questionsFeedbackJustNow;
  }
  final difference = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(milliseconds));
  if (difference.inMinutes < 1) {
    return AppStrings.questionsFeedbackJustNow;
  }
  if (difference.inHours < 1) {
    return AppStrings.questionsFeedbackMinutesAgo(difference.inMinutes);
  }
  if (difference.inDays < 1) {
    return AppStrings.questionsFeedbackHoursAgo(difference.inHours);
  }
  return AppStrings.questionsFeedbackDaysAgo(difference.inDays);
}

final ButtonStyle _compactCommentActionStyle = TextButton.styleFrom(
  minimumSize: Size.zero,
  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  visualDensity: VisualDensity.compact,
);

class _Avatar extends StatelessWidget {
  const _Avatar({this.imageUrl});
  final String? imageUrl;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 17,
    backgroundColor: imageUrl == null ? AppColors.secondaryColor : AppColors.hex252a40,
    backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
    child: imageUrl == null
        ? const Text(
            'U',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          )
        : null,
  );
}

class _Status extends StatelessWidget {
  const _Status({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.orange2.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: AppColors.orange2.withValues(alpha: .55)),
    ),
    child: AppTextView.body1(
      label,
      color: AppColors.orange2,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
  );
}

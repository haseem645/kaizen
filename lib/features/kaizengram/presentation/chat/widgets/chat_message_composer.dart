import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/custom_functions.dart';
import '../../../../../core/widgets/app_text_view.dart';
import '../../kaizengram_message_attachment.dart';
import '../../widgets/kaizengram_full_screen_attachment_view.dart';
import '../chat_strings.dart';
import '../providers/kaizengram_chat_controller.dart';
import '../../widgets/kaizengram_link_utils.dart';
import '../../widgets/kaizengram_link_preview_card.dart';
import 'chat_mention_text.dart';
import 'chat_mention_text_editing_controller.dart';
import 'chat_user_initial_avatar.dart';
import 'chat_video_preview.dart';

const double _chatComposerCornerRadius = 12;
const double _chatComposerControlHeight = 48;
const double _chatComposerActionWidth = 48;
const Color _chatComposerSurfaceColor = Color(0xFF24283D);

//////
class KaizengramChatMessageComposer extends StatefulWidget {
  const KaizengramChatMessageComposer({super.key});

  @override
  State<KaizengramChatMessageComposer> createState() =>
      _KaizengramChatMessageComposerState();
}

class _KaizengramChatMessageComposerState
    extends State<KaizengramChatMessageComposer> {
  late final ChatMentionTextEditingController _textController;
  _MentionQuery? _activeMentionQuery;

  @override
  void initState() {
    super.initState();
    _textController = ChatMentionTextEditingController(
      users: context.read<KaizengramChatController>().users,
      text: context.read<KaizengramChatController>().draftMessage,
    );
    _textController.addListener(_handleTextControllerChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_handleTextControllerChanged);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<KaizengramChatController>();
    final canSendMessage = controller.canSendMessage;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final draftAttachments = controller.draftAttachments;
    final isPickingDraftMedia = controller.isPickingDraftMedia;
    _textController.users = controller.users;
    final draftText = _textController.text;
    final hasDraftLink = kaizengramFirstLinkInText(draftText) != null;
    final replyingTo = controller.replyingTo;
    final mentionSuggestions = _activeMentionQuery == null
        ? const <KaizengramChatUser>[]
        : controller.mentionSuggestions(_activeMentionQuery!.query);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1E27),
          border: Border(
            top: BorderSide(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (replyingTo != null) ...<Widget>[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF24283D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 4,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AppTextView.body3(
                            '${KaizengramChatStrings.replyingToLabel} ${replyingTo.sender.name}',
                            color: AppColors.blue,
                            fontWeight: FontWeight.w700,
                          ),
                          const SizedBox(height: 4),
                          ChatMentionText(
                            text: replyingTo.previewText,
                            users: controller.users,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            defaultStyle: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: controller.cancelReply,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (draftAttachments.isNotEmpty) ...<Widget>[
              _DraftMediaPreviewStrip(
                attachments: draftAttachments,
                onOpenAttachment: _openDraftMediaViewer,
                onRemoveAttachment: controller.removeDraftMedia,
              ),
              const SizedBox(height: 10),
            ],
            if (_activeMentionQuery != null &&
                mentionSuggestions.isNotEmpty) ...<Widget>[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF24283D),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.06),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: mentionSuggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final user = mentionSuggestions[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _insertMention(user),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              children: <Widget>[
                                ChatUserInitialAvatar(
                                  label: kaizengramChatInitialFor(user.name),
                                  accentColor:
                                      kaizengramChatAccentColorForIndex(index),
                                  size: 36,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user.email,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            if (hasDraftLink) ...<Widget>[
              KaizengramTextLinkPreview(text: draftText, topSpacing: 0),
              const SizedBox(height: 10),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _ComposerIconButton(
                  onTap: isPickingDraftMedia ? null : _handlePickMedia,
                  child: isPickingDraftMedia
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textPrimary,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.attach_file_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: _chatComposerControlHeight,
                    ),
                    decoration: BoxDecoration(
                      color: _chatComposerSurfaceColor,
                      borderRadius: BorderRadius.circular(
                        _chatComposerCornerRadius,
                      ),
                      border: Border.all(
                        color: AppColors.textPrimary.withValues(alpha: 0.08),
                      ),
                    ),
                    child: TextField(
                      controller: _textController,
                      onChanged: controller.updateDraftMessage,
                      maxLines: 4,
                      minLines: 1,
                      textAlignVertical: TextAlignVertical.center,
                      cursorHeight: 16,
                      cursorColor: AppColors.textPrimary,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: KaizengramChatStrings.messageHint,
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(
                    _chatComposerCornerRadius,
                  ),
                  onTap: canSendMessage ? _handleSendMessage : null,
                  child: Container(
                    width: _chatComposerActionWidth,
                    height: _chatComposerControlHeight,
                    decoration: BoxDecoration(
                      color: _chatComposerSurfaceColor,
                      borderRadius: BorderRadius.circular(
                        _chatComposerCornerRadius,
                      ),
                      border: Border.all(
                        color: canSendMessage
                            ? AppColors.secondaryColor.withValues(alpha: 0.55)
                            : AppColors.textPrimary.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: canSendMessage
                          ? AppColors.secondaryColor
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePickMedia() async {
    final source = await KaizengramMessageAttachmentPicker.pickSource(context);
    if (!mounted || source == null) {
      return;
    }

    final result = await context
        .read<KaizengramChatController>()
        .pickDraftMediaForSource(source: source);
    if (!mounted) {
      return;
    }

    if (result == KaizengramChatDraftMediaPickResult.failed) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(KaizengramChatStrings.pickMediaError)),
        );
      return;
    }

    if (result == KaizengramChatDraftMediaPickResult.limitReached) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(KaizengramChatStrings.mediaLimitError)),
        );
    }
  }

  void _handleSendMessage() {
    final controller = context.read<KaizengramChatController>();
    controller.updateDraftMessage(_textController.text);
    final didSend = controller.sendMessage();
    if (!didSend) {
      return;
    }

    _textController.clear();
    setState(() => _activeMentionQuery = null);
  }

  void _handleTextControllerChanged() {
    final nextQuery = _findMentionQuery(
      _textController.text,
      _textController.selection,
    );
    if (_activeMentionQuery == nextQuery) {
      return;
    }
    setState(() => _activeMentionQuery = nextQuery);
  }

  void _insertMention(KaizengramChatUser user) {
    final mentionQuery = _activeMentionQuery;
    if (mentionQuery == null) {
      return;
    }

    final mentionText = '@${user.name} ';
    final nextText = _textController.text.replaceRange(
      mentionQuery.start,
      mentionQuery.end,
      mentionText,
    );
    final nextSelectionOffset = mentionQuery.start + mentionText.length;
    _textController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextSelectionOffset),
    );
    context.read<KaizengramChatController>().updateDraftMessage(nextText);
    setState(() => _activeMentionQuery = null);
  }

  void _openDraftMediaViewer(int index) {
    final attachments = context
        .read<KaizengramChatController>()
        .draftAttachments;
    if (attachments.isEmpty) {
      return;
    }

    final selectedAttachment = attachments[index];

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KaizengramFullScreenAttachmentView(
          attachments: attachments,
          initialIndex: index,
          autoPlayInitialVideo: selectedAttachment.isVideo,
        ),
      ),
    );
  }
}

class _DraftMediaPreviewStrip extends StatelessWidget {
  const _DraftMediaPreviewStrip({
    required this.attachments,
    required this.onOpenAttachment,
    required this.onRemoveAttachment,
  });

  final List<KaizengramMessageAttachment> attachments;
  final ValueChanged<int> onOpenAttachment;
  final ValueChanged<String> onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    const spacing = 8.0;
    const mediaCardSize = 92.0;
    const pdfCardWidth = 220.0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF24283D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppTextView.body4(
            KaizengramChatStrings.selectedMediaLabel(
              attachments.length,
              KaizengramChatController.maxMessageMediaCount,
            ),
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: mediaCardSize,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List<Widget>.generate(attachments.length * 2 - 1, (
                  index,
                ) {
                  if (index.isOdd) {
                    return const SizedBox(width: spacing);
                  }

                  final attachmentIndex = index ~/ 2;
                  final attachment = attachments[attachmentIndex];
                  return _DraftMediaPreviewCard(
                    attachment: attachment,
                    width: attachment.isPdf ? pdfCardWidth : mediaCardSize,
                    height: mediaCardSize,
                    onOpen: () => onOpenAttachment(attachmentIndex),
                    onRemove: () => onRemoveAttachment(attachment.path),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftMediaPreviewCard extends StatelessWidget {
  const _DraftMediaPreviewCard({
    required this.attachment,
    required this.width,
    required this.height,
    required this.onOpen,
    required this.onRemove,
  });

  final KaizengramMessageAttachment attachment;
  final double width;
  final double height;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: const Color(0xFF111317),
                child: attachment.isPdf
                    ? _DraftPdfPreviewCard(
                        attachment: attachment,
                        onOpen: onOpen,
                      )
                    : attachment.isVideo
                    ? ChatVideoPreview(
                        videoPath: attachment.path,
                        maxHeight: height,
                        muted: true,
                        playButtonSize: 30,
                        playIconSize: 16,
                        onTapOverride: onOpen,
                        onOpenFullScreen: onOpen,
                      )
                    : Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onOpen,
                          child: attachment.isNetworkPath
                              ? Image.network(
                                  attachment.path,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const _DraftMediaFallback(),
                                )
                              : Image.file(
                                  File(attachment.path),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const _DraftMediaFallback(),
                                ),
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.44),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftPdfPreviewCard extends StatelessWidget {
  const _DraftPdfPreviewCard({required this.attachment, required this.onOpen});

  final KaizengramMessageAttachment attachment;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.secondaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  CustomFunctions.fileNameFromPath(
                    attachment.path,
                    fallback: KaizengramChatStrings.documentMessageLabel,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftMediaFallback extends StatelessWidget {
  const _DraftMediaFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.broken_image_outlined,
        color: AppColors.textSecondary,
        size: 26,
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(_chatComposerCornerRadius),
      onTap: onTap,
      child: Container(
        width: _chatComposerActionWidth,
        height: _chatComposerControlHeight,
        decoration: BoxDecoration(
          color: _chatComposerSurfaceColor,
          borderRadius: BorderRadius.circular(_chatComposerCornerRadius),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

_MentionQuery? _findMentionQuery(String text, TextSelection selection) {
  if (!selection.isValid) {
    return null;
  }

  final cursor = selection.baseOffset;
  if (cursor < 0 || cursor > text.length) {
    return null;
  }

  final beforeCursor = text.substring(0, cursor);
  final atIndex = beforeCursor.lastIndexOf('@');
  if (atIndex == -1) {
    return null;
  }
  if (atIndex > 0) {
    final prefix = beforeCursor[atIndex - 1];
    final canStartMention = prefix == ' ' || prefix == '\n' || prefix == '\t';
    if (!canStartMention) {
      return null;
    }
  }

  final query = beforeCursor.substring(atIndex + 1);
  if (query.contains(RegExp(r'\s'))) {
    return null;
  }

  return _MentionQuery(start: atIndex, end: cursor, query: query);
}

class _MentionQuery {
  const _MentionQuery({
    required this.start,
    required this.end,
    required this.query,
  });

  final int start;
  final int end;
  final String query;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is _MentionQuery &&
        other.start == start &&
        other.end == end &&
        other.query == query;
  }

  @override
  int get hashCode => Object.hash(start, end, query);
}

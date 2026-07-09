import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/custom_functions.dart';
import '../../../../../core/widgets/app_text_view.dart';
import '../chat_strings.dart';
import '../providers/kaizengram_chat_controller.dart';
import 'chat_user_initial_avatar.dart';

class ShareKaizengramPostBottomSheet extends StatelessWidget {
  const ShareKaizengramPostBottomSheet({super.key, required this.controller});

  final KaizengramChatController controller;

  @override
  Widget build(BuildContext context) {
    final directMessageTargets = controller.shareDirectMessageTargets;
    final hasDestinations =
        controller.channels.isNotEmpty || directMessageTargets.isNotEmpty;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const AppTextView.body1(
              KaizengramChatStrings.sharePostTitle,
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 6),
            const AppTextView.body2(
              KaizengramChatStrings.sharePostSubtitle,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.58,
              ),
              child: hasDestinations
                  ? ListView(
                      shrinkWrap: true,
                      children: <Widget>[
                        if (controller.channels.isNotEmpty) ...<Widget>[
                          const _ShareSectionHeader(
                            title: KaizengramChatStrings.channelsTitle,
                          ),
                          const SizedBox(height: 8),
                          ...controller.channels.map(
                            (channel) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ShareChannelTile(
                                channel: channel,
                                onTap: () => Navigator.of(context).pop(
                                  KaizengramChatConversationTarget.channel(
                                    channel.name,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (directMessageTargets.isNotEmpty) ...<Widget>[
                          if (controller.channels.isNotEmpty)
                            const SizedBox(height: 8),
                          const _ShareSectionHeader(
                            title: KaizengramChatStrings.directMessagesTitle,
                          ),
                          const SizedBox(height: 8),
                          ...List<
                            Widget
                          >.generate(directMessageTargets.length, (index) {
                            final user = directMessageTargets[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ShareDirectMessageTile(
                                user: user,
                                index: index,
                                onTap: () => Navigator.of(context).pop(
                                  KaizengramChatConversationTarget.directMessage(
                                    user.email,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF24283D),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.06),
                        ),
                      ),
                      child: const AppTextView.body3(
                        KaizengramChatStrings.sharePostEmptyState,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareSectionHeader extends StatelessWidget {
  const _ShareSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppTextView.body2(
      title,
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w700,
    );
  }
}

class _ShareChannelTile extends StatelessWidget {
  const _ShareChannelTile({required this.channel, required this.onTap});

  final KaizengramChatChannel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF24283D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: <Widget>[
              _ShareChannelAvatar(channel: channel),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppTextView.body2(
                      '#${channel.name}',
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 2),
                    const AppTextView.body3(
                      KaizengramChatStrings.channelLabel,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareDirectMessageTile extends StatelessWidget {
  const _ShareDirectMessageTile({
    required this.user,
    required this.index,
    required this.onTap,
  });

  final KaizengramChatUser user;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF24283D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: <Widget>[
              ChatUserInitialAvatar(
                label: kaizengramChatInitialFor(user.name),
                accentColor: kaizengramChatAccentColorForIndex(index),
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppTextView.body2(
                      user.name,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 2),
                    AppTextView.body3(
                      user.email,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareChannelAvatar extends StatelessWidget {
  const _ShareChannelAvatar({required this.channel});

  final KaizengramChatChannel channel;

  @override
  Widget build(BuildContext context) {
    final imagePath = channel.imagePath?.trim();
    if (imagePath != null && imagePath.isNotEmpty) {
      final networkUrl = CustomFunctions.resolveNetworkUrl(imagePath);
      final ImageProvider<Object> imageProvider = networkUrl != null
          ? NetworkImage(networkUrl)
          : FileImage(File(imagePath));
      return CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFF24283D),
        backgroundImage: imageProvider,
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E27),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.06),
        ),
      ),
      child: const Icon(
        Icons.tag_rounded,
        color: AppColors.secondaryColor,
        size: 18,
      ),
    );
  }
}

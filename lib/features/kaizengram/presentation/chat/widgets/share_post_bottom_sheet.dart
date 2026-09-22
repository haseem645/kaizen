import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/utils/custom_functions.dart';
import '../../../../../core/widgets/app_text_view.dart';
import '../../../groups/presentation/pages/kaizengram_groups_screen.dart';
import '../providers/kaizengram_chat_controller.dart';
import 'chat_module_ui.dart';
import 'chat_user_initial_avatar.dart';

enum KaizengramShareDestinationType { chat, group }

class KaizengramShareDestination {
  const KaizengramShareDestination.chat({required this.conversation})
    : type = KaizengramShareDestinationType.chat,
      groupId = null;

  const KaizengramShareDestination.group({required this.groupId})
    : type = KaizengramShareDestinationType.group,
      conversation = null;

  final KaizengramShareDestinationType type;
  final KaizengramChatConversationTarget? conversation;
  final String? groupId;
}

class ShareKaizengramPostBottomSheet extends StatelessWidget {
  const ShareKaizengramPostBottomSheet({
    super.key,
    required this.controller,
    required this.groupDestinations,
  });

  final KaizengramChatController controller;
  final List<KaizengramGroupShareDestination> groupDestinations;

  @override
  Widget build(BuildContext context) {
    final directMessageTargets = controller.shareDirectMessageTargets;
    final hasDestinations =
        groupDestinations.isNotEmpty ||
        controller.channels.isNotEmpty ||
        directMessageTargets.isNotEmpty;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: kaizengramChatScreenSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const KaizengramChatSheetHandle(),
            const SizedBox(height: 18),
            const AppTextView.body1(
              AppStrings.sharePostTitle,
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            const SizedBox(height: 6),
            const AppTextView.body2(
              AppStrings.sharePostSubtitle,
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
                        if (groupDestinations.isNotEmpty) ...<Widget>[
                          const _ShareSectionHeader(
                            title: AppStrings.groupsTitle,
                          ),
                          const SizedBox(height: 8),
                          ...groupDestinations.map(
                            (group) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ShareGroupTile(
                                group: group,
                                onTap: () => Navigator.of(context).pop(
                                  KaizengramShareDestination.group(
                                    groupId: group.id,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (controller.channels.isNotEmpty) ...<Widget>[
                          if (groupDestinations.isNotEmpty)
                            const SizedBox(height: 8),
                          const _ShareSectionHeader(
                            title: AppStrings.channelsTitle,
                          ),
                          const SizedBox(height: 8),
                          ...controller.channels.map(
                            (channel) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ShareChannelTile(
                                channel: channel,
                                onTap: () => Navigator.of(context).pop(
                                  KaizengramShareDestination.chat(
                                    conversation:
                                        KaizengramChatConversationTarget.channel(
                                          channel.name,
                                        ),
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
                            title: AppStrings.directMessagesTitle,
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
                                  KaizengramShareDestination.chat(
                                    conversation:
                                        KaizengramChatConversationTarget.directMessage(
                                          user.email,
                                        ),
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
                        color: kaizengramChatCardSurfaceColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const AppTextView.body3(
                        AppStrings.sharePostEmptyState,
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
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    );
  }
}

class _ShareGroupTile extends StatelessWidget {
  const _ShareGroupTile({required this.group, required this.onTap});

  final KaizengramGroupShareDestination group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: kaizengramChatCardSurfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: <Widget>[
              _ShareGroupAvatar(group: group),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppTextView.body2(
                      group.name,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 2),
                    AppTextView.body4(
                      AppStrings.authorMeta(
                        group.privacyLabel,
                        AppStrings.memberCountLabel(group.memberCount),
                      ),
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
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
            color: kaizengramChatCardSurfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
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
                      AppStrings.channelLabel,
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
            color: kaizengramChatCardSurfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
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

class _ShareGroupAvatar extends StatelessWidget {
  const _ShareGroupAvatar({required this.group});

  final KaizengramGroupShareDestination group;

  @override
  Widget build(BuildContext context) {
    final imagePath = group.imagePath?.trim();
    if (imagePath != null && imagePath.isNotEmpty) {
      final ImageProvider<Object> imageProvider;
      if (CustomFunctions.isAssetImagePath(imagePath)) {
        imageProvider = AssetImage(imagePath);
      } else {
        final networkUrl = CustomFunctions.resolveNetworkUrl(imagePath);
        imageProvider = networkUrl != null
            ? NetworkImage(networkUrl)
            : FileImage(File(imagePath));
      }

      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.surfaceDark3,
        backgroundImage: imageProvider,
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.surfaceDark3,
      backgroundImage: NetworkImage(group.imageUrl),
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
        backgroundColor: AppColors.surfaceDark3,
        backgroundImage: imageProvider,
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.hex1b1e27,
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

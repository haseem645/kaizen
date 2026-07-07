import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_text_view.dart';
import '../chat_strings.dart';
import '../providers/kaizengram_chat_controller.dart';
import '../widgets/chat_user_initial_avatar.dart';
import '../widgets/create_channel_bottom_sheet.dart';
import 'kaizengram_chat_screen.dart';

class KaizengramChannelsScreen extends StatelessWidget {
  const KaizengramChannelsScreen({super.key, this.controller});

  final KaizengramChatController? controller;

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return ChangeNotifierProvider<KaizengramChatController>.value(
        value: controller!,
        child: const _KaizengramChannelsView(),
      );
    }

    return ChangeNotifierProvider<KaizengramChatController>(
      create: (_) => KaizengramChatController(),
      child: const _KaizengramChannelsView(),
    );
  }
}

class _KaizengramChannelsView extends StatelessWidget {
  const _KaizengramChannelsView();

  static const Color _screenBackground = Color(0xFF111317);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<KaizengramChatController>();

    return Scaffold(
      backgroundColor: _screenBackground,
      appBar: AppBar(
        backgroundColor: _screenBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const AppTextView.body1(
          KaizengramChatStrings.chatHomeTitle,
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: <Widget>[
          _SectionHeader(
            title: KaizengramChatStrings.channelsTitle,
            actionIcon: Icons.add_rounded,
            onActionTap: () => _showCreateChannelSheet(context),
          ),
          const SizedBox(height: 8),
          ...controller.channels.map(
            (channel) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ChannelListTile(
                channel: channel,
                onTap: () => _openChannel(context, channel),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionHeader(
            title: KaizengramChatStrings.directMessagesTitle,
            actionIcon: Icons.add_rounded,
            onActionTap: () => _showDirectMessageSheet(context),
          ),
          const SizedBox(height: 8),
          if (controller.directMessageUsers.isEmpty)
            const _EmptyDirectMessagesCard()
          else
            ...controller.directMessageUsers.map(
              (user) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DirectMessageListTile(
                  user: user,
                  onTap: () => _openDirectMessage(context, user.email),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showCreateChannelSheet(BuildContext context) async {
    final controller = context.read<KaizengramChatController>();
    final createdChannel = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateChannelBottomSheet(controller: controller),
    );

    if (createdChannel == null || createdChannel.isEmpty || !context.mounted) {
      return;
    }

    await _openChannel(context, createdChannel);
  }

  Future<void> _showDirectMessageSheet(BuildContext context) async {
    final controller = context.read<KaizengramChatController>();
    final selectedEmail = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StartDirectMessageBottomSheet(controller: controller),
    );

    if (selectedEmail == null || !context.mounted) {
      return;
    }

    await _openDirectMessage(context, selectedEmail);
  }

  Future<void> _openChannel(BuildContext context, String channelName) {
    final controller = context.read<KaizengramChatController>();
    controller.selectChannel(channelName);
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => KaizengramChatScreen(controller: controller)),
    );
  }

  Future<void> _openDirectMessage(BuildContext context, String userEmail) {
    final controller = context.read<KaizengramChatController>();
    controller.openDirectMessage(userEmail);
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => KaizengramChatScreen(controller: controller)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actionIcon, required this.onActionTap});

  final String title;
  final IconData actionIcon;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: AppTextView.body2(
            title,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        InkWell(
          onTap: onActionTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF1B1E27),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.08)),
            ),
            child: Icon(actionIcon, color: AppColors.textPrimary, size: 18),
          ),
        ),
      ],
    );
  }
}

class _ChannelListTile extends StatelessWidget {
  const _ChannelListTile({required this.channel, required this.onTap});

  final String channel;
  final VoidCallback onTap;
  //
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1E27),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.tag_rounded, color: AppColors.secondaryColor, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppTextView.body2(
                          '#$channel',
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class _DirectMessageListTile extends StatelessWidget {
  const _DirectMessageListTile({required this.user, required this.onTap});

  final KaizengramChatUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1E27),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: <Widget>[
              ChatUserInitialAvatar(
                label: kaizengramChatInitialFor(user.name),
                accentColor: AppColors.blue,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppTextView.body2(
                      user.name,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 1),
                    AppTextView.body4(
                      user.email,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDirectMessagesCard extends StatelessWidget {
  const _EmptyDirectMessagesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E27),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: const AppTextView.body3(
        KaizengramChatStrings.noDirectMessages,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _StartDirectMessageBottomSheet extends StatelessWidget {
  const _StartDirectMessageBottomSheet({required this.controller});

  final KaizengramChatController controller;

  @override
  Widget build(BuildContext context) {
    final candidates = controller.directMessageCandidates;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
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
              KaizengramChatStrings.startDirectMessageTitle,
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 6),
            const AppTextView.body2(
              KaizengramChatStrings.startDirectMessageSubtitle,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.46),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: candidates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = candidates[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).pop(user.email),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF24283D),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.06)),
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
                                  AppTextView.body4(
                                    user.email,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_view.dart';
import '../chat_strings.dart';
import '../providers/kaizengram_chat_controller.dart';
import 'add_people_dialog.dart';
import 'chat_user_initial_avatar.dart';
import 'remove_user_confirmation_dialog.dart';

class KaizengramChatUsersBottomSheet extends StatelessWidget {
  const KaizengramChatUsersBottomSheet({super.key, required this.controller});

  final KaizengramChatController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final channelUsers = controller.currentChannelUsers;

        return SafeArea(
          top: false,
          bottom: false,
          child: Container(
            height: MediaQuery.sizeOf(context).height * 0.58,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AppTextView.body1(
                    KaizengramChatStrings.usersTitle,
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: channelUsers.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _AddPeopleRow(controller: controller);
                      }

                      final user = channelUsers[index - 1];
                      final isCurrentUser =
                          user.email == controller.currentUser.email;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF24283D),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.06,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            ChatUserInitialAvatar(
                              label: kaizengramChatInitialFor(user.name),
                              accentColor: kaizengramChatAccentColorForIndex(
                                index,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  AppTextView.body2(
                                    user.email,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  const SizedBox(height: 4),
                                  AppTextView.body3(
                                    user.name,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ],
                              ),
                            ),
                            if (!isCurrentUser) ...<Widget>[
                              const SizedBox(width: 12),
                              InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => _confirmRemoveUser(context, user),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.red1.withValues(
                                      alpha: 0.16,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.remove_rounded,
                                    color: AppColors.red1,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                AppButton(
                  text: KaizengramChatStrings.actionClose,
                  onPressed: () => Navigator.of(context).pop(),
                  borderRadius: 14,
                  minimumHeight: 48,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmRemoveUser(
    BuildContext context,
    KaizengramChatUser user,
  ) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (_) => RemoveUserConfirmationDialog(user: user),
    );
    if (shouldRemove != true || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final didRemove = controller.removeUserFromCurrentChannel(user);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            didRemove
                ? KaizengramChatStrings.userRemovedSnackBar(user.email)
                : KaizengramChatStrings.cannotRemoveCurrentUserError,
          ),
        ),
      );
  }
}

class _AddPeopleRow extends StatelessWidget {
  const _AddPeopleRow({required this.controller});

  final KaizengramChatController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showAddPeopleDialog(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF24283D),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.blue.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppColors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: AppTextView.body2(
                  KaizengramChatStrings.addPeopleLabel,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddPeopleDialog(BuildContext context) async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => AddPeopleDialog(controller: controller),
    );
    if (email == null || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final addedEmail = controller.addUserToCurrentChannel(email);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            addedEmail.isEmpty
                ? KaizengramChatStrings.duplicateChannelUserError
                : KaizengramChatStrings.userAddedSnackBar(addedEmail),
          ),
        ),
      );
  }
}

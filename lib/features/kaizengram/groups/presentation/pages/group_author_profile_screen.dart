import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/widgets/app_full_screen.dart';
import '../../../../../core/widgets/app_text_view.dart';
import '../widgets/group_author_profile_widgets.dart';

class GroupAuthorProfileScreen extends StatelessWidget {
  const GroupAuthorProfileScreen({
    required this.groupName,
    required this.groupCategory,
    required this.groupPrivacyLabel,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.authorRole,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.gender,
    required this.timeLabel,
    required this.postContent,
    super.key,
  });

  final String groupName;
  final String groupCategory;
  final String groupPrivacyLabel;
  final String authorName;
  final String authorAvatarUrl;
  final String authorRole;
  final String email;
  final String phone;
  final String dateOfBirth;
  final String gender;
  final String timeLabel;
  final String postContent;

  @override
  Widget build(BuildContext context) {
    return AppFullScreen(
      backgroundColor: const Color(0xFF111317),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Expanded(
                  child: AppTextView.body1(
                    AppStrings.profileScreenTitle,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: <Widget>[
                GroupAuthorProfileHeroCard(
                  authorName: authorName,
                  authorAvatarUrl: authorAvatarUrl,
                  authorRole: authorRole,
                  timeLabel: timeLabel,
                ),
                const SizedBox(height: 16),
                GroupAuthorProfileInfoCard(
                  title: AppStrings.profileGroupHeader,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppTextView.body2(
                        AppStrings.profileGroupValue(groupName),
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 8),
                      AppTextView.body4(
                        AppStrings.privacyMeta(
                          groupPrivacyLabel,
                          groupCategory,
                        ),
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GroupAuthorProfileInfoCard(
                  title: AppStrings.profileContactHeader,
                  child: Column(
                    children: <Widget>[
                      GroupAuthorProfileDetailRow(
                        icon: Icons.alternate_email_rounded,
                        label: AppStrings.profileEmailLabel,
                        value: email,
                      ),
                      const SizedBox(height: 12),
                      GroupAuthorProfileDetailRow(
                        icon: Icons.phone_outlined,
                        label: AppStrings.profilePhoneLabel,
                        value: phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GroupAuthorProfileInfoCard(
                  title: AppStrings.profilePersonalHeader,
                  child: Column(
                    children: <Widget>[
                      GroupAuthorProfileDetailRow(
                        icon: Icons.cake_outlined,
                        label: AppStrings.profileDateOfBirthLabel,
                        value: dateOfBirth,
                      ),
                      const SizedBox(height: 12),
                      GroupAuthorProfileDetailRow(
                        icon: Icons.person_outline_rounded,
                        label: AppStrings.profileGenderLabel,
                        value: gender,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GroupAuthorProfileInfoCard(
                  title: AppStrings.profileRecentPostHeader,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppTextView.body4(
                        AppStrings.profileRecentPostMeta(groupName, timeLabel),
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      const SizedBox(height: 10),
                      AppTextView.body2(
                        postContent,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GroupAuthorProfileInfoCard(
                  title: AppStrings.profileAboutHeader,
                  child: AppTextView.body2(
                    AppStrings.profileAboutSummary(
                      authorName,
                      groupName,
                      groupCategory,
                    ),
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

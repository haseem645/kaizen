import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/audit_member.dart';

class AuditMemberCard extends StatelessWidget {
  const AuditMemberCard({
    super.key,
    required this.member,
    this.onAuditTap,
    this.actionLabel = AppStrings.checkInTitle,
    this.showLastCheckIn = true,
  });

  final AuditMember member;
  final VoidCallback? onAuditTap;
  final String actionLabel;
  final bool showLastCheckIn;

  @override
  Widget build(BuildContext context) {
    final profileName = _resolveProfileName(member.name);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextView.body(
                        member.roleTitle,
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      AppTextView.body3(
                        profileName,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      if (showLastCheckIn) ...[
                        const SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 12),
                            children: [
                              TextSpan(
                                text: 'Last Check-in: ',
                                style: TextStyle(
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.75,
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: member.lastAuditLabel,
                                style: const TextStyle(
                                  color: AppColors.secondaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (member.profiles.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _ProfilesRow(profiles: member.profiles),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _MemberAvatar(
                label: member.avatarLabel,
                name: member.name,
                imageUrl: member.avatarImageUrl,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  value: member.overallScore.toStringAsFixed(1),
                  label: AppStrings.auditOverallScore,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  value: '${member.confidenceLevel}%',
                  label: AppStrings.auditConfidenceLevel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AuditActionButton(
                  onTap: onAuditTap,
                  label: actionLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _resolveProfileName(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return 'No Profile Allocated';
    }

    return trimmedValue;
  }
}

class _ProfilesRow extends StatelessWidget {
  const _ProfilesRow({required this.profiles});

  final List<AuditMemberProfile> profiles;
  static const double _avatarSize = 26;
  static const double _overlapOffset = 18;

  @override
  Widget build(BuildContext context) {
    final visibleProfiles = profiles.take(5).toList(growable: false);
    final stackWidth = visibleProfiles.isEmpty
        ? 0.0
        : _avatarSize + ((visibleProfiles.length - 1) * _overlapOffset);

    return SizedBox(
      height: 34,
      width: stackWidth,
      child: Stack(
        children: [
          for (var index = 0; index < visibleProfiles.length; index++)
            Positioned(
              left: index * _overlapOffset,
              child: _ProfileAvatar(imageUrl: visibleProfiles[index].imageUrl),
            ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = CustomFunctions.resolveImageUrl(imageUrl);

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textPrimary, width: 1.4),
        image: DecorationImage(
          image: resolvedImageUrl == null
              ? const AssetImage('lib/assets/images/dumy_pic.png')
              : NetworkImage(resolvedImageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.label,
    required this.name,
    required this.imageUrl,
  });

  final String label;
  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = CustomFunctions.resolveImageUrl(imageUrl);

    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: resolvedImageUrl == null
              ? const AssetImage('lib/assets/images/dumy_pic.png')
              : NetworkImage(resolvedImageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark2,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppTextView.title1(value, color: AppColors.textPrimary, fontSize: 22),
          const SizedBox(height: 3),
          AppTextView.body3(
            label,
            color: AppColors.secondaryColor,
            textAlign: TextAlign.center,
            fontSize: 10,
          ),
        ],
      ),
    );
  }
}

class _AuditActionButton extends StatelessWidget {
  const _AuditActionButton({this.onTap, required this.label});

  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondaryColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          height: 78,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.arrow_outward_rounded,
                color: AppColors.textPrimary,
                size: 28,
              ),
              const SizedBox(height: 6),
              AppTextView.body1(
                label,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

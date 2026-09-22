import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/utils/custom_functions.dart';
import '../../../../../core/widgets/app_text_view.dart';

class GroupsSearchField extends StatelessWidget {
  const GroupsSearchField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.hex1b1e27,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        cursorHeight: 18,
        style: const TextStyle(color: AppColors.textPrimary),
        cursorColor: AppColors.textPrimary,
        decoration: const InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
          ),
          hintText: AppStrings.searchHint,
          hintStyle: TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class PrimaryGroupsButton extends StatelessWidget {
  const PrimaryGroupsButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: AppTextView.body3(
          label,
          color: AppColors.hex0b1520,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class SecondaryGroupsButton extends StatelessWidget {
  const SecondaryGroupsButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.10),
          ),
        ),
        alignment: Alignment.center,
        child: AppTextView.body3(
          label,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class GroupSummaryTile extends StatelessWidget {
  const GroupSummaryTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.hex1b1e27,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.textPrimary, size: 18),
          const SizedBox(height: 10),
          AppTextView.body4(
            label,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 4),
          AppTextView.body3(
            value,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}

class GroupsSection extends StatelessWidget {
  const GroupsSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final Widget child;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: AppTextView.body1(
                  title,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              if (actionLabel != null && onActionTap != null)
                InkWell(
                  onTap: onActionTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    child: AppTextView.body4(
                      actionLabel!,
                      color: AppColors.blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 4),
            AppTextView.body4(
              subtitle!,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class GroupThumbnailImage extends StatelessWidget {
  const GroupThumbnailImage({
    super.key,
    required this.imageUrl,
    required this.borderRadius,
    required this.size,
    this.imagePath,
  });

  final String imageUrl;
  final double borderRadius;
  final double size;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final imageProvider = _resolvedGroupsAvatarImageProvider(
      imagePath: imagePath,
      imageUrl: imageUrl,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageProvider == null
          ? _GroupThumbnailFallback(size: size)
          : Image(
              image: imageProvider,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _GroupThumbnailFallback(size: size),
            ),
    );
  }
}

class _GroupThumbnailFallback extends StatelessWidget {
  const _GroupThumbnailFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.hex232834,
      alignment: Alignment.center,
      child: const Icon(Icons.groups_2_rounded, color: AppColors.textSecondary),
    );
  }
}

class GroupHeaderAvatar extends StatelessWidget {
  const GroupHeaderAvatar({
    super.key,
    required this.groupImageUrl,
    this.groupImagePath,
    this.authorAvatarImagePath,
    required this.authorAvatarUrl,
    required this.onGroupTap,
    required this.onProfileTap,
  });

  final String groupImageUrl;
  final String? groupImagePath;
  final String? authorAvatarImagePath;
  final String authorAvatarUrl;
  final VoidCallback onGroupTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final authorImageProvider = _resolvedGroupsAvatarImageProvider(
      imagePath: authorAvatarImagePath,
      imageUrl: authorAvatarUrl,
    );

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          InkWell(
            onTap: onGroupTap,
            borderRadius: BorderRadius.circular(14),
            child: GroupThumbnailImage(
              imageUrl: groupImageUrl,
              imagePath: groupImagePath,
              borderRadius: 14,
              size: 44,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.hex1b1e27,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.90),
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: AppColors.hex232834,
                  backgroundImage: authorImageProvider,
                  child: authorImageProvider == null
                      ? const Icon(
                          Icons.person_rounded,
                          color: AppColors.textPrimary,
                          size: 12,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

ImageProvider<Object>? _resolvedGroupsAvatarImageProvider({
  String? imagePath,
  String? imageUrl,
}) {
  final normalizedImagePath = imagePath?.trim();
  if (normalizedImagePath != null && normalizedImagePath.isNotEmpty) {
    if (CustomFunctions.isAssetImagePath(normalizedImagePath)) {
      return AssetImage(normalizedImagePath);
    }

    final localFile = File(normalizedImagePath);
    if (localFile.existsSync()) {
      return FileImage(localFile);
    }
  }

  final normalizedImageUrl = imageUrl?.trim();
  if (normalizedImageUrl != null && normalizedImageUrl.isNotEmpty) {
    final resolvedImageUrl = CustomFunctions.resolveNetworkUrl(
      normalizedImageUrl,
    );
    if (resolvedImageUrl != null) {
      return NetworkImage(resolvedImageUrl);
    }
  }

  if (normalizedImagePath != null && normalizedImagePath.isNotEmpty) {
    final resolvedImagePath = CustomFunctions.resolveNetworkUrl(
      normalizedImagePath,
    );
    if (resolvedImagePath != null) {
      return NetworkImage(resolvedImagePath);
    }
  }

  return null;
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
  });

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AppTextView.body4(
        label,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class InlineMetaChip extends StatelessWidget {
  const InlineMetaChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: AppTextView.body4(
        label,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class GroupsActionChip extends StatelessWidget {
  const GroupsActionChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AppTextView.body4(
          label,
          color: AppColors.hex0b1520,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

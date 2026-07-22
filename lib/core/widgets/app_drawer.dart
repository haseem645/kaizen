import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../navigation/app_menu_type.dart';
import 'app_text_view.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.name,
    this.image,
    this.imageUrl,
    required this.selectedMenu,
    this.onHomeTap,
    this.onProfileTap,
    this.onLearningTracksTap,
    this.onComplianceTap,
    this.onAuditsTap,
    this.onPerformanceSnapshotTap,
    this.onSeatProfilesTap,
    this.onPaygradesTap,
    this.onKaizenGptTap,
    this.onSettingTap,
    this.onDrawerHeaderTap,
  });

  final String name;
  final String? image;
  final String? imageUrl;
  final AppMenuType? selectedMenu;
  final VoidCallback? onHomeTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLearningTracksTap;
  final VoidCallback? onComplianceTap;
  final VoidCallback? onAuditsTap;
  final VoidCallback? onPerformanceSnapshotTap;
  final VoidCallback? onSeatProfilesTap;
  final VoidCallback? onPaygradesTap;
  final VoidCallback? onKaizenGptTap;
  final VoidCallback? onSettingTap;
  final VoidCallback? onDrawerHeaderTap;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surfaceDark,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildDrawerItem(
              context,
              icon: Icons.home_outlined,
              title: AppStrings.homeKaizengram,
              isSelected: selectedMenu == AppMenuType.home,
              onTap: onHomeTap,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.auto_awesome_outlined,
              title: AppStrings.homeAi,
              isSelected: selectedMenu == AppMenuType.kaizenGpt,
              onTap: onKaizenGptTap,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.verified_user_outlined,
              title: AppStrings.homeLearningTracks,
              isSelected: selectedMenu == AppMenuType.learningTracks,
              onTap: onLearningTracksTap,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.folder_open_outlined,
              title: AppStrings.homeCompliance,
              isSelected: selectedMenu == AppMenuType.compliance,
              onTap: onComplianceTap,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.fact_check_outlined,
              title: AppStrings.weeklyCheckIns,
              isSelected: selectedMenu == AppMenuType.audits,
              onTap: onAuditsTap,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.insights_outlined,
              title: AppStrings.performanceSnapshot,
              isSelected: selectedMenu == AppMenuType.performanceSnapshot,
              onTap: onPerformanceSnapshotTap,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.event_seat_outlined,
              title: AppStrings.homeSeatProfiles,
              isSelected: selectedMenu == AppMenuType.seatProfiles,
              onTap: onSeatProfilesTap,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.payments_outlined,
              title: AppStrings.homePaygrades,
              isSelected: selectedMenu == AppMenuType.paygrades,
              onTap: onPaygradesTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: GestureDetector(
        onTap: onDrawerHeaderTap,
        child: Row(
          children: [
            _ProfileAvatar(imagePath: image, imageUrl: imageUrl),
            const SizedBox(width: 14),
            Expanded(
              child: AppTextView.body1(
                name,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.secondaryColor : AppColors.textPrimary),
      title: AppTextView.body2(
        title,
        color: isSelected ? AppColors.secondaryColor : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      selected: isSelected,
      selectedTileColor: AppColors.secondaryColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
      onTap: () {
        Navigator.of(context).pop();
        onTap?.call();
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.imagePath, this.imageUrl});

  final String? imagePath;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final provider = _resolveImageProvider();

    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceDark3,
        border: Border.all(color: AppColors.secondaryColor, width: 2),
        image: provider == null ? null : DecorationImage(image: provider, fit: BoxFit.cover),
      ),
      child: provider == null
          ? const Icon(Icons.person_outline_rounded, color: AppColors.textPrimary, size: 48)
          : null,
    );
  }

  ImageProvider<Object>? _resolveImageProvider() {
    final candidates = [imagePath, imageUrl];

    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value == null || value.isEmpty) {
        continue;
      }

      if (value.startsWith('http')) {
        return CachedNetworkImageProvider(value);
      }

      final file = File(value);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }

    return null;
  }
}

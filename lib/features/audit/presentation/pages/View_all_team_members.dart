// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/audit_profile.dart';
import '../providers/audit_controller.dart';

class ViewAllTeamMembers extends StatefulWidget {
  const ViewAllTeamMembers({
    super.key,
    required this.members,
    required this.onMemberTap,
    required this.onFavoriteTap,
  });

  final List<AuditProfile> members;
  final Future<void> Function(AuditProfile member) onMemberTap;
  final Future<List<AuditProfile>> Function(AuditProfile member) onFavoriteTap;

  @override
  State<ViewAllTeamMembers> createState() => _ViewAllTeamMembersState();
}

class _ViewAllTeamMembersState extends State<ViewAllTeamMembers> {
  late final TextEditingController _searchController;
  late List<AuditProfile> _members;
  _TeamMembersTab _selectedTab = _TeamMembersTab.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _members = widget.members;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = _filteredMembers;

    return Dialog.fullscreen(
      backgroundColor: AppColors.mainBg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            children: [
              _Header(onClose: () => Navigator.of(context).pop()),
              const SizedBox(height: 8),
              _TeamMembersTabs(
                selectedTab: _selectedTab,
                onTabChanged: (tab) {
                  setState(() {
                    _selectedTab = tab;
                  });
                },
              ),
              const SizedBox(height: 16),
              _SearchBar(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _query = value);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: members.isEmpty
                    ? const Center(
                        child: AppTextView.body(
                          'No team members found.',
                          color: AppColors.textSecondary,
                        ),
                      )
                    : ListView.separated(
                        itemCount: members.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _TeamMemberTile(
                            member: members[index],
                            onTap: () => widget.onMemberTap(members[index]),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<AuditProfile> get _filteredMembers {
    final visibleMembers = _selectedTab == _TeamMembersTab.favorites
        ? _members.where((member) => member.isFavorite).toList(growable: false)
        : _members;
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return visibleMembers;
    }

    return visibleMembers
        .where((member) {
          return member.name.toLowerCase().contains(query) ||
              member.roleTitle.toLowerCase().contains(query) ||
              member.email.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  void updateMembers(List<AuditProfile> members) {
    setState(() {
      _members = members;
    });
  }
}

enum _TeamMembersTab { all, favorites }

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const AppTextView.body1(
            'Team Members',
            color: AppColors.secondaryColor,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: AppColors.textPrimary,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Search team members',
                hintStyle: TextStyle(
                  color: AppColors.grey1,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamMembersTabs extends StatelessWidget {
  const _TeamMembersTabs({required this.selectedTab, required this.onTabChanged});

  final _TeamMembersTab selectedTab;
  final ValueChanged<_TeamMembersTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TeamMembersTabButton(
              label: 'All Team Members',
              isSelected: selectedTab == _TeamMembersTab.all,
              onTap: () => onTabChanged(_TeamMembersTab.all),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TeamMembersTabButton(
              label: 'My Favorites',
              isSelected: selectedTab == _TeamMembersTab.favorites,
              onTap: () => onTabChanged(_TeamMembersTab.favorites),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamMembersTabButton extends StatelessWidget {
  const _TeamMembersTabButton({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AppTextView.body3(
          label,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _TeamMemberTile extends StatelessWidget {
  const _TeamMemberTile({required this.member, required this.onTap});

  final AuditProfile member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            Positioned(right: 5, top: 0, child: _FavoriteToggleButton(member: member)),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _Avatar(size: 48, imageUrl: member.imageUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextView.body2(
                          member.roleTitle,
                          color: AppColors.secondaryColor,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        AppTextView.body2(
                          member.name,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (member.email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          AppTextView.body3(
                            member.email,
                            color: AppColors.textSecondary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteToggleButton extends StatelessWidget {
  const _FavoriteToggleButton({required this.member});

  final AuditProfile member;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuditController>();
    final isLoading = controller.isFavoriteUpdating(member.profileJob);

    return IconButton(
      onPressed: isLoading
          ? null
          : () async {
              final parentState = context.findAncestorStateOfType<_ViewAllTeamMembersState>();
              if (parentState == null) {
                return;
              }

              try {
                final updatedMembers = await parentState.widget.onFavoriteTap(member);
                if (!context.mounted) {
                  return;
                }

                parentState.updateMembers(updatedMembers);
              } catch (_) {
                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Unable to update favorite right now.')),
                  );
              }
            },
      splashRadius: 18,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
            )
          : Icon(
              Icons.star_rounded,
              color: member.isFavorite ? AppColors.yellow : AppColors.grey2,
              size: 20,
            ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.size, this.imageUrl});

  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = CustomFunctions.resolveImageUrl(imageUrl);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: resolvedImageUrl == null
              ? const AssetImage('${AppStrings.imagePath}dumy_pic.png')
              : NetworkImage(resolvedImageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

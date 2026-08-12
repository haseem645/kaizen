import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dot_divider.dart';
import '../../../../core/widgets/app_text_view.dart';

class AuditSeatProfileFilterSheet extends StatefulWidget {
  const AuditSeatProfileFilterSheet({
    super.key,
    required this.options,
    this.initialValue,
    this.showAllOption = false,
    this.allOptionLabel = 'All Seat Profiles',
    this.title = AppStrings.auditSeatProfile,
    this.searchHint = AppStrings.auditSearchSeatProfile,
  });

  final List<String> options;
  final String? initialValue;
  final bool showAllOption;
  final String allOptionLabel;
  final String title;
  final String searchHint;

  @override
  State<AuditSeatProfileFilterSheet> createState() =>
      _AuditSeatProfileFilterSheetState();
}

class _AuditSeatProfileFilterSheetState
    extends State<AuditSeatProfileFilterSheet> {
  String? _selectedValue;
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.showAllOption
        ? (widget.initialValue ?? '')
        : widget.initialValue;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredOptions = widget.options
        .where((option) {
          if (_searchQuery.trim().isEmpty) {
            return true;
          }

          return option.toLowerCase().contains(
            _searchQuery.trim().toLowerCase(),
          );
        })
        .toList(growable: false);

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: const BoxDecoration(
          color: AppColors.mainBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            _SelectionHeader(
              title: widget.title,
              onBack: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 22),
            const AppDotDivider(),
            const SizedBox(height: 24),
            _SeatProfileSearchBar(
              controller: _searchController,
              hintText: widget.searchHint,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 22),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (widget.showAllOption)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _SelectionOptionTile(
                          title: widget.allOptionLabel,
                          isSelected: _selectedValue == '',
                          onTap: () {
                            setState(() {
                              _selectedValue = '';
                            });
                          },
                        ),
                      ),
                    ...filteredOptions.map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _SelectionOptionTile(
                          title: option,
                          isSelected: _selectedValue == option,
                          onTap: () {
                            setState(() {
                              _selectedValue = option;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            const AppDotDivider(),
            const SizedBox(height: 22),
            AppButton(
              text: AppStrings.done,
              onPressed: (!widget.showAllOption && _selectedValue == null)
                  ? null
                  : () => Navigator.of(context).pop(_selectedValue),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatProfileSearchBar extends StatelessWidget {
  const _SeatProfileSearchBar({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.75),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorHeight: 16,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        cursorColor: AppColors.textPrimary,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: SvgPicture.asset(
            '${AppStrings.imagePath}back.svg',
            width: 24,
            height: 24,
          ),
        ),
        Expanded(
          child: AppTextView.title(
            title,
            color: AppColors.secondaryColor,
            fontSize: 20,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 32),
      ],
    );
  }
}

class _SelectionOptionTile extends StatelessWidget {
  const _SelectionOptionTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.secondaryColor
                      : AppColors.hexd9d4f0,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.hex7747e6
                        : AppColors.hexd9d4f0,
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: AppTextView.body(
                  title,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

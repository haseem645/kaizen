import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dot_divider.dart';
import '../../../../core/widgets/app_text_view.dart';

class ComplianceLearningTrackFilterSheet extends StatefulWidget {
  const ComplianceLearningTrackFilterSheet({
    super.key,
    required this.seatProfiles,
    required this.selectedSeatProfiles,
  });

  final List<String> seatProfiles;
  final Set<String> selectedSeatProfiles;

  @override
  State<ComplianceLearningTrackFilterSheet> createState() =>
      _ComplianceLearningTrackFilterSheetState();
}

class _ComplianceLearningTrackFilterSheetState extends State<ComplianceLearningTrackFilterSheet> {
  late final Set<String> _selectedSeatProfiles = Set<String>.from(widget.selectedSeatProfiles);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: const BoxDecoration(
          color: AppColors.mainBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildHeader(context),
              const SizedBox(height: 18),
              const AppDotDivider(),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.seatProfiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final seatProfile = widget.seatProfiles[index];
                    final isSelected = _selectedSeatProfiles.contains(seatProfile);

                    return _buildSeatProfileItem(
                      name: seatProfile,
                      isSelected: isSelected,
                      onTap: () => _toggleSeatProfile(seatProfile),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: AppStrings.done,
                onPressed: () {
                  Navigator.of(context).pop(_selectedSeatProfiles);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 0,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: SvgPicture.asset('${AppStrings.imagePath}back.svg', width: 24, height: 24),
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppTextView.body1(
              AppStrings.complianceSeatProfileTitle,
              color: AppColors.secondaryColor,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeatProfileItem({
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildCheckbox(isSelected),
              const SizedBox(width: 14),
              Expanded(
                child: AppTextView.body(
                  name,
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

  Widget _buildCheckbox(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.lightGreen1 : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isSelected ? AppColors.lightGreen1 : AppColors.textPrimary,
          width: 1.5,
        ),
      ),
    );
  }

  void _toggleSeatProfile(String seatProfile) {
    setState(() {
      if (_selectedSeatProfiles.contains(seatProfile)) {
        _selectedSeatProfiles.remove(seatProfile);
      } else {
        _selectedSeatProfiles.add(seatProfile);
      }
    });
  }
}

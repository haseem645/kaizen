import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_seat_selection_tile.dart';
import '../../../../core/widgets/app_selection_sheet.dart';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFilterSheetHeader(
              title: AppStrings.complianceSeatProfileTitle,
              centerTitle: true,
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSeatProfileItem({
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AppSeatSelectionTile(
      title: name,
      isSelected: isSelected,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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

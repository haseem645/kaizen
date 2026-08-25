import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dot_divider.dart';
import '../../../../core/widgets/app_text_view.dart';

class AuditYearQuarterFilterSheet extends StatefulWidget {
  const AuditYearQuarterFilterSheet({
    super.key,
    required this.options,
    this.initialValue,
  });

  final List<String> options;
  final String? initialValue;

  @override
  State<AuditYearQuarterFilterSheet> createState() =>
      _AuditYearQuarterFilterSheetState();
}

class _AuditYearQuarterFilterSheetState
    extends State<AuditYearQuarterFilterSheet> {
  late final List<int> _years;
  int? _selectedYear;
  String? _selectedQuarterCode;

  @override
  void initState() {
    super.initState();
    _years =
        widget.options
            .map(_parseYearQuarter)
            .map((item) => item.year)
            .toSet()
            .toList()
          ..sort();

    final initial = widget.initialValue == null
        ? null
        : _parseYearQuarter(widget.initialValue!);
    _selectedYear = initial?.year ?? (_years.isNotEmpty ? _years.first : null);
    _selectedQuarterCode = initial?.quarterCode;
  }

  @override
  Widget build(BuildContext context) {
    final quarterOptions = _quarterOptionsForSelectedYear();
    final sheetHeight = MediaQuery.of(context).size.height * 0.88;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        height: sheetHeight,
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
              title: AppStrings.auditSelectYearQuarter,
              onBack: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppDotDivider(),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.grey1.withValues(alpha: 0.75),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.chevron_left_rounded,
                                color: AppColors.grey1,
                                size: 24,
                              ),
                              const Spacer(),
                              const AppTextView.body(
                                'Select Year',
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.grey1,
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _years.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 2.3,
                                  mainAxisSpacing: 18,
                                  crossAxisSpacing: 18,
                                ),
                            itemBuilder: (context, index) {
                              final year = _years[index];
                              final isSelected = year == _selectedYear;

                              return InkWell(
                                borderRadius: BorderRadius.circular(8),
                                splashFactory: NoSplash.splashFactory,
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                onTap: () {
                                  final availableQuarterCodes = widget.options
                                      .map(_parseYearQuarter)
                                      .where((item) => item.year == year)
                                      .map((item) => item.quarterCode)
                                      .toSet();
                                  setState(() {
                                    _selectedYear = year;
                                    if (!availableQuarterCodes.contains(
                                      _selectedQuarterCode,
                                    )) {
                                      _selectedQuarterCode =
                                          availableQuarterCodes.isNotEmpty
                                          ? availableQuarterCodes.first
                                          : null;
                                    }
                                  });
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.secondaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: AppTextView.body(
                                    '$year',
                                    color: isSelected
                                        ? Colors.black
                                        : AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    ...quarterOptions.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _SelectionOptionTile(
                          title: item.label,
                          isSelected: _selectedQuarterCode == item.quarterCode,
                          onTap: () {
                            setState(() {
                              _selectedQuarterCode = item.quarterCode;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const AppDotDivider(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            AppButton(
              text: AppStrings.done,
              onPressed: _selectedYear == null || _selectedQuarterCode == null
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pop('${_selectedYear!} - ${_selectedQuarterCode!}'),
            ),
          ],
        ),
      ),
    );
  }

  List<_QuarterOption> _quarterOptionsForSelectedYear() {
    if (_selectedYear == null) {
      return const [];
    }

    return List<_QuarterOption>.generate(4, (index) {
      final quarterNumber = index + 1;
      final quarterCode = 'Q$quarterNumber';

      return _QuarterOption(
        quarterCode: quarterCode,
        label: 'Quarter $quarterNumber - $_selectedYear',
      );
    }, growable: false);
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
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
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

class _ParsedYearQuarter {
  const _ParsedYearQuarter({
    required this.year,
    required this.quarterCode,
    required this.quarterNumber,
  });

  final int year;
  final String quarterCode;
  final int quarterNumber;
}

class _QuarterOption {
  const _QuarterOption({required this.quarterCode, required this.label});

  final String quarterCode;
  final String label;
}

_ParsedYearQuarter _parseYearQuarter(String value) {
  final parts = value.split(' - ');
  final year = int.tryParse(parts.first.trim()) ?? 0;
  final quarterCode = parts.length > 1 ? parts[1].trim() : 'Q1';
  final quarterNumber = int.tryParse(quarterCode.replaceAll('Q', '')) ?? 1;

  return _ParsedYearQuarter(
    year: year,
    quarterCode: quarterCode,
    quarterNumber: quarterNumber,
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_confirmation_dialog.dart';
import '../../../../core/widgets/app_dot_divider.dart';
import '../../../../core/widgets/app_overlay_close_button.dart';
import '../../../../core/widgets/app_swipe_reveal_action.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/seat_profile_category_draft.dart';

////
Future<bool> showSeatProfileManageCategoriesSheet(
  BuildContext context, {
  required List<SeatProfileCategoryDraft> initialCategories,
  required Future<void> Function(List<SeatProfileCategoryDraft> categories) onSaveCategories,
}) async {
  final didUpdate = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (_) => SeatProfileManageCategoriesSheet(
      initialCategories: initialCategories,
      onSaveCategories: onSaveCategories,
    ),
  );

  return didUpdate == true;
}

class SeatProfileManageCategoriesSheet extends StatefulWidget {
  const SeatProfileManageCategoriesSheet({
    super.key,
    required this.initialCategories,
    required this.onSaveCategories,
  });

  final List<SeatProfileCategoryDraft> initialCategories;
  final Future<void> Function(List<SeatProfileCategoryDraft> categories) onSaveCategories;

  @override
  State<SeatProfileManageCategoriesSheet> createState() => _SeatProfileManageCategoriesSheetState();
}

class _SeatProfileManageCategoriesSheetState extends State<SeatProfileManageCategoriesSheet> {
  late final _ManageSeatCategoriesDialogController _formController;

  @override
  void initState() {
    super.initState();
    _formController = _ManageSeatCategoriesDialogController()
      ..initializeWith(widget.initialCategories);
  }

  Future<void> _submit() async {
    final validationMessage = _formController.validateEntries();
    if (validationMessage != null) {
      _formController.setMessage(validationMessage);
      return;
    }

    if (_formController.requiresTotalConfirmation) {
      final shouldContinue = await _showTotalConfirmationDialog();
      if (!mounted || !shouldContinue) {
        return;
      }
    }

    _formController.setSaving(true);

    try {
      await widget.onSaveCategories(_formController.buildDrafts());
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(error.toString());
    } finally {
      if (mounted) {
        _formController.setSaving(false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _showTotalConfirmationDialog() async {
    final didConfirm = await showDialog<bool>(
      context: context,
      builder: (_) => AppConfirmationDialog(
        title: AppStrings.seatProfileCategoriesSaveConfirmationTitle,
        description: AppStrings.seatProfileCategoriesSaveConfirmationDescription,
        onCancelCallback: () async => Navigator.of(context).pop(false),
        onConfirmCallback: () async => Navigator.of(context).pop(true),
        confirmText: AppStrings.seatProfileSaveAction,
        cancelText: AppStrings.done,
      ),
    );

    return didConfirm == true;
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _formController,
      builder: (context, _) => PopScope<Object?>(
        canPop: !_formController.isSaving,
        child: SafeArea(
          top: false,
          bottom: false,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 720,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.88,
                ),
                child: Material(
                  color: AppColors.surfaceDark,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 560;
                      final amountFieldWidth = isCompact ? 92.0 : 118.0;

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          isCompact ? 18 : 24,
                          isCompact ? 18 : 20,
                          isCompact ? 18 : 24,
                          isCompact ? 20 : 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextView.body1(
                                    AppStrings.seatProfileManageCategoriesDialogTitle,
                                    color: AppColors.textPrimary,
                                    fontSize: isCompact ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                _SeatContentDialogCloseButton(
                                  onTap: _formController.isSaving
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                            SizedBox(height: isCompact ? 14 : 18),
                            const AppDotDivider(),
                            SizedBox(height: isCompact ? 18 : 24),
                            _ManageSeatCategoriesIntroSection(
                              isCompact: isCompact,
                              importanceStatusValue: _formController.importanceStatusValue,
                              importanceStatusLabel: _formController.importanceStatusLabel,
                              importanceStatusColor: _formController.importanceStatusColor,
                            ),
                            SizedBox(height: isCompact ? 20 : 28),
                            _SeatCategoryHeaderRow(
                              isCompact: isCompact,
                              amountFieldWidth: amountFieldWidth,
                            ),
                            SizedBox(height: isCompact ? 10 : 14),
                            if (_formController.rows.isNotEmpty) ...[
                              ...List.generate(
                                _formController.rows.length,
                                (index) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == _formController.rows.length - 1
                                        ? (isCompact ? 10 : 12)
                                        : (isCompact ? 8 : 10),
                                  ),
                                  child: _SeatCategoryInputRow(
                                    key: ObjectKey(_formController.rows[index]),
                                    rowController: _formController.rows[index],
                                    onDeleteTap: _formController.isSaving
                                        ? null
                                        : () => _formController.removeRowAt(index),
                                    isCompact: isCompact,
                                    amountFieldWidth: amountFieldWidth,
                                  ),
                                ),
                              ),
                            ],
                            _SeatCategoryActionFooter(
                              isCompact: isCompact,
                              totalImportance: _formController.totalImportance,
                              onAddTap: _formController.isSaving ? null : _formController.addRow,
                            ),
                            SizedBox(height: isCompact ? 14 : 18),
                            AppTextView.body2(
                              AppStrings.seatProfileCategoryValidationNote,
                              color: AppColors.grey1,
                              fontSize: isCompact ? 12 : 14,
                              height: 1.45,
                            ),
                            if (_formController.message != null) ...[
                              const SizedBox(height: 16),
                              _CreateMessageCard(message: _formController.message!),
                            ],
                            SizedBox(height: isCompact ? 18 : 22),
                            Align(
                              alignment: isCompact ? Alignment.center : Alignment.centerRight,
                              child: SizedBox(
                                width: isCompact ? double.infinity : 180,
                                child: AppButton(
                                  text: AppStrings.seatProfileSaveAction,
                                  onPressed: _formController.isSaving ? null : _submit,
                                  isLoading: _formController.isSaving,
                                  borderRadius: 14,
                                  minimumHeight: 48,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManageSeatCategoriesDialogController extends ChangeNotifier {
  final List<_SeatCategoryRowController> rows = <_SeatCategoryRowController>[];
  bool _isSaving = false;
  String? _message;

  bool get isSaving => _isSaving;
  String? get message => _message;

  double get totalImportance =>
      rows.fold<double>(0, (total, row) => total + _parseWeightPercent(row.weightController.text));

  double get remainingImportance => 100 - totalImportance;
  bool get hasReachedImportance => remainingImportance.abs() < 0.001;
  bool get hasExceededImportance => remainingImportance < -0.001;
  double get importanceStatusValue => totalImportance;

  String get importanceStatusLabel {
    if (hasReachedImportance) {
      return AppStrings.seatProfileCategoryImportanceReached;
    }

    if (hasExceededImportance) {
      return AppStrings.seatProfileCategoryImportanceExceeded;
    }

    return AppStrings.seatProfileCategoryImportanceRemaining;
  }

  Color get importanceStatusColor =>
      hasReachedImportance ? AppColors.secondaryColor : AppColors.red1;
  bool get requiresTotalConfirmation => remainingImportance > 0.001;

  void initializeWith(List<SeatProfileCategoryDraft> categories) {
    for (final row in rows) {
      row.dispose();
    }
    rows.clear();

    for (final category in categories) {
      rows.add(
        _SeatCategoryRowController(
          uuid: category.uuid,
          title: category.title,
          weightPercent: _formatSeatProfilePercent(category.weightPercent),
          onChanged: _handleRowChanged,
        ),
      );
    }

    _message = null;
    notifyListeners();
  }

  void addRow() {
    rows.add(_SeatCategoryRowController(onChanged: _handleRowChanged));
    _message = null;
    notifyListeners();
  }

  void removeRowAt(int index) {
    if (index < 0 || index >= rows.length) {
      return;
    }

    final row = rows.removeAt(index);
    row.dispose();
    _message = null;
    notifyListeners();
  }

  void setSaving(bool value) {
    if (_isSaving == value) {
      return;
    }

    _isSaving = value;
    notifyListeners();
  }

  void setMessage(String? message) {
    if (_message == message) {
      return;
    }

    _message = message;
    notifyListeners();
  }

  String? validateEntries() {
    for (final row in rows) {
      final title = row.nameController.text.trim();
      if (title.isEmpty) {
        return AppStrings.seatProfileCategoryNameRequired;
      }
      if (title.length > 25) {
        return AppStrings.seatProfileCategoryNameCharacterLimit;
      }
      if (_countWords(title) > 3) {
        return AppStrings.seatProfileCategoryNameWordLimit;
      }

      final weightText = row.weightController.text.trim();
      if (weightText.isEmpty) {
        return AppStrings.seatProfileCategoryImportanceRequired;
      }

      final weight = double.tryParse(weightText);
      if (weight == null || weight <= 0) {
        return AppStrings.seatProfileCategoryImportanceInvalid;
      }
    }

    if (totalImportance > 100.001) {
      return AppStrings.seatProfileCategoryImportanceTotalExceeded;
    }

    return null;
  }

  List<SeatProfileCategoryDraft> buildDrafts() {
    return rows
        .map(
          (row) => SeatProfileCategoryDraft(
            uuid: row.uuid,
            title: row.nameController.text.trim(),
            weightPercent: _parseWeightPercent(row.weightController.text),
          ),
        )
        .toList(growable: false);
  }

  void _handleRowChanged() {
    if (_message == null) {
      notifyListeners();
      return;
    }

    _message = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final row in rows) {
      row.dispose();
    }
    super.dispose();
  }
}

class _SeatCategoryRowController {
  _SeatCategoryRowController({
    this.uuid,
    String title = '',
    String weightPercent = '',
    required VoidCallback onChanged,
  }) : _onChanged = onChanged {
    nameController = TextEditingController(text: title)..addListener(_handleChanged);
    weightController = TextEditingController(text: weightPercent)..addListener(_handleChanged);
  }

  final String? uuid;
  late final TextEditingController nameController;
  late final TextEditingController weightController;
  final VoidCallback _onChanged;

  void _handleChanged() {
    _onChanged();
  }

  void dispose() {
    nameController
      ..removeListener(_handleChanged)
      ..dispose();
    weightController
      ..removeListener(_handleChanged)
      ..dispose();
  }
}

class _CategoryRemainingCard extends StatelessWidget {
  const _CategoryRemainingCard({
    required this.importanceStatusValue,
    required this.importanceStatusLabel,
    required this.backgroundColor,
    required this.isCompact,
  });

  final double importanceStatusValue;
  final String importanceStatusLabel;
  final Color backgroundColor;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCompact ? double.infinity : 220,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 18, vertical: isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppTextView.title1(
              '${_formatSeatProfilePercent(importanceStatusValue)}%',
              color: AppColors.textPrimary,
              fontSize: isCompact ? 28 : 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: isCompact ? 10 : 12),
          Expanded(
            child: AppTextView.body1(
              importanceStatusLabel,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: isCompact ? 14 : 18,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageSeatCategoriesIntroSection extends StatelessWidget {
  const _ManageSeatCategoriesIntroSection({
    required this.isCompact,
    required this.importanceStatusValue,
    required this.importanceStatusLabel,
    required this.importanceStatusColor,
  });

  final bool isCompact;
  final double importanceStatusValue;
  final String importanceStatusLabel;
  final Color importanceStatusColor;

  @override
  Widget build(BuildContext context) {
    final infoCard = Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.mainBg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
        border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextView.body1(
            AppStrings.seatProfileManageCategoriesSectionTitle,
            color: AppColors.lightPurple2,
            fontSize: isCompact ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: isCompact ? 8 : 10),
          AppTextView.body(
            AppStrings.seatProfileManageCategoriesDescription,
            color: AppColors.lightPurple1,
            fontSize: isCompact ? 13 : 15,
            height: 1.45,
          ),
        ],
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          infoCard,
          const SizedBox(height: 12),
          _CategoryRemainingCard(
            importanceStatusValue: importanceStatusValue,
            importanceStatusLabel: importanceStatusLabel,
            backgroundColor: importanceStatusColor,
            isCompact: true,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: infoCard),
        const SizedBox(width: 16),
        _CategoryRemainingCard(
          importanceStatusValue: importanceStatusValue,
          importanceStatusLabel: importanceStatusLabel,
          backgroundColor: importanceStatusColor,
          isCompact: false,
        ),
      ],
    );
  }
}

class _SeatCategoryHeaderRow extends StatelessWidget {
  const _SeatCategoryHeaderRow({required this.isCompact, required this.amountFieldWidth});

  final bool isCompact;
  final double amountFieldWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppTextView.body1(
            AppStrings.seatProfileCategoryNameColumn,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: isCompact ? 13 : 18,
          ),
        ),
        SizedBox(width: isCompact ? 8 : 12),
        SizedBox(
          width: amountFieldWidth,
          child: AppTextView.body1(
            AppStrings.seatProfileImportancePercentColumn,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: isCompact ? 12 : 18,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _SeatCategoryInputRow extends StatelessWidget {
  const _SeatCategoryInputRow({
    super.key,
    required this.rowController,
    required this.onDeleteTap,
    required this.isCompact,
    required this.amountFieldWidth,
  });

  final _SeatCategoryRowController rowController;
  final VoidCallback? onDeleteTap;
  final bool isCompact;
  final double amountFieldWidth;

  @override
  Widget build(BuildContext context) {
    final rowHeight = isCompact ? 46.0 : 52.0;

    return SizedBox(
      height: rowHeight,
      child: AppSwipeRevealAction(
        isEnabled: onDeleteTap != null,
        onActionTap: onDeleteTap,
        borderRadius: 12,
        actionWidth: isCompact ? 56 : 64,
        actionGap: isCompact ? 8 : 10,
        actionChild: Container(
          height: rowHeight,
          decoration: BoxDecoration(color: AppColors.red1, borderRadius: BorderRadius.circular(12)),
          child: Icon(
            Icons.delete_outline_rounded,
            color: AppColors.textPrimary,
            size: isCompact ? 20 : 22,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DialogInputField(
                controller: rowController.nameController,
                hintText: AppStrings.seatProfileCategoryNameColumn,
                isCompact: isCompact,
                inputFormatters: <TextInputFormatter>[LengthLimitingTextInputFormatter(25)],
              ),
            ),
            SizedBox(width: isCompact ? 8 : 12),
            SizedBox(
              width: amountFieldWidth,
              child: _DialogInputField(
                controller: rowController.weightController,
                hintText: '0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                isCompact: isCompact,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogInputField extends StatelessWidget {
  const _DialogInputField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.textAlign = TextAlign.left,
    this.inputFormatters,
    this.isCompact = false,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isCompact ? 46 : 52,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.32)),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: textAlign,
          inputFormatters: inputFormatters,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: isCompact ? 13 : 14,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: AppColors.textPrimary,
          decoration: InputDecoration(
            border: InputBorder.none,
            isCollapsed: true,
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.65),
              fontSize: isCompact ? 13 : 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogDottedActionButton extends StatelessWidget {
  const _DialogDottedActionButton({
    required this.label,
    required this.onTap,
    this.isCompact = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return Opacity(
      opacity: isEnabled ? 1 : 0.58,
      child: CustomPaint(
        painter: _SeatProfileDottedRoundedBorderPainter(
          color: AppColors.fieldBorder.withValues(alpha: 0.45),
          radius: isCompact ? 16 : 18,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
            child: Ink(
              height: isCompact ? 56 : 64,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(isCompact ? 16 : 18)),
              child: Center(
                child: AppTextView.body1(
                  label,
                  color: AppColors.fieldBorder.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                  fontSize: isCompact ? 15 : 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatCategoryActionFooter extends StatelessWidget {
  const _SeatCategoryActionFooter({
    required this.isCompact,
    required this.totalImportance,
    required this.onAddTap,
  });

  final bool isCompact;
  final double totalImportance;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    final totalLabel =
        '${AppStrings.seatProfileCategoriesTotalLabel}: ${_formatSeatProfilePercent(totalImportance)}%';

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DialogDottedActionButton(
            label: AppStrings.seatProfileAddSeatCategoryAction,
            onTap: onAddTap,
            isCompact: true,
          ),
          const SizedBox(height: 10),
          AppTextView.body2(
            totalLabel,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.right,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _DialogDottedActionButton(
            label: AppStrings.seatProfileAddSeatCategoryAction,
            onTap: onAddTap,
          ),
        ),
        const SizedBox(width: 16),
        AppTextView.body1(totalLabel, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      ],
    );
  }
}

class _CreateMessageCard extends StatelessWidget {
  const _CreateMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.red1.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red1.withValues(alpha: 0.28)),
      ),
      child: AppTextView.body2(message, color: AppColors.textPrimary, height: 1.4),
    );
  }
}

class _SeatContentDialogCloseButton extends StatelessWidget {
  const _SeatContentDialogCloseButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppOverlayCloseButton(onTap: onTap);
  }
}

class _SeatProfileDottedRoundedBorderPainter extends CustomPainter {
  const _SeatProfileDottedRoundedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SeatProfileDottedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

double _parseWeightPercent(String value) {
  return double.tryParse(value.trim()) ?? 0;
}

String _formatSeatProfilePercent(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(1).replaceFirst(RegExp(r'\.?0+$'), '');
}

int _countWords(String value) {
  return value.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dot_divider.dart';
import '../../../../core/widgets/app_overlay_close_button.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../seat_profile/domain/entities/department.dart';
import '../models/department_color_option.dart';

Future<bool> showEditDepartmentDialog(
  BuildContext context, {
  required Department department,
  required Future<void> Function(String name, String colorHex) onSave,
}) async {
  final didSave = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _EditDepartmentDialog(department: department, onSave: onSave),
  );

  return didSave == true;
}

class _EditDepartmentDialog extends StatefulWidget {
  const _EditDepartmentDialog({required this.department, required this.onSave});

  final Department department;
  final Future<void> Function(String name, String colorHex) onSave;

  @override
  State<_EditDepartmentDialog> createState() => _EditDepartmentDialogState();
}

class _EditDepartmentDialogState extends State<_EditDepartmentDialog> {
  late final _EditDepartmentDialogController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _EditDepartmentDialogController(widget.department);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final didSave = await _controller.submit(widget.onSave);
    if (!mounted || !didSave) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

        return PopScope<Object?>(
          canPop: !_controller.isSaving,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: FractionallySizedBox(
              heightFactor: 0.9,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 52,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.fieldBorder.withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: AppTextView.body1(
                              AppStrings.departmentsEditTitle,
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _DialogCloseButton(
                            onTap: _controller.isSaving
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 18, 24, 0),
                      child: AppDotDivider(),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 22, 24, 0),
                      child: Center(
                        child: AppTextView.body(
                          AppStrings.departmentsEditDescription,
                          color: AppColors.lightPurple1,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppTextView.body2(
                              AppStrings.departmentsNameLabel,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            const SizedBox(height: 10),
                            _DialogTextField(
                              controller: _controller.nameController,
                              hintText: AppStrings.departmentsNameHint,
                              enabled: !_controller.isSaving,
                            ),
                            const SizedBox(height: 18),
                            const AppTextView.body2(
                              AppStrings.departmentsColorLabel,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            const SizedBox(height: 10),
                            _SelectedColorPreview(controller: _controller),
                            const SizedBox(height: 14),
                            IgnorePointer(
                              ignoring: _controller.isSaving,
                              child: _HsvColorPicker(controller: _controller),
                            ),
                            const SizedBox(height: 18),
                            const AppTextView.body2(
                              AppStrings.departmentsColorHexLabel,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            const SizedBox(height: 10),
                            _DialogTextField(
                              controller: _controller.hexController,
                              hintText: DepartmentColorPalette.fallbackHex,
                              enabled: !_controller.isSaving,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(7),
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[#0-9a-fA-F]'),
                                ),
                              ],
                            ),
                            if (_controller.errorMessage != null) ...[
                              const SizedBox(height: 16),
                              _DialogErrorCard(
                                message: _controller.errorMessage!,
                              ),
                            ],
                            const SizedBox(height: 22),
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: 180,
                                child: AppButton(
                                  text: AppStrings.seatProfileSaveAction,
                                  onPressed: _controller.canSave
                                      ? _submit
                                      : null,
                                  isLoading: _controller.isSaving,
                                  borderRadius: 14,
                                  minimumHeight: 48,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EditDepartmentDialogController extends ChangeNotifier {
  _EditDepartmentDialogController(Department department)
    : nameController = TextEditingController(text: department.name),
      hexController = TextEditingController(),
      _hsvColor = DepartmentColorPalette.resolveHsvColor(department.colorHex) {
    nameController.addListener(_handleInputChanged);
    hexController.addListener(_handleHexChanged);
    _setHexText(
      DepartmentColorPalette.hexFromColor(_hsvColor.toColor()),
      notify: false,
    );
  }

  final TextEditingController nameController;
  final TextEditingController hexController;
  HSVColor _hsvColor;

  bool _isSaving = false;
  String? _errorMessage;
  bool _isSyncingHex = false;

  bool get isSaving => _isSaving;
  bool get canSave =>
      !_isSaving &&
      nameController.text.trim().isNotEmpty &&
      DepartmentColorPalette.isValidHex(hexController.text);
  String? get errorMessage => _errorMessage;
  String get normalizedHex =>
      DepartmentColorPalette.hexFromColor(selectedColor);
  Color get selectedColor => _hsvColor.toColor();
  double get selectedHue => _hsvColor.hue;
  double get selectedSaturation => _hsvColor.saturation;
  double get selectedValue => _hsvColor.value;

  Future<bool> submit(
    Future<void> Function(String name, String colorHex) onSave,
  ) async {
    final validationMessage = _validate();
    if (validationMessage != null) {
      _errorMessage = validationMessage;
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await onSave(nameController.text.trim(), normalizedHex);
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void updateHue(double hue) {
    final safeHue = hue.clamp(0.0, 360.0).toDouble();
    _hsvColor = _hsvColor.withHue(safeHue);
    _syncHexFromPicker();
  }

  void updateSaturationAndValue({
    required double saturation,
    required double value,
  }) {
    _hsvColor = _hsvColor
        .withSaturation(saturation.clamp(0.0, 1.0).toDouble())
        .withValue(value.clamp(0.0, 1.0).toDouble());
    _syncHexFromPicker();
  }

  String? _validate() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      return AppStrings.departmentsNameRequired;
    }

    if (!DepartmentColorPalette.isValidHex(hexController.text)) {
      return AppStrings.departmentsColorInvalid;
    }

    return null;
  }

  void _handleInputChanged() {
    if (_errorMessage != null) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _handleHexChanged() {
    if (_isSyncingHex) {
      return;
    }

    final normalized = DepartmentColorPalette.normalizeHex(hexController.text);
    var shouldNotify = true;

    if (DepartmentColorPalette.isValidHex(normalized)) {
      _hsvColor = DepartmentColorPalette.resolveHsvColor(normalized);
      if (hexController.text != normalized) {
        _setHexText(normalized, notify: false);
        shouldNotify = false;
      }
    }

    if (_errorMessage != null) {
      _errorMessage = null;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  void _syncHexFromPicker() {
    _setHexText(
      DepartmentColorPalette.hexFromColor(_hsvColor.toColor()),
      notify: false,
    );
    if (_errorMessage != null) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setHexText(String value, {bool notify = true}) {
    _isSyncingHex = true;
    hexController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _isSyncingHex = false;

    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController
      ..removeListener(_handleInputChanged)
      ..dispose();
    hexController
      ..removeListener(_handleHexChanged)
      ..dispose();
    super.dispose();
  }
}

class _HsvColorPicker extends StatelessWidget {
  const _HsvColorPicker({required this.controller});

  final _EditDepartmentDialogController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _SaturationValuePicker(
              hue: controller.selectedHue,
              saturation: controller.selectedSaturation,
              value: controller.selectedValue,
              onChanged: controller.updateSaturationAndValue,
            ),
          ),
          const SizedBox(width: 14),
          _HueSlider(
            hue: controller.selectedHue,
            onChanged: controller.updateHue,
          ),
        ],
      ),
    );
  }
}

class _SelectedColorPreview extends StatelessWidget {
  const _SelectedColorPreview({required this.controller});

  final _EditDepartmentDialogController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: controller.selectedColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppTextView.body4(
                  AppStrings.departmentsSelectedColor,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 4),
                AppTextView.body2(
                  controller.normalizedHex,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaturationValuePicker extends StatelessWidget {
  const _SaturationValuePicker({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  final double hue;
  final double saturation;
  final double value;
  final void Function({required double saturation, required double value})
  onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pickerWidth = constraints.maxWidth;
        final pickerHeight = constraints.maxHeight;
        final indicatorLeft = (saturation * pickerWidth)
            .clamp(0.0, pickerWidth)
            .toDouble();
        final indicatorTop = ((1 - value) * pickerHeight)
            .clamp(0.0, pickerHeight)
            .toDouble();
        final hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();

        void handlePosition(Offset localPosition) {
          final nextSaturation = (localPosition.dx / pickerWidth)
              .clamp(0.0, 1.0)
              .toDouble();
          final nextValue = (1 - (localPosition.dy / pickerHeight))
              .clamp(0.0, 1.0)
              .toDouble();
          onChanged(saturation: nextSaturation, value: nextValue);
        }

        return GestureDetector(
          onTapDown: (details) => handlePosition(details.localPosition),
          onPanStart: (details) => handlePosition(details.localPosition),
          onPanUpdate: (details) => handlePosition(details.localPosition),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.12),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(decoration: BoxDecoration(color: hueColor)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.white, Colors.transparent],
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (indicatorLeft - 11)
                        .clamp(0.0, pickerWidth - 22)
                        .toDouble(),
                    top: (indicatorTop - 11)
                        .clamp(0.0, pickerHeight - 22)
                        .toDouble(),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.textPrimary,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sliderHeight = constraints.maxHeight;
          final indicatorTop = ((hue / 360) * sliderHeight)
              .clamp(0.0, sliderHeight)
              .toDouble();

          void handlePosition(Offset localPosition) {
            final nextHue = ((localPosition.dy / sliderHeight) * 360)
                .clamp(0.0, 360.0)
                .toDouble();
            onChanged(nextHue);
          }

          return GestureDetector(
            onTapDown: (details) => handlePosition(details.localPosition),
            onPanStart: (details) => handlePosition(details.localPosition),
            onPanUpdate: (details) => handlePosition(details.localPosition),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.textPrimary.withValues(alpha: 0.12),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.red,
                    Colors.yellow,
                    Colors.green,
                    Colors.cyan,
                    Colors.blue,
                    Colors.purple,
                    Colors.red,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 2,
                    right: 2,
                    top: (indicatorTop - 12)
                        .clamp(0.0, sliderHeight - 24)
                        .toDouble(),
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.textPrimary,
                          width: 2,
                        ),
                        color: Colors.transparent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  const _DialogTextField({
    required this.controller,
    required this.hintText,
    required this.enabled,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        enabled: enabled,
        inputFormatters: inputFormatters,
        cursorColor: AppColors.textPrimary,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.grey1,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _DialogErrorCard extends StatelessWidget {
  const _DialogErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.red1.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.red1.withValues(alpha: 0.24)),
      ),
      child: AppTextView.body3(
        message,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _DialogCloseButton extends StatelessWidget {
  const _DialogCloseButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppOverlayCloseButton(onTap: onTap);
  }
}

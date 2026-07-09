import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_view.dart';
import '../chat_strings.dart';
import '../providers/kaizengram_chat_controller.dart';

class CreateChannelBottomSheet extends StatefulWidget {
  const CreateChannelBottomSheet({super.key, required this.controller});

  final KaizengramChatController controller;

  @override
  State<CreateChannelBottomSheet> createState() =>
      _CreateChannelBottomSheetState();
}

class _CreateChannelBottomSheetState extends State<CreateChannelBottomSheet> {
  late final TextEditingController _textController = TextEditingController();
  String? _errorText;
  String? _selectedImagePath;
  var _isPickingImage = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          decoration: const BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const AppTextView.body1(
                KaizengramChatStrings.createChannelTitle,
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 6),
              const AppTextView.body2(
                KaizengramChatStrings.createChannelSubtitle,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              AppTextView.body2(
                KaizengramChatStrings.createChannelImageLabel,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isPickingImage ? null : _handlePickImage,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF24283D),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.textPrimary.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 58,
                            height: 58,
                            child: _selectedImagePath == null
                                ? Container(
                                    color: AppColors.surfaceDark3,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.tag_rounded,
                                      color: AppColors.secondaryColor,
                                      size: 24,
                                    ),
                                  )
                                : Image.file(
                                    File(_selectedImagePath!),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              AppTextView.body2(
                                _selectedImagePath == null
                                    ? KaizengramChatStrings
                                          .createChannelImageHint
                                    : KaizengramChatStrings.actionChangeImage,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              const SizedBox(height: 4),
                              AppTextView.body3(
                                _selectedImagePath == null
                                    ? KaizengramChatStrings.actionAddImage
                                    : KaizengramChatStrings
                                          .createChannelImageSelectedHint,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _isPickingImage
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textPrimary,
                                ),
                              )
                            : Icon(
                                _selectedImagePath == null
                                    ? Icons.add_photo_alternate_outlined
                                    : Icons.edit_outlined,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                maxLength: 20,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: KaizengramChatStrings.channelNameLabel,
                  hintText: KaizengramChatStrings.channelNameHint,
                  errorText: _errorText,
                  filled: true,
                  fillColor: const Color(0xFF24283D),
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.secondaryColor,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.red1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.red1),
                  ),
                ),
                onChanged: (_) {
                  if (_errorText == null) {
                    return;
                  }
                  setState(() => _errorText = null);
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                text: KaizengramChatStrings.actionCreate,
                onPressed: _handleCreateChannel,
                borderRadius: 14,
                minimumHeight: 48,
              ),
              const SizedBox(height: 10),
              AppButton(
                text: KaizengramChatStrings.actionCancel,
                onPressed: () => Navigator.of(context).pop(),
                backgroundColor: const Color(0xFF24283D),
                borderRadius: 14,
                minimumHeight: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCreateChannel() {
    final validationMessage = widget.controller.validateChannelName(
      _textController.text,
    );
    if (validationMessage != null) {
      setState(() => _errorText = validationMessage);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final createdChannel = widget.controller.createChannel(
      _textController.text,
      imagePath: _selectedImagePath,
    );
    Navigator.of(context).pop(createdChannel);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            KaizengramChatStrings.channelCreatedSnackBar(createdChannel),
          ),
        ),
      );
  }

  Future<void> _handlePickImage() async {
    setState(() {
      _isPickingImage = true;
    });

    try {
      final selectedImagePath = await widget.controller.pickChannelImage();
      if (!mounted || selectedImagePath == null || selectedImagePath.isEmpty) {
        return;
      }

      setState(() {
        _selectedImagePath = selectedImagePath;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(KaizengramChatStrings.pickChannelImageError),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      } else {
        _isPickingImage = false;
      }
    }
  }
}

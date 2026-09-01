import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class DepartmentColorPalette {
  DepartmentColorPalette._();

  static const String fallbackHex = '#A67DFF';

  static String normalizeHex(String? value) {
    final cleaned = value?.trim().toUpperCase().replaceAll(' ', '') ?? '';
    if (cleaned.isEmpty) {
      return '';
    }

    final raw = cleaned.startsWith('#') ? cleaned.substring(1) : cleaned;
    if (raw.isEmpty) {
      return '';
    }

    return '#$raw';
  }

  static String displayHex(String? value) {
    final normalized = normalizeHex(value);
    if (isValidHex(normalized)) {
      return normalized;
    }

    return fallbackHex;
  }

  static bool isValidHex(String value) {
    return RegExp(r'^#[0-9A-F]{6}$').hasMatch(normalizeHex(value));
  }

  static Color resolveColor(String? value) {
    final normalized = normalizeHex(value);
    if (!isValidHex(normalized)) {
      return AppColors.secondaryColor;
    }

    final raw = normalized.substring(1);
    return Color(int.parse(raw, radix: 16) | 0xFF000000);
  }

  static HSVColor resolveHsvColor(String? value) {
    return HSVColor.fromColor(resolveColor(displayHex(value)));
  }

  static String hexFromColor(Color color) {
    final red = ((color.r * 255.0).round() & 0xff)
        .toRadixString(16)
        .padLeft(2, '0')
        .toUpperCase();
    final green = ((color.g * 255.0).round() & 0xff)
        .toRadixString(16)
        .padLeft(2, '0')
        .toUpperCase();
    final blue = ((color.b * 255.0).round() & 0xff)
        .toRadixString(16)
        .padLeft(2, '0')
        .toUpperCase();
    return '#$red$green$blue';
  }
}

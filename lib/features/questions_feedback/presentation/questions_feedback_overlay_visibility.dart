import 'package:flutter/foundation.dart';

/// Coordinates feature-owned modal visibility with the app-level shortcut.
class QuestionsFeedbackOverlayVisibility {
  QuestionsFeedbackOverlayVisibility._();

  static final ValueNotifier<bool> isCreateSheetOpen = ValueNotifier<bool>(
    false,
  );

  static void setCreateSheetOpen(bool isOpen) {
    if (isCreateSheetOpen.value != isOpen) {
      isCreateSheetOpen.value = isOpen;
    }
  }
}

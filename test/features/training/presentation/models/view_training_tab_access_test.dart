// ignore_for_file: depend_on_referenced_packages

import 'package:test/test.dart';
import 'package:sparrowkaizen/features/training/presentation/models/view_training_tab_access.dart';

void main() {
  for (final canManage in [false, true]) {
    test('Quiz and Assignment require edit permission (can manage: $canManage)', () {
      for (final index in [0, 1, 2, 3]) {
        expect(
          isTrainingViewerTabEnabled(canManageTraining: canManage, tabIndex: index),
          index < 2 || canManage,
        );
      }
    });

    test('normalizes restricted selections (can manage: $canManage)', () {
      for (final index in [2, 3]) {
        expect(
          normalizeTrainingViewerTabIndex(canManageTraining: canManage, tabIndex: index),
          canManage ? index : 0,
        );
      }
    });
  }

  test('only Video is available before a lesson is selected', () {
    for (final canManage in [false, true]) {
      expect(maxTrainingTabIndex(hasSelectedModule: false, canManageTraining: canManage), 0);
    }
  });

  test('indices outside the four viewer tabs are disabled', () {
    for (final index in [-1, 4, 999]) {
      expect(isTrainingViewerTabEnabled(canManageTraining: true, tabIndex: index), isFalse);
    }
  });

  test('invalid indices return to Video', () {
    for (final index in [-1, 4, 999]) {
      expect(normalizeTrainingViewerTabIndex(canManageTraining: true, tabIndex: index), 0);
    }
  });
}

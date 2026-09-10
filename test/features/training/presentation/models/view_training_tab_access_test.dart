// ignore_for_file: depend_on_referenced_packages

import 'package:test/test.dart';
import 'package:sparrowkaizen/features/training/presentation/models/view_training_tab_access.dart';

void main() {
  for (final isPublic in [false, true]) {
    for (final isChild in [false, true]) {
      test('allows every viewer tab (public: $isPublic, child: $isChild)', () {
        for (final index in [0, 1, 2, 3]) {
          expect(
            isTrainingViewerTabEnabled(
              isPubliclyAvailable: isPublic,
              isChildOrganization: isChild,
              tabIndex: index,
            ),
            isTrue,
          );
        }
      });

      test('preserves selected Quiz and Assignment (public: $isPublic, child: $isChild)', () {
        for (final index in [2, 3]) {
          expect(
            normalizeTrainingViewerTabIndex(
              isPubliclyAvailable: isPublic,
              isChildOrganization: isChild,
              tabIndex: index,
            ),
            index,
          );
        }
      });
    }
  }

  test('indices outside the four viewer tabs are disabled', () {
    for (final index in [-1, 4, 999]) {
      expect(isTrainingViewerTabEnabled(isPubliclyAvailable: true, tabIndex: index), isFalse);
    }
  });

  test('invalid indices return to Video', () {
    for (final index in [-1, 4, 999]) {
      expect(normalizeTrainingViewerTabIndex(isPubliclyAvailable: true, tabIndex: index), 0);
    }
  });
}

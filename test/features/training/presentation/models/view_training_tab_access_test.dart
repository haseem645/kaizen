// ignore_for_file: depend_on_referenced_packages

import 'package:test/test.dart';
import 'package:sparrowkaizen/features/training/presentation/models/view_training_tab_access.dart';

void main() {
  group('isTrainingViewerTabEnabled', () {
    for (final isPubliclyAvailable in <bool>[false, true]) {
      test(
        'allows child organisations to view Quiz and Assignment (public: $isPubliclyAvailable)',
        () {
          for (final tabIndex in <int>[2, 3]) {
            expect(
              isTrainingViewerTabEnabled(
                isPubliclyAvailable: isPubliclyAvailable,
                tabIndex: tabIndex,
                isChildOrganization: true,
              ),
              isTrue,
            );
          }
        },
      );
    }

    test('allows all tabs when the lesson is not publicly available', () {
      expect(
        isTrainingViewerTabEnabled(isPubliclyAvailable: false, tabIndex: 0),
        isTrue,
      );
      expect(
        isTrainingViewerTabEnabled(isPubliclyAvailable: false, tabIndex: 1),
        isTrue,
      );
      expect(
        isTrainingViewerTabEnabled(isPubliclyAvailable: false, tabIndex: 2),
        isTrue,
      );
      expect(
        isTrainingViewerTabEnabled(isPubliclyAvailable: false, tabIndex: 3),
        isTrue,
      );
    });

    test('allows only the first two tabs when the lesson is public', () {
      expect(
        isTrainingViewerTabEnabled(isPubliclyAvailable: true, tabIndex: 0),
        isTrue,
      );
      expect(
        isTrainingViewerTabEnabled(isPubliclyAvailable: true, tabIndex: 1),
        isTrue,
      );
      expect(
        isTrainingViewerTabEnabled(isPubliclyAvailable: true, tabIndex: 2),
        isFalse,
      );
      expect(
        isTrainingViewerTabEnabled(isPubliclyAvailable: true, tabIndex: 3),
        isFalse,
      );
    });
  });

  group('normalizeTrainingViewerTabIndex', () {
    test('keeps child Quiz and Assignment tabs when a lesson is public', () {
      for (final tabIndex in <int>[2, 3]) {
        expect(
          normalizeTrainingViewerTabIndex(
            isPubliclyAvailable: true,
            tabIndex: tabIndex,
            isChildOrganization: true,
          ),
          tabIndex,
        );
      }
    });

    test('resets public Quiz and Assignment tabs after leaving a child', () {
      for (final tabIndex in <int>[2, 3]) {
        final childTabIndex = normalizeTrainingViewerTabIndex(
          isPubliclyAvailable: true,
          tabIndex: tabIndex,
          isChildOrganization: true,
        );

        expect(
          normalizeTrainingViewerTabIndex(
            isPubliclyAvailable: true,
            tabIndex: childTabIndex,
            isChildOrganization: false,
          ),
          0,
        );
      }
    });

    test('keeps allowed tabs unchanged', () {
      expect(
        normalizeTrainingViewerTabIndex(isPubliclyAvailable: true, tabIndex: 1),
        1,
      );
      expect(
        normalizeTrainingViewerTabIndex(
          isPubliclyAvailable: false,
          tabIndex: 3,
        ),
        3,
      );
    });

    test('moves disabled public tabs back to the first tab', () {
      expect(
        normalizeTrainingViewerTabIndex(isPubliclyAvailable: true, tabIndex: 2),
        0,
      );
      expect(
        normalizeTrainingViewerTabIndex(isPubliclyAvailable: true, tabIndex: 3),
        0,
      );
    });
  });
}

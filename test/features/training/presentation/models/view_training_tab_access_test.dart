// ignore_for_file: depend_on_referenced_packages

import 'package:test/test.dart';
import 'package:sparrowkaizen/features/training/presentation/models/view_training_tab_access.dart';

void main() {
  group('isTrainingViewerTabEnabled', () {
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

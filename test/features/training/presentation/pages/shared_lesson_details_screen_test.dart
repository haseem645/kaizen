import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/features/training/domain/entities/seat_description_training.dart';
import 'package:sparrowkaizen/features/training/domain/entities/shared_lesson_content.dart';
import 'package:sparrowkaizen/features/training/domain/repositories/shared_lms_repository.dart';
import 'package:sparrowkaizen/features/training/presentation/pages/shared_lesson_details_screen.dart';

void main() {
  testWidgets('shared lesson shows all four read-only tabs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SharedLessonDetailsScreen(
          sharedContentId: 'shared-list',
          publicId: 'lesson-public-id',
          sharedLmsRepository: _SharedLessonRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shared lesson'), findsWidgets);
    expect(find.text(AppStrings.trainingNoVideoAvailable), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(AppStrings.trainingSopTab).last);
    await tester.pumpAndSettle();

    expect(find.text('Shared SOP'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(AppStrings.trainingQuizTab).last);
    await tester.pumpAndSettle();

    expect(find.text('Shared question?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(AppStrings.trainingAssignmentTab).last);
    await tester.pumpAndSettle();

    expect(find.text('Shared assignment'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing shared list ID shows an error without a request', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SharedLessonDetailsScreen(
          sharedContentId: '',
          publicId: 'lesson-public-id',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.trainingSharedLessonUnavailable),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _SharedLessonRepository extends Fake implements SharedLmsRepository {
  @override
  Future<SharedLessonContent> getSharedLesson(
    String sharedContentId,
    String publicId,
  ) async {
    assert(sharedContentId == 'shared-list');
    assert(publicId == 'lesson-public-id');
    return const SharedLessonContent(
      module: SeatDescriptionTrainingModuleDetail(
        uuid: 'lesson-public-id',
        actualId: '',
        title: 'Shared lesson',
        thumbnails: <String>[],
        description: 'Summary',
        assignmentTitle: 'Shared assignment',
        assignmentInstructions: '<p>Assignment instructions</p>',
        questions: <SeatDescriptionTrainingQuestion>[
          SeatDescriptionTrainingQuestion(
            uuid: 'question-1',
            question: 'Shared question?',
            options: <SeatDescriptionTrainingQuestionOption>[
              SeatDescriptionTrainingQuestionOption(
                uuid: 'option-1',
                text: 'Answer',
              ),
            ],
            selectedOptionUuid: null,
            imageUrl: null,
          ),
        ],
        thumbnailLink: null,
        trainingVideo: null,
        isPubliclyAvailable: true,
        learningTrackCount: 0,
      ),
      document: SeatDescriptionTrainingDocument(
        uuid: '',
        text: '<p>Shared SOP</p>',
      ),
      assignment: SeatDescriptionTrainingAssignment(
        uuid: '',
        title: 'Shared assignment',
        instructions: '<p>Assignment instructions</p>',
      ),
    );
  }
}

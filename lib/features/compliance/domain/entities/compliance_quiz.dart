import 'compliance_quiz_question.dart';

class ComplianceQuiz {
  const ComplianceQuiz({
    required this.timeSpent,
    required this.questions,
    required this.temporaryAnswers,
    required this.quizAttemptUuid,
  });

  final int? timeSpent;
  final List<ComplianceQuizQuestion> questions;
  final Map<String, String> temporaryAnswers;
  final String? quizAttemptUuid;
}

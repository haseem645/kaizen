class ComplianceQuizResult {
  const ComplianceQuizResult({
    required this.uuid,
    required this.completionPercentage,
    required this.totalAttempts,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.totalTimeSpent,
    required this.isPassed,
    required this.questionResponses,
  });

  final String uuid;
  final double completionPercentage;
  final int totalAttempts;
  final int correctAnswers;
  final int totalQuestions;
  final int totalTimeSpent;
  final bool isPassed;
  final List<ComplianceQuizQuestionResponse> questionResponses;

  String get displayScore => '${_formatNumber(completionPercentage)}%';

  String get displayCorrectAnswers {
    if (totalQuestions <= 0) {
      return correctAnswers.toString();
    }

    return '$correctAnswers/$totalQuestions';
  }

  String get displayIncorrectAnswers {
    final value = (totalQuestions - correctAnswers).clamp(0, totalQuestions);
    if (totalQuestions <= 0) {
      return value.toString();
    }

    return '$value/$totalQuestions';
  }

  String get displayHeading => isPassed ? 'Congratulations!' : 'Great Effort! Let’s Try Again ';

  String get displayStatus => isPassed ? 'Pass' : 'Fail';

  String get displayTotalTimeSpent {
    final minutes = totalTimeSpent ~/ 60;
    final seconds = totalTimeSpent % 60;
    if (minutes <= 0) {
      return '${seconds}s';
    }

    return '${minutes}m ${seconds}s';
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }
}

class ComplianceQuizQuestionResponse {
  const ComplianceQuizQuestionResponse({
    required this.uuid,
    required this.isCorrect,
    required this.selectedOption,
    required this.question,
    required this.options,
    this.imageUrl,
  });

  final String uuid;
  final bool isCorrect;
  final String? selectedOption;
  final String question;
  final List<ComplianceQuizResultOption> options;
  final String? imageUrl;
}

class ComplianceQuizResultOption {
  const ComplianceQuizResultOption({required this.uuid, required this.text});

  final String uuid;
  final String text;
}

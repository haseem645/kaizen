import '../../../../core/constants/app_strings.dart';

enum TrainingLibraryFilter {
  seat,
  category,
  description;

  String get prefix => switch (this) {
    seat => AppStrings.trainingLibrarySeatFilterPrefix,
    category => AppStrings.trainingLibraryCategoryFilterPrefix,
    description => AppStrings.trainingLibraryDescriptionFilterPrefix,
  };
}

typedef TrainingLibraryFilterTag = ({TrainingLibraryFilter type, String label});

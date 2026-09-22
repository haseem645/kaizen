const int trainingViewerTabCount = 4;

int maxTrainingTabIndex({required bool hasSelectedModule, required bool canManageTraining}) =>
    !hasSelectedModule ? 0 : (canManageTraining ? trainingViewerTabCount - 1 : 1);

/// Video and SOP remain available without permission to edit the lesson.
bool isTrainingViewerTabEnabled({required bool canManageTraining, required int tabIndex}) {
  return tabIndex >= 0 &&
      tabIndex <=
          maxTrainingTabIndex(hasSelectedModule: true, canManageTraining: canManageTraining);
}

int normalizeTrainingViewerTabIndex({required bool canManageTraining, required int tabIndex}) {
  if (isTrainingViewerTabEnabled(canManageTraining: canManageTraining, tabIndex: tabIndex)) {
    return tabIndex;
  }

  return 0;
}

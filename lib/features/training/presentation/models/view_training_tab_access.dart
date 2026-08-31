const int trainingViewerCoreTabCount = 2;

bool isTrainingViewerTabEnabled({
  required bool isPubliclyAvailable,
  required int tabIndex,
}) {
  if (tabIndex < 0) {
    return false;
  }

  if (tabIndex < trainingViewerCoreTabCount) {
    return true;
  }

  return !isPubliclyAvailable;
}

int normalizeTrainingViewerTabIndex({
  required bool isPubliclyAvailable,
  required int tabIndex,
}) {
  if (isTrainingViewerTabEnabled(
    isPubliclyAvailable: isPubliclyAvailable,
    tabIndex: tabIndex,
  )) {
    return tabIndex;
  }

  return 0;
}

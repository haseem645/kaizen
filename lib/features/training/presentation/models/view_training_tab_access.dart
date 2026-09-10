const int trainingViewerTabCount = 4;

/// Lesson visibility and organisation type do not restrict read-only tabs.
bool isTrainingViewerTabEnabled({
  required bool isPubliclyAvailable,
  required int tabIndex,
  bool isChildOrganization = false,
}) {
  return tabIndex >= 0 && tabIndex < trainingViewerTabCount;
}

int normalizeTrainingViewerTabIndex({
  required bool isPubliclyAvailable,
  required int tabIndex,
  bool isChildOrganization = false,
}) {
  if (isTrainingViewerTabEnabled(
    isPubliclyAvailable: isPubliclyAvailable,
    tabIndex: tabIndex,
    isChildOrganization: isChildOrganization,
  )) {
    return tabIndex;
  }

  return 0;
}

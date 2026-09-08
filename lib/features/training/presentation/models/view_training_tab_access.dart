const int trainingViewerCoreTabCount = 2;

bool isTrainingViewerTabEnabled({
  required bool isPubliclyAvailable,
  required int tabIndex,
  bool isChildOrganization = false,
}) {
  if (tabIndex < 0) {
    return false;
  }

  if (tabIndex < trainingViewerCoreTabCount) {
    return true;
  }

  return isChildOrganization || !isPubliclyAvailable;
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

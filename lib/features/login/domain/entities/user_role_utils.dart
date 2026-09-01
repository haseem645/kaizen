String normalizeUserRole(String? value) {
  final normalizedValue = value?.trim().toLowerCase() ?? '';
  if (normalizedValue.isEmpty) {
    return '';
  }

  final collapsedValue = normalizedValue.replaceAll(RegExp(r'[^a-z0-9]+'), '');

  switch (collapsedValue) {
    case 'csuite':
      return 'csuite';
    case 'departmentlead':
    case 'deptlead':
      return 'dept_lead';
    case 'teamlead':
      return 'team_lead';
    case 'teammember':
      return 'team_member';
    default:
      return normalizedValue.replaceAll(RegExp(r'[\s-]+'), '_');
  }
}

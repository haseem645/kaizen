import '../../features/login/domain/entities/user.dart';
import '../../features/login/domain/entities/user_hierarchy_membership.dart';
import '../../features/organizations/domain/entities/organization.dart';

class AppPermissionUtils {
  const AppPermissionUtils._();

  static bool hasOwnerOverrideAccess(User? user) {
    final availableRoles = user?.normalizedRoles.toSet() ?? const <String>{};
    return user?.isOwner == true || availableRoles.contains('owner');
  }

  static bool canAccessSandbox(User? user) {
    return hasOwnerOverrideAccess(user) || user?.hasSandboxAccess == true;
  }

  static bool canAccessAuditTeamMembers(User? user) {
    final availableRoles = user?.normalizedRoles.toSet() ?? const <String>{};
    return hasOwnerOverrideAccess(user) ||
        availableRoles.contains('dept_lead') ||
        availableRoles.contains('supervisor') ||
        availableRoles.contains('team_lead');
  }

  static bool isChildOrganization(Organization? organization) {
    return organization?.type.trim().toLowerCase() == 'child';
  }

  static bool canModifyCurrentOrganizationContent({
    required Organization? currentOrganization,
  }) {
    return !isChildOrganization(currentOrganization);
  }

  static bool canCreateSeatProfiles({
    required User? user,
    required Organization? currentOrganization,
  }) {
    if (hasOwnerOverrideAccess(user)) {
      return true;
    }

    if (!canModifyCurrentOrganizationContent(
      currentOrganization: currentOrganization,
    )) {
      return false;
    }

    final availableRoles = user?.normalizedRoles.toSet() ?? const <String>{};
    return availableRoles.contains('csuite') ||
        availableRoles.contains('dept_lead') ||
        availableRoles.contains('team_lead');
  }

  static bool canManageAnyTrainingModules({
    required User? user,
    required Organization? currentOrganization,
  }) {
    if (hasOwnerOverrideAccess(user)) {
      return true;
    }

    if (!canModifyCurrentOrganizationContent(
      currentOrganization: currentOrganization,
    )) {
      return false;
    }

    for (final membership
        in user?.hierarchyMemberships ?? const <UserHierarchyMembership>[]) {
      if (membership.canManageTrainingModules) {
        return true;
      }
    }

    return false;
  }

  static bool occupiesSeatProfile({
    required User? user,
    required String seatProfileId,
  }) {
    final normalizedSeatProfileId = seatProfileId.trim();
    if (normalizedSeatProfileId.isEmpty) {
      return false;
    }

    for (final membership
        in user?.hierarchyMemberships ?? const <UserHierarchyMembership>[]) {
      if (membership.job?.uuid.trim() == normalizedSeatProfileId) {
        return true;
      }
    }

    return false;
  }

  static bool canManageTrainingForSeatProfile({
    required User? user,
    required Organization? currentOrganization,
    required String seatProfileId,
  }) {
    if (hasOwnerOverrideAccess(user)) {
      return true;
    }

    final normalizedSeatProfileId = seatProfileId.trim();
    if (normalizedSeatProfileId.isEmpty) {
      return false;
    }

    if (!canModifyCurrentOrganizationContent(
      currentOrganization: currentOrganization,
    )) {
      return false;
    }

    if (occupiesSeatProfile(
      user: user,
      seatProfileId: normalizedSeatProfileId,
    )) {
      return false;
    }

    for (final membership
        in user?.hierarchyMemberships ?? const <UserHierarchyMembership>[]) {
      if (!membership.canManageTrainingModules) {
        continue;
      }

      if (membership.manageableSeatProfileIds.contains(
        normalizedSeatProfileId,
      )) {
        return true;
      }
    }

    return false;
  }
}

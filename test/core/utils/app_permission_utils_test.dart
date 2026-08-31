// ignore_for_file: depend_on_referenced_packages

import 'package:test/test.dart';
import 'package:sparrowkaizen/core/utils/app_permission_utils.dart';
import 'package:sparrowkaizen/features/login/domain/entities/organization_hierarchy_job.dart';
import 'package:sparrowkaizen/features/login/domain/entities/organization_hierarchy_node.dart';
import 'package:sparrowkaizen/features/login/domain/entities/organization_hierarchy_profile.dart';
import 'package:sparrowkaizen/features/login/domain/entities/user.dart';
import 'package:sparrowkaizen/features/login/domain/entities/user_hierarchy_membership.dart';
import 'package:sparrowkaizen/features/organizations/domain/entities/organization.dart';

void main() {
  group('AppPermissionUtils.canAccessScopedCreateEntry', () {
    test('allows owner accounts to open scoped create flows', () {
      final canAccess = AppPermissionUtils.canAccessScopedCreateEntry(
        User(isOwner: true),
      );

      expect(canAccess, isTrue);
    });

    test('does not allow accounts with an empty roles list', () {
      final canAccess = AppPermissionUtils.canAccessScopedCreateEntry(
        User(roles: const <String>[]),
      );

      expect(canAccess, isFalse);
    });

    test('does not allow accounts that are only team members', () {
      final canAccess = AppPermissionUtils.canAccessScopedCreateEntry(
        User(roles: const <String>['team_member']),
      );

      expect(canAccess, isFalse);
    });

    test('prefers elevated roles when team member is also present', () {
      final canAccess = AppPermissionUtils.canAccessScopedCreateEntry(
        User(roles: const <String>['team_member', 'team_lead']),
      );

      expect(canAccess, isTrue);
    });

    test('allows any non-team-member role to open scoped create flows', () {
      final canAccess = AppPermissionUtils.canAccessScopedCreateEntry(
        User(roles: const <String>['dept_lead']),
      );

      expect(canAccess, isTrue);
    });
  });

  group('AppPermissionUtils.canManageTrainingForSeatProfile', () {
    const parentOrganization = Organization(
      id: 'org-1',
      name: 'Parent Org',
      website: null,
      contactNo: null,
      address: null,
      createdAt: '2026-08-28T00:00:00.000Z',
      type: 'parent',
      logoUrl: null,
    );

    test('allows managers to edit explicitly managed child seat profiles', () {
      final user = User(
        roles: const <String>['dept_lead'],
        hierarchyMemberships: const <UserHierarchyMembership>[
          UserHierarchyMembership(
            nodeUuid: 'node-1',
            role: 'dept_lead',
            manageableSeatProfileIds: <String>['seat-42'],
          ),
        ],
      );

      final canManage = AppPermissionUtils.canManageTrainingForSeatProfile(
        user: user,
        currentOrganization: parentOrganization,
        seatProfileId: 'seat-42',
      );

      expect(canManage, isTrue);
    });

    test('does not allow unlisted seat profiles for lead accounts', () {
      final user = User(
        roles: const <String>['dept_lead'],
        hierarchyMemberships: const <UserHierarchyMembership>[
          UserHierarchyMembership(
            nodeUuid: 'node-1',
            role: 'dept_lead',
            job: OrganizationHierarchyJob(uuid: 'seat-1', title: 'Lead Seat'),
            manageableSeatProfileIds: <String>['seat-managed'],
          ),
        ],
      );

      final canManage = AppPermissionUtils.canManageTrainingForSeatProfile(
        user: user,
        currentOrganization: parentOrganization,
        seatProfileId: 'seat-1',
      );

      expect(canManage, isFalse);
    });

    test('matches manageable seat ids across normalized alternate ids', () {
      final user = User(
        roles: const <String>['team_lead'],
        hierarchyMemberships: const <UserHierarchyMembership>[
          UserHierarchyMembership(
            nodeUuid: 'node-1',
            role: 'team_lead',
            manageableSeatProfileIds: <String>[' seat-managed '],
          ),
        ],
      );

      final canManage = AppPermissionUtils.canManageTrainingForSeatProfile(
        user: user,
        currentOrganization: parentOrganization,
        seatProfileId: 'seat-public-id',
        additionalSeatProfileIds: const <String>['SEAT-MANAGED'],
      );

      expect(canManage, isTrue);
    });

    test(
      'prefers team lead access when another membership is only team member',
      () {
        final user = User(
          roles: const <String>['team_lead', 'team_member'],
          hierarchyMemberships: const <UserHierarchyMembership>[
            UserHierarchyMembership(
              nodeUuid: 'node-member',
              role: 'team_member',
              job: OrganizationHierarchyJob(
                uuid: 'seat-own',
                title: 'Own Seat',
              ),
            ),
            UserHierarchyMembership(
              nodeUuid: 'node-lead',
              role: 'team_lead',
              job: OrganizationHierarchyJob(
                uuid: 'seat-own',
                title: 'Own Seat',
              ),
              manageableSeatProfileIds: <String>['seat-managed'],
            ),
          ],
        );

        final canManage = AppPermissionUtils.canManageTrainingForSeatProfile(
          user: user,
          currentOrganization: parentOrganization,
          seatProfileId: 'seat-own',
          additionalSeatProfileIds: const <String>['seat-managed'],
        );

        expect(canManage, isTrue);
      },
    );

    test('does not allow training management when the roles list is empty', () {
      final user = User(
        roles: const <String>[],
        hierarchyMemberships: const <UserHierarchyMembership>[
          UserHierarchyMembership(
            nodeUuid: 'node-1',
            role: 'team_lead',
            manageableSeatProfileIds: <String>['seat-managed'],
          ),
        ],
      );

      final canManage = AppPermissionUtils.canManageTrainingForSeatProfile(
        user: user,
        currentOrganization: parentOrganization,
        seatProfileId: 'seat-managed',
      );

      expect(canManage, isFalse);
    });

    test(
      'allows csuite users to manage training without explicit seat mappings',
      () {
        final user = User(roles: const <String>['c_suite']);

        final canManage = AppPermissionUtils.canManageTrainingForSeatProfile(
          user: user,
          currentOrganization: parentOrganization,
          seatProfileId: 'seat-99',
        );

        expect(canManage, isTrue);
      },
    );
  });

  group('AppPermissionUtils seat profile permissions', () {
    const parentOrganization = Organization(
      id: 'org-1',
      name: 'Parent Org',
      website: null,
      contactNo: null,
      address: null,
      createdAt: '2026-08-28T00:00:00.000Z',
      type: 'parent',
      logoUrl: null,
    );

    test(
      'allows department leads to manage seat profiles in their department',
      () {
        final user = User(
          roles: const <String>['dept_lead'],
          hierarchyMemberships: const <UserHierarchyMembership>[
            UserHierarchyMembership(
              nodeUuid: 'node-1',
              role: 'dept_lead',
              departmentUuid: 'dept-1',
            ),
          ],
        );

        final canManage = AppPermissionUtils.canManageSeatProfileDepartment(
          user: user,
          currentOrganization: parentOrganization,
          departmentId: 'dept-1',
        );

        expect(canManage, isTrue);
      },
    );

    test(
      'does not allow seat profile edits outside the managed department',
      () {
        final user = User(
          roles: const <String>['team_lead'],
          hierarchyMemberships: const <UserHierarchyMembership>[
            UserHierarchyMembership(
              nodeUuid: 'node-1',
              role: 'team_lead',
              departmentUuid: 'dept-1',
            ),
          ],
        );

        final canManage = AppPermissionUtils.canManageSeatProfileDepartment(
          user: user,
          currentOrganization: parentOrganization,
          departmentId: 'dept-2',
        );

        expect(canManage, isFalse);
      },
    );

    test(
      'does not allow seat profile creation when a lead account has no department scope',
      () {
        final user = User(roles: const <String>['team_lead']);

        final canCreate = AppPermissionUtils.canCreateSeatProfiles(
          user: user,
          currentOrganization: parentOrganization,
        );

        expect(canCreate, isFalse);
      },
    );

    test(
      'allows c_suite aliases to manage seat profiles across departments',
      () {
        final user = User(roles: const <String>['c_suite']);

        final canManage = AppPermissionUtils.canManageSeatProfileDepartment(
          user: user,
          currentOrganization: parentOrganization,
          departmentId: 'dept-9',
        );

        expect(canManage, isTrue);
      },
    );
  });

  group('AppPermissionUtils.canManagePaygrades', () {
    const parentOrganization = Organization(
      id: 'org-1',
      name: 'Parent Org',
      website: null,
      contactNo: null,
      address: null,
      createdAt: '2026-08-28T00:00:00.000Z',
      type: 'parent',
      logoUrl: null,
    );

    test('allows owners to manage paygrades', () {
      final user = User(isOwner: true);

      final canManage = AppPermissionUtils.canManagePaygrades(
        user: user,
        currentOrganization: parentOrganization,
      );

      expect(canManage, isTrue);
    });

    test('allows c_suite accounts to manage paygrades', () {
      final user = User(roles: const <String>['c_suite']);

      final canManage = AppPermissionUtils.canManagePaygrades(
        user: user,
        currentOrganization: parentOrganization,
      );

      expect(canManage, isTrue);
    });

    test('does not allow team leads to manage paygrades', () {
      final user = User(roles: const <String>['team_lead']);

      final canManage = AppPermissionUtils.canManagePaygrades(
        user: user,
        currentOrganization: parentOrganization,
      );

      expect(canManage, isFalse);
    });
  });

  group('OrganizationHierarchyNode.collectMembershipsForUser', () {
    test(
      'uses only the matched user node children as managed seat profiles',
      () {
        const loggedInProfileUuid = '2095f56d-0917-403a-b3aa-b98405460dcd';
        final rootNode = OrganizationHierarchyNode(
          uuid: '8b131d82-b6ab-452b-9fa8-b88755843e52',
          role: 'team_lead',
          job: const OrganizationHierarchyJob(
            uuid: '48b7e158-c1d8-4c4f-aa7b-cf28928c82e3',
            title: 'Frontend dev',
          ),
          profile: const OrganizationHierarchyProfile(
            name: 'Haseem Assistant',
            uuid: loggedInProfileUuid,
            email: 'haseemhussain761@gmail.com',
            image: 'https://media-dev.kaizenteams.ai/example.jpg',
            onboarded: true,
            userUuid: 'ccaf92a0-a5da-4227-a8b6-e1f136a75c3d',
          ),
          departmentUuid: '3a94043c-97e9-4dd0-8fbb-eebead1fcbdd',
          children: <OrganizationHierarchyNode>[
            OrganizationHierarchyNode(
              uuid: '5b9e5005-cb6a-4bd5-b287-f9267d3ebfa3',
              role: 'team_lead',
              job: const OrganizationHierarchyJob(
                uuid: 'ca901124-b4ea-4cd0-a594-5f1686ac03ff',
                title: 'Backend Dev',
              ),
              profile: const OrganizationHierarchyProfile(
                name: 'Gretchen Bradford',
                uuid: 'bcc954e5-6072-4a7b-b5ff-76d60ae4ad80',
                email: 'paze@mailinator.com',
                onboarded: true,
                userUuid: '287827f8-86d2-48f8-99ce-8c05ce5040b1',
              ),
              departmentUuid: '3a94043c-97e9-4dd0-8fbb-eebead1fcbdd',
              children: <OrganizationHierarchyNode>[
                OrganizationHierarchyNode(
                  uuid: 'grandchild-node',
                  role: 'team_member',
                  job: const OrganizationHierarchyJob(
                    uuid: 'grandchild-seat',
                    title: 'QA Dev',
                  ),
                  profile: const OrganizationHierarchyProfile(
                    name: 'Nested Report',
                    uuid: 'nested-profile',
                  ),
                ),
              ],
            ),
          ],
        );

        final memberships = rootNode.collectMembershipsForUser(<String>{
          loggedInProfileUuid.toLowerCase(),
        });

        expect(memberships, hasLength(1));
        expect(memberships.single.normalizedRole, 'team_lead');
        expect(memberships.single.manageableSeatProfileIds, const <String>[
          'ca901124-b4ea-4cd0-a594-5f1686ac03ff',
        ]);
      },
    );
  });
}

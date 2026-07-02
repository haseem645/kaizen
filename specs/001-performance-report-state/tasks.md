# Tasks: Performance Report State Cleanup

**Input**: Design documents from `/specs/001-performance-report-state/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/performance-report-view-state.md

**Tests**: Tests are not explicitly requested in the specification. This task list relies on targeted static analysis and manual validation from `quickstart.md`.

**Organization**: Tasks are grouped by user story to preserve independent implementation and validation.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g. US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare the feature docs and implementation context for a low-risk refactor

- [X] T001 Review current state ownership and mutable UI flows in `lib/features/audit/presentation/pages/performance_report_screen.dart`
- [X] T002 Review controller-backed report state dependencies in `lib/features/audit/presentation/providers/audit_controller.dart`
- [X] T003 [P] Review validation scenarios and expected parity in `specs/001-performance-report-state/quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the replacement state pattern before touching story-specific behavior

**⚠️ CRITICAL**: No user story work should begin until this phase is complete

- [X] T004 Define the local replacement state shape for `PerformanceReportScreen` in `lib/features/audit/presentation/pages/performance_report_screen.dart`
- [X] T005 Create or co-locate a notifier-backed view-state helper for screen-local mutable state in `lib/features/audit/presentation/pages/performance_report_screen.dart`
- [X] T006 Replace page-level state ownership entry points so the screen reads mutable UI state from the new mechanism in `lib/features/audit/presentation/pages/performance_report_screen.dart`
- [X] T007 Preserve `AuditController` as the single source of truth for API-backed report data in `lib/features/audit/presentation/providers/audit_controller.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Remove page-level mutable UI state (Priority: P1) 🎯 MVP

**Goal**: Remove page-level `setState` from the main performance report screen flow and replace it with explicit, predictable screen-local state ownership

**Independent Test**: Open `PerformanceReportScreen`, switch categories, refresh report-backed content, and confirm the visible category state stays correct without page-level `setState`

- [X] T008 [US1] Refactor selected category ownership to use the replacement local state mechanism in `lib/features/audit/presentation/pages/performance_report_screen.dart`
- [X] T009 [US1] Replace post-frame category reset repair logic with deterministic synchronization based on report identity in `lib/features/audit/presentation/pages/performance_report_screen.dart`
- [X] T010 [US1] Update category selection callbacks and derived rendering reads to consume the replacement state path in `lib/features/audit/presentation/pages/performance_report_screen.dart`
- [X] T011 [US1] Remove page-level `setState` usage tied to primary report-page transitions in `lib/features/audit/presentation/pages/performance_report_screen.dart`
- [X] T012 [US1] Run `flutter analyze lib/features/audit/presentation/pages/performance_report_screen.dart lib/features/audit/presentation/providers/audit_controller.dart` and record the result in `specs/001-performance-report-state/quickstart.md`

**Checkpoint**: User Story 1 should now be functional and independently verifiable

---

## Phase 4: User Story 2 - Preserve current report interactions (Priority: P2)

**Goal**: Keep time range, certified report, remarks, commitment, signature, and downstream navigation behavior unchanged while using the new state pattern

**Independent Test**: Exercise the existing interaction flows on `PerformanceReportScreen` and confirm user-visible behavior remains unchanged

- [X] T013 [US2] Refactor time-range selection flow to avoid page-level `setState` while preserving current behavior in `lib/features/audit/presentation/pages/performance_report_screen.dart`
- [X] T014 [US2] Replace dialog-local mutable state handling with an explicit transient state mechanism for the date-range picker in `lib/features/audit/presentation/pages/performance_report_screen.dart`
- [ ] T015 [P] [US2] Verify certified report selection, remarks generation, and commitment synchronization still bind correctly to controller state in `lib/features/audit/presentation/pages/performance_report_screen.dart`
- [ ] T016 [P] [US2] Verify signature actions and downstream description-report navigation remain behaviorally unchanged in `lib/features/audit/presentation/pages/performance_report_screen.dart`
- [ ] T017 [US2] Run the manual validation scenarios from `specs/001-performance-report-state/quickstart.md` and document any parity notes in `specs/001-performance-report-state/quickstart.md`

**Checkpoint**: User Stories 1 and 2 should both work without behavior regressions

---

## Phase 5: User Story 3 - Make future state changes easier to extend (Priority: P3)

**Goal**: Leave the screen with a clear, traceable state ownership model that future maintainers can extend safely

**Independent Test**: Review the refactored screen and confirm mutable values can be traced to either controller-owned data or the explicit local view-state mechanism

- [X] T018 [US3] Simplify `PerformanceReportScreen` state-reading structure so local mutable values are sourced from one explicit path in `lib/features/audit/presentation/pages/performance_report_screen.dart`
- [X] T019 [US3] Add concise code comments only where needed to explain non-obvious view-state synchronization in `lib/features/audit/presentation/pages/performance_report_screen.dart`
- [X] T020 [US3] Align the final screen implementation with the ownership rules documented in `specs/001-performance-report-state/contracts/performance-report-view-state.md`
- [X] T021 [US3] Perform a final maintainability pass to remove obsolete local-state scaffolding and dead synchronization code in `lib/features/audit/presentation/pages/performance_report_screen.dart`

**Checkpoint**: All user stories should now be independently satisfied

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and cross-cutting cleanup

- [X] T022 [P] Re-run `flutter analyze` for the touched audit presentation files in `lib/features/audit/presentation/pages/` and `lib/features/audit/presentation/providers/`
- [X] T023 [P] Update `specs/001-performance-report-state/quickstart.md` with final validation outcomes and any residual manual-check notes
- [X] T024 Verify the final implementation still honors the constitution principles documented in `.specify/memory/constitution.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - blocks all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational completion
- **User Story 2 (Phase 4)**: Depends on User Story 1 because the interaction-preservation work builds on the new state ownership pattern
- **User Story 3 (Phase 5)**: Depends on User Stories 1 and 2
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Establishes the replacement state mechanism and is the MVP scope
- **User Story 2 (P2)**: Requires the replacement mechanism from US1 to preserve behavior without reintroducing `setState`
- **User Story 3 (P3)**: Finalizes maintainability after the functional refactor is complete

### Parallel Opportunities

- T003 can run in parallel with T001-T002
- T015 and T016 can run in parallel after the US2 refactor path is in place
- T022 and T023 can run in parallel during polish

---

## Parallel Example: User Story 2

```bash
# After the time-range refactor is in place, these review/verification tasks can proceed together:
Task: "Verify certified report selection, remarks generation, and commitment synchronization in lib/features/audit/presentation/pages/performance_report_screen.dart"
Task: "Verify signature actions and downstream description-report navigation in lib/features/audit/presentation/pages/performance_report_screen.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Validate category switching and report refresh behavior
5. Stop for review if a minimal safe refactor checkpoint is desired

### Incremental Delivery

1. Establish explicit local view-state ownership
2. Migrate category-state behavior first
3. Migrate time-range and other interactive flows without changing behavior
4. Finish with clarity and maintainability cleanup
5. Run final static and manual validation

### Parallel Team Strategy

With multiple developers:

1. One developer establishes the foundational view-state mechanism
2. After US1 lands, one developer can verify report interaction parity while another performs maintainability cleanup prep
3. Final validation and documentation updates can be split in the polish phase

---

## Notes

- All tasks use the required checklist format with task IDs and exact file paths
- No explicit test-writing tasks are included because TDD/tests were not requested in the specification
- The suggested MVP scope is **User Story 1 only**

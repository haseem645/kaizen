# Feature Specification: Performance Report State Cleanup

**Feature Branch**: `[001-performance-report-state]`

**Created**: 2026-06-16

**Status**: Draft

**Input**: User description: "make PerformanceReportScreen setState function free and use its replacement for clean state change"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Remove page-level mutable UI state (Priority: P1)

As a maintainer of the performance report flow, I want `PerformanceReportScreen` to stop relying on page-level `setState` for its primary UI behavior so that state changes are predictable, easier to review, and aligned with the existing controller-driven architecture.

**Why this priority**: This is the core intent of the request and directly reduces fragile, scattered UI state handling in a business-critical screen.

**Independent Test**: Can be fully tested by opening the performance report, switching categories and date range options, and confirming the UI updates correctly without introducing regressions in loading, tab selection, or screen refresh behavior.

**Acceptance Scenarios**:

1. **Given** the performance report screen is opened, **When** report data loads or refreshes, **Then** the screen reflects the latest state without relying on page-level `setState` to keep visible selections in sync.
2. **Given** a user changes the selected category tab, **When** the selection changes, **Then** the displayed category description list updates through the replacement state mechanism and remains consistent after subsequent report refreshes.
3. **Given** the screen needs to reset derived UI selections because the underlying report changed, **When** the new report is applied, **Then** the reset occurs predictably and without post-frame `setState` patching on the page widget.

---

### User Story 2 - Preserve current report interactions (Priority: P2)

As a user viewing a performance report, I want all existing interactions on the screen to continue working the same way after the refactor so that the state cleanup does not change the product behavior I depend on.

**Why this priority**: The refactor is valuable only if it keeps the current experience intact while improving maintainability.

**Independent Test**: Can be tested by exercising the existing flows on the screen, including time range changes, certified report selection, remarks generation, signature actions, and category navigation.

**Acceptance Scenarios**:

1. **Given** the user changes the time range, **When** the report reloads, **Then** the selected time range, available data, and visible content remain behaviorally consistent with the current screen.
2. **Given** the user interacts with category descriptions and downstream navigation, **When** they open a description detail report, **Then** the navigation context and request parameters remain unchanged by the state refactor.
3. **Given** the user edits commitment text or signature-related actions, **When** state updates occur elsewhere on the page, **Then** those interactions continue to behave as they do today.

---

### User Story 3 - Make future state changes easier to extend (Priority: P3)

As a developer adding new behavior to `PerformanceReportScreen`, I want state ownership to be obvious and consolidated so that future UI changes can be added with lower regression risk.

**Why this priority**: This is the long-term maintainability outcome of the refactor and protects a large screen from becoming more brittle over time.

**Independent Test**: Can be evaluated by inspecting the updated state flow and verifying that interactive page state is owned by a clear replacement mechanism rather than multiple ad hoc `setState` calls.

**Acceptance Scenarios**:

1. **Given** a developer reads the screen implementation, **When** they trace state changes for category selection or dialog-driven choices, **Then** the owning mechanism is explicit and localized rather than scattered across page-level `setState` calls.
2. **Given** the screen is reviewed after the refactor, **When** reviewers inspect state transitions, **Then** they can identify a single consistent pattern for mutable UI state on the page.

### Edge Cases

- What happens when a refreshed report contains fewer category tabs than the previously selected category?
- How does the screen handle a state refresh that arrives while a transient UI element, such as the date-range dialog, is open?
- What happens when a user selects a custom range and then immediately switches back to the default range?
- How does the replacement state mechanism behave when the report is briefly null or loading during a reload?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `PerformanceReportScreen` MUST remove page-level `setState` usage for primary screen state changes tied to report rendering and category selection.
- **FR-002**: The screen MUST adopt a replacement state mechanism that fits the project’s existing state-management direction and keeps mutable page state explicit and predictable.
- **FR-003**: Category selection MUST continue to update the visible description list correctly after the refactor.
- **FR-004**: Derived UI resets caused by refreshed report data MUST be handled without post-frame page-level `setState` repair logic.
- **FR-005**: Existing time-range behavior MUST remain functionally unchanged for users after the refactor.
- **FR-006**: Existing certified-report selection, remarks generation, commitment editing, signature handling, and downstream navigation MUST remain functionally unchanged after the refactor.
- **FR-007**: The updated state flow MUST make it clear which layer owns mutable screen state and how that state is updated.
- **FR-008**: The refactor MUST avoid introducing new behavior changes unrelated to the state-management cleanup.
- **FR-009**: The resulting screen MUST continue to handle loading, empty, and refreshed report states without inconsistent UI selection or stale rendered data.

### Key Entities *(include if feature involves data)*

- **Performance Report View State**: The mutable UI state required to present the performance report screen, including selected category, selected time-range presentation state, and any derived visual state that must stay in sync with loaded report data.
- **Performance Report Data**: The loaded report content already supplied by controller/repository flow, including profile context, categories, remarks, certification data, and related report-driven UI sections.
- **Transient Selection Context**: The short-lived selection values used by the user while switching categories or choosing date ranges, which must remain stable and predictable across refreshes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Reviewers can inspect `PerformanceReportScreen` and find no page-level `setState` calls used for primary report-page state transitions.
- **SC-002**: A user can switch categories, refresh report data, and continue using the screen without seeing stale category content or incorrect tab selection.
- **SC-003**: A user can complete the existing performance report flows covered by the page without behavior regressions introduced by the refactor.
- **SC-004**: Developers can identify the owning mechanism for mutable screen state in one consistent pattern without tracing multiple unrelated local update paths.

## Assumptions

- The refactor should preserve the existing visual design and user-facing behavior unless a change is required to remove brittle state handling.
- Existing controller and repository behavior for loading report data remains the source of truth for business data on the page.
- A controller-backed or notifier-backed state replacement is acceptable as long as it aligns with the project’s current patterns and keeps state ownership clear.
- State cleanup is limited to `PerformanceReportScreen` and directly related helper flows unless a narrowly scoped supporting change is required nearby.

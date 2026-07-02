# Contract: Performance Report View State Ownership

## Purpose

Define the expected ownership boundaries for mutable state in `PerformanceReportScreen` after the refactor.

## State Ownership Rules

### Controller-Owned State

The following remains owned by `AuditController`:

- report loading flags
- loaded performance report data
- selected certified report identifier
- generated remarks state
- certification progress and related actions
- employee/facilitator signature state
- commitment value persisted as part of controller state

### Screen-Local View State

The following is owned by the screen-level replacement state mechanism:

- selected category index
- derived selection reset logic tied to report identity changes
- transient dialog selection state used before applying a custom date range
- any other purely presentational value that does not affect backend contracts or shared feature state

## Behavior Contract

1. The screen MUST not use page-level `setState` as the primary mechanism for report-page state transitions.
2. The visible category list MUST always reflect a valid selected category index derived from current report data.
3. When report identity changes, local selection state MUST either remain valid or reset deterministically to a valid fallback.
4. Dialog-local temporary state MUST be isolated from controller-owned business state until the user applies a selection.
5. API request parameters, route arguments, and downstream navigation identifiers MUST remain unchanged by this refactor.

## Verification Contract

- Reviewers should be able to trace each mutable value to either controller ownership or local view-state ownership.
- No stale category rendering should occur after report reloads or certified report changes.
- Manual verification should confirm unchanged user behavior for time-range selection, category switching, certification-related actions, and navigation to description details.

# GitHub Task Drafts: Performance Report State Cleanup

This file prepares GitHub-ready tasks for `haseem645/kaizen` based on `specs/001-performance-report-state/tasks.md`.

## Recommended Issue Structure

### Epic

- Title: `PerformanceReportScreen state cleanup`
  - Body summary:
    - Remove page-level `setState` from `PerformanceReportScreen`
    - Replace it with explicit local view-state ownership
    - Preserve existing report interactions and navigation behavior
    - Validate with `flutter analyze` and quickstart scenarios

### Child Issues

- Title: `Refactor PerformanceReportScreen category state ownership`
  - Covers: T004-T012

- Title: `Preserve PerformanceReportScreen interaction behavior after state refactor`
  - Covers: T013-T017

- Title: `Finalize PerformanceReportScreen maintainability cleanup`
  - Covers: T018-T024

## Copy-Paste Issue Bodies

### 1. Refactor PerformanceReportScreen category state ownership

Scope:
- Define explicit local view state
- Replace selected-category `setState` flow
- Remove post-frame repair logic
- Keep `AuditController` as the API-backed source of truth

Acceptance:
- No page-level `setState` remains for primary report-page state transitions
- Category selection stays valid through report refreshes
- `flutter analyze` passes on touched files

Reference:
- `specs/001-performance-report-state/spec.md`
- `specs/001-performance-report-state/plan.md`
- `specs/001-performance-report-state/tasks.md`

### 2. Preserve PerformanceReportScreen interaction behavior after state refactor

Scope:
- Refactor time-range flow without behavior changes
- Preserve certified report, remarks, commitment, signature, and navigation behavior
- Validate parity with quickstart scenarios

Acceptance:
- Existing interactions behave the same as before the refactor
- No API contract or navigation regressions are introduced

Reference:
- `specs/001-performance-report-state/spec.md`
- `specs/001-performance-report-state/quickstart.md`
- `specs/001-performance-report-state/tasks.md`

### 3. Finalize PerformanceReportScreen maintainability cleanup

Scope:
- Simplify state ownership readability
- Remove obsolete state scaffolding
- Align final code with the documented ownership contract
- Re-run final validation

Acceptance:
- Mutable values are traceable to controller-owned or explicit local view-state ownership
- Quickstart validation notes are updated
- Final static analysis passes

Reference:
- `specs/001-performance-report-state/contracts/performance-report-view-state.md`
- `specs/001-performance-report-state/tasks.md`

## Publishing Blocker

GitHub CLI is installed locally, but this environment is not authenticated:

```text
gh auth status
You are not logged into any GitHub hosts.
```

Once authenticated, these can be created with `gh issue create` in `haseem645/kaizen`.

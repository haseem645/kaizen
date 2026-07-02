# Research: Performance Report State Cleanup

## Decision 1: Use an explicit local view-state object backed by `ValueNotifier`

- **Decision**: Replace ad hoc page-level `setState` for screen-owned mutable UI state with a dedicated local view-state object managed through `ValueNotifier` and observed with `ValueListenableBuilder` or equivalent small-scope listeners.
- **Rationale**: The screen already uses `AuditController` as the source of truth for report data, but some transient UI concerns such as selected category and derived selection resets are local to the page. A notifier-backed local state keeps those concerns explicit without expanding controller scope unnecessarily or introducing a second large app-wide state pattern.
- **Alternatives considered**:
  - Move all transient UI state into `AuditController`: rejected because it would broaden controller responsibility for purely local presentation concerns.
  - Keep `setState` but reduce calls: rejected because it still leaves page-level mutable state opaque and only partially addresses the request.
  - Introduce a new Riverpod provider just for this screen: rejected because the current screen already depends on Provider and controller patterns, and a one-screen refactor should avoid introducing a parallel state-management style.

## Decision 2: Keep business report data in `AuditController`

- **Decision**: Continue to source report content, loading flags, certification actions, remarks generation, and API-driven state from `AuditController`.
- **Rationale**: The current architecture already centralizes report data and side effects there. The refactor target is UI-state predictability, not a business-layer redesign.
- **Alternatives considered**:
  - Split report data into a new controller: rejected because it would enlarge the refactor beyond the requested scope.
  - Cache extra report state locally in the widget tree: rejected because it risks divergence from the controller source of truth.

## Decision 3: Replace post-frame selection repair with deterministic derived-state synchronization

- **Decision**: Convert category reset behavior into deterministic synchronization logic tied to report identity changes rather than post-frame `setState` patches.
- **Rationale**: Post-frame fixes hide state transitions and make stale-selection bugs harder to reason about. The replacement should compute the next valid selection directly when report data changes.
- **Alternatives considered**:
  - Preserve the post-frame reset and only wrap it in a notifier: rejected because it keeps the same brittle timing pattern.
  - Always force category index to zero on rebuild: rejected because it would risk user-visible regressions and unnecessary resets.

## Decision 4: Isolate temporary dialog state from the page lifecycle

- **Decision**: For date-range and similar transient interactions, use a dedicated local state holder or extracted dialog component rather than `StatefulBuilder` callbacks tied to the page’s `setState`.
- **Rationale**: The user requested a setState-free screen. Temporary selection state can remain local, but it should be owned by an explicit dialog-level mechanism rather than anonymous builder state.
- **Alternatives considered**:
  - Leave `StatefulBuilder` in place: rejected because it still relies on `setState` in the same screen file and keeps dialog state less explicit.
  - Push dialog state into `AuditController`: rejected because it mixes temporary form state with persistent screen/business state.

## Decision 5: Preserve API and navigation contracts exactly

- **Decision**: Do not change route arguments, downstream identifiers, or API request wiring while performing the state cleanup.
- **Rationale**: The constitution prioritizes exact API contract wiring and low-risk changes. This refactor should improve state clarity without affecting request behavior.
- **Alternatives considered**:
  - Combine state cleanup with route or request refactors: rejected because it increases regression risk and broadens review scope.

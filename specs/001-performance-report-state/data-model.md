# Data Model: Performance Report State Cleanup

## Overview

This feature does not introduce backend entities or persistence changes. It clarifies the presentation-state model used by `PerformanceReportScreen`.

## Entities

### PerformanceReportViewState

- **Purpose**: Represents mutable, page-local UI state that is not business data and does not belong in API-backed controller state.
- **Fields**:
  - `selectedCategoryIndex`: currently active category tab index
  - `lastCategorySelectionKey`: identity token used to determine whether the loaded report changed in a way that should invalidate the current selection
  - `commitmentTextSyncMarker`: latest controller-backed commitment value already applied to the text controller, if explicit tracking remains necessary
  - `timeRangeDialogState` (optional nested state): temporary start date, end date, visible month, and selection mode for custom range picking when dialog-local state is externalized
- **Validation rules**:
  - `selectedCategoryIndex` must always resolve to a valid available tab index or default safely to `0`
  - derived synchronization markers must be recomputed from report identity rather than manually patched after build
- **State transitions**:
  - initial -> default empty values on screen creation
  - loaded -> selected category may remain current if still valid
  - refreshed with compatible tabs -> selection preserved
  - refreshed with incompatible tabs -> selection reset deterministically to a valid fallback

### PerformanceReportData

- **Purpose**: Represents the API-backed report data already owned by `AuditController`.
- **Fields referenced by this refactor**:
  - `profile.profileJob`
  - `profile.profileUuid`
  - `categoryTabs`
  - `remarkVersion`
  - `selectedCertifiedReportUuid`
  - certification and signature-related values
- **Validation rules**:
  - remains owned by controller state
  - local page state must never become a second source of truth for this data

### TimeRangeSelectionDraft

- **Purpose**: Represents temporary values while the user is choosing a custom date range before applying changes.
- **Fields**:
  - `selectedStart`
  - `selectedEnd`
  - `visibleMonth`
  - `selectionMode`
  - `dialogStep`
- **Validation rules**:
  - end date cannot resolve earlier than start date in the final applied selection
  - applying the draft must produce the same controller calls as today
- **State transitions**:
  - default options state
  - custom-range editing
  - applied
  - cancelled

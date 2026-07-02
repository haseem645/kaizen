# Quickstart: Performance Report State Cleanup Validation

## Prerequisites

- Flutter SDK installed and available on the path
- Project dependencies fetched with `flutter pub get`
- A runnable app configuration that can open `PerformanceReportScreen`

## Static Validation

Run:

```sh
flutter analyze lib/features/audit/presentation/pages/performance_report_screen.dart \
  lib/features/audit/presentation/providers/audit_controller.dart
```

Expected outcome:

- Analysis completes without errors
- No new warnings are introduced by the refactor in the touched files

Result:

- `flutter analyze lib/features/audit/presentation/pages/performance_report_screen.dart lib/features/audit/presentation/pages/performance_report_dialogs.dart lib/features/audit/presentation/providers/audit_controller.dart`
  passed on 2026-06-16 with no issues found

## Manual Validation Scenarios

### 1. Initial load

1. Launch the app and open `PerformanceReportScreen`
2. Wait for the report to load

Expected outcome:

- Report content loads normally
- Default category selection is valid
- No flicker or stale placeholder content remains after load

### 2. Category switching

1. Select a non-default category tab
2. Verify the description list updates
3. Trigger a report refresh path that causes report content to reload

Expected outcome:

- Category selection remains valid if the category still exists
- If the category is no longer valid, the screen resets to a valid fallback without broken UI
- No stale description rows remain visible

### 3. Time-range change

1. Switch from `This Quarter` to `Custom Date Range`
2. Select a range and apply it
3. Switch back to `This Quarter`

Expected outcome:

- The same controller-driven report reload behavior occurs as before
- Dialog interactions remain usable without inconsistent temporary state
- The screen reflects the correct resulting report and selection state

### 4. Existing action parity

1. Generate remarks
2. Interact with certified report selection
3. Use the description-row navigation action
4. If applicable, interact with commitment/signature-related controls

Expected outcome:

- Existing actions continue to function as before
- Navigation parameters and downstream report behavior remain unchanged
- No new regressions appear in unrelated screen sections

Current note:

- Static validation is complete
- Full manual in-app parity verification is still pending runtime execution

## Files to Review

- [spec.md](./spec.md)
- [plan.md](./plan.md)
- [research.md](./research.md)
- [data-model.md](./data-model.md)
- [contracts/performance-report-view-state.md](./contracts/performance-report-view-state.md)

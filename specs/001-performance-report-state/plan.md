# Implementation Plan: Performance Report State Cleanup

**Branch**: `[001-performance-report-state]` | **Date**: 2026-06-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-performance-report-state/spec.md`

**Note**: This plan focuses on removing `setState`-driven page state from `PerformanceReportScreen` and replacing it with explicit, low-risk state ownership aligned with the existing Provider-based flow.

## Summary

Refactor `PerformanceReportScreen` so mutable UI state is no longer coordinated through page-level `setState` or ad hoc post-frame repair logic. Keep business data in `AuditController`, introduce a small explicit local view-state mechanism for transient UI concerns, and preserve all current user-visible behavior for category selection, time-range changes, certification flows, and downstream navigation.

## Technical Context

**Language/Version**: Dart 3.9 with Flutter SDK  
**Primary Dependencies**: Flutter framework, `provider`, existing `AuditController`/repository flow  
**Storage**: N/A for this refactor; existing remote-backed report loading remains unchanged  
**Testing**: `flutter analyze`, existing `flutter_test` infrastructure if targeted widget coverage is added later  
**Target Platform**: Flutter mobile application for iOS and Android  
**Project Type**: Feature-first mobile app  
**Performance Goals**: Preserve current interaction responsiveness for category selection, date-range changes, and screen refreshes without visible flicker or stale content  
**Constraints**: No API contract changes, no user-facing behavior regressions, maintain existing screen structure and route behavior, keep change localized to the performance report flow  
**Scale/Scope**: One complex report screen plus directly related helper state objects/dialog handling within the same feature

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Feature-First Clean Architecture**: Pass. Changes remain inside `lib/features/audit/presentation` and do not move feature logic into `core`.
- **Exact and Safe API Contract Wiring**: Pass. This refactor does not intentionally change endpoint paths, query parameters, payloads, or repository contracts.
- **Predictable State and Navigation**: Pass with explicit design requirement. State ownership must move from scattered `setState` usage to a single traceable local state pattern plus existing controller state.
- **UI Consistency With the Current App**: Pass. The screen layout, interactions, and styling remain intact.
- **Small, Verifiable, Low-Risk Changes**: Pass. Scope is limited to one screen and nearby helper flow, with `flutter analyze` as the baseline verification gate.

## Project Structure

### Documentation (this feature)

```text
specs/001-performance-report-state/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── performance-report-view-state.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/
│   ├── preference/
│   ├── utils/
│   └── widgets/
├── features/
│   └── audit/
│       ├── data/
│       ├── domain/
│       └── presentation/
│           ├── pages/
│           │   ├── performance_report_screen.dart
│           │   └── seat_description_final_audit_report.dart
│           └── providers/
│               └── audit_controller.dart
└── routes/
```

**Structure Decision**: Keep the refactor within the existing audit feature presentation layer. Business report loading remains in `AuditController`, while screen-local transient state is represented explicitly in the performance report page or a colocated helper model without creating a new cross-feature abstraction.

## Complexity Tracking

No constitution violations are expected. A simpler “leave the screen as-is” option was rejected because scattered `setState` and post-frame repair logic make state ownership harder to follow and increase regression risk on a large report screen.

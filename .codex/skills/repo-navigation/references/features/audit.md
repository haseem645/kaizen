# Check-In Skill

This file is a lightweight routing index for `lib/features/check_in`.

Path style in this file:

- Use shortened repo-root paths starting with `.../`
- Treat `.../` as "this repository root"

## Audit Overview And Main Flow

Use for audit landing UI, top-level filters, overview behavior, and main audit navigation.

- First file: `.../lib/features/check_in/presentation/pages/check_in_screen.dart`
- Next if state or loading behavior changes: `.../lib/features/check_in/presentation/providers/check_in_controller.dart`
- Next if remote/local fetch behavior changes: `.../lib/features/check_in/data/datasources/audit_remote_data_source.dart`

## Audit Detail And Single Audit Views

Use for audit detail screens, single-description flows, report-category detail, and item-specific audit content.

- First file: `.../lib/features/check_in/presentation/pages/check_in_details_screen.dart`
- Next if single-item drilldown is involved: `.../lib/features/check_in/presentation/pages/single_check_in_details_screen.dart`
- Next if controller logic changes: `.../lib/features/check_in/presentation/providers/check_in_controller.dart`

## Audit Comments, Media, And Bottom Sheets

Use for media comments, check-in comment threads, selected media sync, upload/comment behavior, and comment bottom sheets.

- First file: `.../lib/features/check_in/presentation/pages/check_in_media_comments_bottom_sheet.dart`
- Next if media-comment widget behavior changes: `.../lib/features/check_in/presentation/widgets/description_media_comment_bottom_sheet.dart`
- Next if response/entity mapping changes: `.../lib/features/check_in/domain/entities/description_comments_response.dart`
- Next if remote API behavior changes: `.../lib/features/check_in/data/datasources/audit_remote_data_source.dart`

## Audit Reports And Performance

Use for audit reports, final audit report screens, performance reports, and snapshots.

- First file: `.../lib/features/check_in/presentation/pages/check_in_report.dart`
- Next for final audit report behavior: `.../lib/features/check_in/presentation/pages/seat_description_final_check_in_report.dart`
- Next for performance reporting: `.../lib/features/check_in/presentation/pages/performance_report_screen.dart`
- Next if data/state changes: `.../lib/features/check_in/presentation/providers/check_in_controller.dart`

## Audit Training

Training UI and controllers now live in the top-level training feature.

- Open: `.../.codex/skills/repo-navigation/references/features/training.md`
- Stay in audit only when changing the upstream audit entry points, route payloads, or audit API behavior that feeds training.

## Audit Filters, Team, And Shared Widgets

Use for audit filter sheets, team-member selection, audit cards, search, and shared audit widgets.

- First file: `.../lib/features/check_in/presentation/pages/check_in_filter_sheet.dart`
- Next for team-member flows: `.../lib/features/check_in/presentation/pages/View_all_team_members.dart`
- Supporting widgets:
- `.../lib/features/check_in/presentation/widgets/check_in_member_card.dart`
- `.../lib/features/check_in/presentation/widgets/check_in_search_bar.dart`
- `.../lib/features/check_in/presentation/widgets/check_in_status_switcher.dart`

## Default Audit Rule

If the task is ambiguous, start with `.../lib/features/check_in/presentation/pages/check_in_screen.dart` and widen only after confirming the task touches reports, comments, or detail flows.

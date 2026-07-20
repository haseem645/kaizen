# Audit Skill

This file is a lightweight routing index for `lib/features/audit`.

Path style in this file:

- Use shortened repo-root paths starting with `.../`
- Treat `.../` as "this repository root"

## Audit Overview And Main Flow

Use for audit landing UI, top-level filters, overview behavior, and main audit navigation.

- First file: `.../lib/features/audit/presentation/pages/audit_screen.dart`
- Next if state or loading behavior changes: `.../lib/features/audit/presentation/providers/audit_controller.dart`
- Next if remote/local fetch behavior changes: `.../lib/features/audit/data/datasources/audit_remote_data_source.dart`

## Audit Detail And Single Audit Views

Use for audit detail screens, single-description flows, report-category detail, and item-specific audit content.

- First file: `.../lib/features/audit/presentation/pages/audit_detail_screen.dart`
- Next if single-item drilldown is involved: `.../lib/features/audit/presentation/pages/single_audit_details_screen.dart`
- Next if controller logic changes: `.../lib/features/audit/presentation/providers/audit_controller.dart`

## Audit Comments, Media, And Bottom Sheets

Use for media comments, check-in comment threads, selected media sync, upload/comment behavior, and comment bottom sheets.

- First file: `.../lib/features/audit/presentation/pages/audit_media_comments_bottom_sheet.dart`
- Next if media-comment widget behavior changes: `.../lib/features/audit/presentation/widgets/description_media_comment_bottom_sheet.dart`
- Next if response/entity mapping changes: `.../lib/features/audit/domain/entities/description_comments_response.dart`
- Next if remote API behavior changes: `.../lib/features/audit/data/datasources/audit_remote_data_source.dart`

## Audit Reports And Performance

Use for audit reports, final audit report screens, performance reports, and snapshots.

- First file: `.../lib/features/audit/presentation/pages/audit_report.dart`
- Next for final audit report behavior: `.../lib/features/audit/presentation/pages/seat_description_final_audit_report.dart`
- Next for performance reporting: `.../lib/features/audit/presentation/pages/performance_report_screen.dart`
- Next if data/state changes: `.../lib/features/audit/presentation/providers/audit_controller.dart`

## Audit Filters, Team, And Shared Widgets

Use for audit filter sheets, team-member selection, audit cards, search, and shared audit widgets.

- First file: `.../lib/features/audit/presentation/pages/audit_filter_sheet.dart`
- Next for team-member flows: `.../lib/features/audit/presentation/pages/View_all_team_members.dart`
- Supporting widgets:
- `.../lib/features/audit/presentation/widgets/audit_member_card.dart`
- `.../lib/features/audit/presentation/widgets/audit_search_bar.dart`
- `.../lib/features/audit/presentation/widgets/audit_status_switcher.dart`

## Default Audit Rule

If the task is ambiguous, start with `.../lib/features/audit/presentation/pages/audit_screen.dart` and widen only after confirming the task touches reports, comments, or detail flows.

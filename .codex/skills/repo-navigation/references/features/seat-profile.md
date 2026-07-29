# Seat Profile Skill

This file is a lightweight routing index for `lib/features/seat_profile`.

Path style in this file:

- Use shortened repo-root paths starting with `.../`
- Treat `.../` as "this repository root"

## Seat Profile Shell And Lists

Use for seat-profile listing, filters, search, descriptions list, and main seat-profile flow.

- First file: `.../lib/features/seat_profile/presentation/pages/seat_profile_screen.dart`
- Next for descriptions flow: `.../lib/features/seat_profile/presentation/pages/seat_profile_descriptions_screen.dart`
- Next if list state changes: `.../lib/features/seat_profile/presentation/providers/seat_profile_controller.dart`

## Seat Profile Detail And Dialogs

Use for seat-profile detail pages, description dialogs, and detail-controller behavior.

- First file: `.../lib/features/seat_profile/presentation/pages/seat_profile_detail_screen.dart`
- Next for description dialog behavior: `.../lib/features/seat_profile/presentation/pages/seat_profile_description_dialog.dart`
- Next if detail state changes: `.../lib/features/seat_profile/presentation/providers/seat_profile_detail_controller.dart`

## Seat Profile Data And Mapping

Use for seat-profile remote data, repositories, department models, and entity/page mapping.

- First file: `.../lib/features/seat_profile/data/datasources/seat_profile_remote_data_source.dart`
- Next for repository behavior: `.../lib/features/seat_profile/data/repositories/seat_profile_repository_impl.dart`
- Next if search/filter UI changes: `.../lib/features/seat_profile/widgets/seat_profile_search_bar.dart`

## Seat Profile Training Setup

Seat-profile-driven training setup now lives in the top-level training feature.

- Open: `.../.codex/skills/repo-navigation/references/features/training.md`
- Stay in seat profile only when changing the seat-profile option sources or the entry route into training setup.

## Default Seat Profile Rule

If the task is ambiguous, start with `.../lib/features/seat_profile/presentation/pages/seat_profile_screen.dart`.

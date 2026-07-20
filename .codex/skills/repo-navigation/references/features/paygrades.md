# Paygrades Skill

This file is a lightweight routing index for `lib/features/paygrades`.

Path style in this file:

- Use shortened repo-root paths starting with `.../`
- Treat `.../` as "this repository root"

## Paygrades List And Detail Flow

Use for paygrades listing, detail screens, pagination behavior, and paygrade-specific presentation state.

- First file: `.../lib/features/paygrades/presentation/pages/paygrades_screen.dart`
- Next for detail behavior: `.../lib/features/paygrades/presentation/pages/paygrade_detail_screen.dart`
- Next if state changes: `.../lib/features/paygrades/presentation/providers/paygrades_controller.dart`

## Paygrades Data And Mapping

Use for paygrade remote data, repository behavior, page/detail mapping, and domain model changes.

- First file: `.../lib/features/paygrades/data/datasources/paygrade_remote_data_source.dart`
- Next for repository behavior: `.../lib/features/paygrades/data/repositories/paygrade_repository_impl.dart`
- Next for detail controller logic: `.../lib/features/paygrades/presentation/providers/paygrade_detail_controller.dart`

## Default Paygrades Rule

If the task is ambiguous, start with `.../lib/features/paygrades/presentation/pages/paygrades_screen.dart`.

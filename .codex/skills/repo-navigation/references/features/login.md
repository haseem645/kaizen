# Login Skill

This file is a lightweight routing index for `lib/features/login`.

Path style in this file:

- Use shortened repo-root paths starting with `.../`
- Treat `.../` as "this repository root"

## Login UI And Submission Flow

Use for login screen UI, field validation, loading/error state, and login submission behavior.

- First file: `.../lib/features/login/presentation/pages/login_screen.dart`
- Next if state changes: `.../lib/features/login/presentation/providers/login_controller.dart`
- Next if auth call behavior changes: `.../lib/features/login/data/datasources/auth_remote_data_source.dart`

## Related Auth Screens

Forgot-password and login-side set-password screens now live in the separate auth feature.

- Open: `.../.codex/skills/repo-navigation/references/features/auth.md`

## Login Data And Auth Mapping

Use for auth repository changes, login response mapping, stored login records, and domain entity adjustments.

- First file: `.../lib/features/login/data/repositories/auth_repository_impl.dart`
- Next for remote auth behavior: `.../lib/features/login/data/datasources/auth_remote_data_source.dart`
- Next for entities: `.../lib/features/login/domain/entities/app_user.dart`

## Default Login Rule

If the task is ambiguous, start with `.../lib/features/login/presentation/pages/login_screen.dart`.

# Auth Skill

This file is a lightweight routing index for `lib/features/auth`.

Path style in this file:

- Use shortened repo-root paths starting with `.../`
- Treat `.../` as "this repository root"

## Auth UI And Reset Flow

Use for forgot-password, login-side set-password, shared auth widgets, and validation helpers that follow the login visual system.

- First file: `.../lib/features/auth/presentation/pages/forgot_password_screen.dart`
- Next for password reset UI: `.../lib/features/auth/presentation/pages/set_password_screen.dart`
- Shared widgets: `.../lib/features/auth/presentation/widgets/auth_page_frame.dart`
- Validation helpers: `.../lib/features/auth/presentation/auth_validators.dart`

## Default Auth Rule

If the task is ambiguous, start with `.../lib/features/auth/presentation/pages/forgot_password_screen.dart`.

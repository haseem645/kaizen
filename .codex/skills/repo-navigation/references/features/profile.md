# Profile Skill

This file is a lightweight routing index for `lib/features/profile`.

Path style in this file:

- Use shortened repo-root paths starting with `.../`
- Treat `.../` as "this repository root"

## Profile UI And State

Use for profile screen UI, profile actions, and profile-specific controller behavior.

- First file: `.../lib/features/profile/presentation/pages/profile_screen.dart`
- Next if state changes: `.../lib/features/profile/presentation/providers/profile_controller.dart`

## Default Profile Rule

If the task is ambiguous, start with `.../lib/features/profile/presentation/pages/profile_screen.dart`.

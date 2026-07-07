# splash_skills.md

This file is a lightweight routing index for `lib/features/splash`.

Path style in this file:

- Use shortened repo-root paths starting with `.../`
- Treat `.../` as "this repository root"

## Splash Entry And Boot Flow

Use for splash screen UI, startup timing, boot navigation, and splash-controller behavior.

- First file: `.../lib/features/splash/presentation/pages/splash_screen.dart`
- Next if startup state/navigation changes: `.../lib/features/splash/presentation/providers/splash_controller.dart`

## Default Splash Rule

If the task is ambiguous, start with `.../lib/features/splash/presentation/pages/splash_screen.dart`.

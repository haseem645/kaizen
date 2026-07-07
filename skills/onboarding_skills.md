# onboarding_skills.md

This file is a lightweight routing index for `lib/features/onboarding`.

Path style in this file:

- Use shortened repo-root paths starting with `.../`
- Treat `.../` as "this repository root"

## Onboarding Screens And State

Use for set-password flow, profile-image setup, onboarding navigation, and onboarding controller behavior.

- First file: `.../lib/features/onboarding/presentation/pages/set_password_screen.dart`
- Next for profile-image setup: `.../lib/features/onboarding/presentation/pages/set_profile_image_screen.dart`
- Next if state changes: `.../lib/features/onboarding/presentation/providers/onboarding_controller.dart`

## Default Onboarding Rule

If the task is ambiguous, start with `.../lib/features/onboarding/presentation/pages/set_password_screen.dart`.

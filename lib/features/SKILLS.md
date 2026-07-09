# SKILLS.md

This file is the parent index for feature-specific skill files in this repository.

Use it to keep context small:

- Read this file first.
- Open only the one `SKILL.md` file that matches the touched feature.
- Read the first linked file from that feature file before widening context.
- Do not scan unrelated features by default.

Path style in this file:

- Use shortened repo-root paths starting with `.../`
- Treat `.../` as "this repository root"

## Feature Skill Files

- Audit: `.../lib/features/audit/SKILL.md`
- Compliance: `.../lib/features/compliance/SKILL.md`
- Kaizen GPT: `.../lib/features/kaizen_gpt/SKILL.md`
- Kaizengram: `.../lib/features/kaizengram/SKILL.md`
- Login: `.../lib/features/login/SKILL.md`
- Onboarding: `.../lib/features/onboarding/SKILL.md`
- Organizations: `.../lib/features/organizations/SKILL.md`
- Paygrades: `.../lib/features/paygrades/SKILL.md`
- Profile: `.../lib/features/profile/SKILL.md`
- Seat Profile: `.../lib/features/seat_profile/SKILL.md`
- Splash: `.../lib/features/splash/SKILL.md`

## Shared App Touchpoints

Open these only if a task clearly crosses feature boundaries:

- Shared strings: `.../lib/core/constants/app_strings.dart`
- Shared user/app state: `.../lib/core/managers/app_manager.dart`
- App-level route wiring: `.../lib/routes/app_router.dart`

## Default Rule

If the module is unclear, identify the touched feature under `.../lib/features/` first, then open only the matching `SKILL.md` file.

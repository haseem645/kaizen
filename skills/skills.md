# skills.md

This file is the parent index for module-specific routing files in this repository.

Use it to keep context small:

- Read this file first.
- Open only the one `*_skills.md` file that matches the touched module.
- Read the first linked file from that module file before widening context.
- Do not scan unrelated modules by default.

Path style in this file:

- Use shortened repo-root paths starting with `.../`
- Treat `.../` as "this repository root"

## Feature Module Skill Files

- Audit: `.../skills/audit_skills.md`
- Compliance: `.../skills/compliance_skills.md`
- Kaizen GPT: `.../skills/kaizen_gpt_skills.md`
- Kaizengram: `.../skills/kaizengram_skills.md`
- Login: `.../skills/login_skills.md`
- Onboarding: `.../skills/onboarding_skills.md`
- Organizations: `.../skills/organizations_skills.md`
- Paygrades: `.../skills/paygrades_skills.md`
- Profile: `.../skills/profile_skills.md`
- Seat Profile: `.../skills/seat_profile_skills.md`
- Splash: `.../skills/splash_skills.md`

## Shared App Touchpoints

Open these only if a task clearly crosses feature boundaries:

- Shared strings: `.../lib/core/constants/app_strings.dart`
- Shared user/app state: `.../lib/core/managers/app_manager.dart`
- App-level route wiring: `.../lib/routes/app_router.dart`

## Default Rule

If the module is unclear, identify the touched feature under `.../lib/features/` first, then open only the matching `*_skills.md` file.

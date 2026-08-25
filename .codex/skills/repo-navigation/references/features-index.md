# Features Index

This file is the canonical feature-routing index for this repository.

Use it to keep context small:

- Read this file first.
- Open only the one feature reference that matches the touched area.
- Open the first linked implementation file from that feature reference before widening context.
- Do not scan unrelated features by default.

Path style in this file:

- Use shortened repo-root paths starting with `.../`
- Treat `.../` as "this repository root"

## Canonical Feature References

- Check-In: `.../.codex/skills/repo-navigation/references/features/audit.md`
- Compliance: `.../.codex/skills/repo-navigation/references/features/compliance.md`
- Kaizen GPT: `.../.codex/skills/repo-navigation/references/features/kaizen-gpt.md`
- Kaizengram: `.../.codex/skills/repo-navigation/references/features/kaizengram.md`
- Login: `.../.codex/skills/repo-navigation/references/features/login.md`
- Onboarding: `.../.codex/skills/repo-navigation/references/features/onboarding.md`
- Organizations: `.../.codex/skills/repo-navigation/references/features/organizations.md`
- Paygrades: `.../.codex/skills/repo-navigation/references/features/paygrades.md`
- Profile: `.../.codex/skills/repo-navigation/references/features/profile.md`
- Seat Profile: `.../.codex/skills/repo-navigation/references/features/seat-profile.md`
- Splash: `.../.codex/skills/repo-navigation/references/features/splash.md`
- Training: `.../.codex/skills/repo-navigation/references/features/training.md`

## Shared App Touchpoints

Open these only if a task clearly crosses feature boundaries:

- Repo-wide rules: `.../AGENTS.md`
- Shared strings: `.../lib/core/constants/app_strings.dart`
- Shared user/app state: `.../lib/core/managers/app_manager.dart`
- App-level route wiring: `.../lib/routes/app_router.dart`

## Source Of Truth

Use the `.codex` feature references directly. Legacy `lib/features/**/SKILL.md` shims have been removed.

## Default Rule

If the module is unclear, identify the touched feature under `.../lib/features/` first, then open only the matching canonical feature reference.

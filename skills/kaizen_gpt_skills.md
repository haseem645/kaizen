# kaizen_gpt_skills.md

This file is a lightweight routing index for `lib/features/kaizen_gpt`.

Path style in this file:

- Use shortened repo-root paths starting with `.../`
- Treat `.../` as "this repository root"

## Kaizen GPT UI And State

Use for the Kaizen GPT screen, message flow, loading state, and feature-specific controller behavior.

- First file: `.../lib/features/kaizen_gpt/presentation/pages/kaizen_gpt.dart`
- Next if state or request flow changes: `.../lib/features/kaizen_gpt/presentation/providers/kaizen_gpt_controller.dart`

## Default Kaizen GPT Rule

If the task is ambiguous, start with `.../lib/features/kaizen_gpt/presentation/pages/kaizen_gpt.dart`.

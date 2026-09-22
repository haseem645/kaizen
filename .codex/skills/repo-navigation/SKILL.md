---
name: repo-navigation
description: Use when working in this kaizen Flutter repository and you need repo-specific routing guidance, feature entrypoints, or instructions on which files to open first. Read the feature index first, then open only the matching feature reference instead of scanning unrelated modules.
---

# Repo Navigation

This skill is the canonical home for repository navigation guidance in this project.

## Read Order

1. Keep the root `AGENTS.md` as the canonical repo-wide rules file because Codex auto-discovers that path.
2. Read `references/features-index.md` first for feature routing.
3. Open only the matching file under `references/features/`.
4. Open the first linked implementation file from that feature reference before widening context.
5. Expand to controller, data, routing, or shared files only when the task clearly crosses that boundary.

## Canonical References

- Feature index: `references/features-index.md`
- Feature routing files: `references/features/*.md`

## Source Of Truth

- The `.codex` routing files are the maintained source of truth.
- Feature-level `lib/features/**/SKILL.md` compatibility shims have been removed.

## Implementation Rule

- Do not use `setState()` to update widget or screen state in this project.
- For new or changed UI flows, use the project’s existing state update patterns such as `Provider`, `ChangeNotifier`, `ProxyProvider`, or the owning controller/provider logic already established in the touched feature.

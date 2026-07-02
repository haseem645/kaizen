# AGENTS.md

## Purpose

This file defines repository-level rules for Codex in this Flutter project.
Favor small, targeted changes that preserve existing architecture, naming, and UI behavior.

## Repository Expectations

This is a feature-first Flutter application organized under `lib/features`.
Most features follow `data`, `domain`, and `presentation` layers, but Codex should match the local pattern of the touched feature instead of forcing a rewrite.

## Repository Layout

- `lib/core/`
  Shared constants, config, managers, navigation, utilities, services, and reusable widgets.
- `lib/features/<feature>/`
  Feature code grouped by domain such as `presentation`, `data`, `domain`, and related models/providers.
- `lib/routes/`
  App-level route registration and navigation wiring.
- `lib/assets/images/`
  Bundled image assets used by the application.
- `third_party/`
  Local vendored packages. Do not edit unless the task explicitly requires it.
- `build/`, `.dart_tool/`
  Generated output. Do not modify manually.

## How To Work In This Repo

- Prefer following the existing feature structure instead of introducing a new architecture.
- Prefer the existing `Provider`, `ChangeNotifier`, and `ProxyProvider` patterns already used in the codebase. Do not introduce a new state-management approach without explicit approval.
- Keep mutable screen state in the owning controller/provider when that screen already follows that pattern.
- For strictly local widget state, `ValueNotifier` is acceptable when it keeps the code simpler and the surrounding file already uses that style.
- Reuse existing shared UI primitives such as `AppTextView`, `AppColors`, `DrawerMainScreen`, and existing utility helpers before creating new abstractions.
- Keep screen-specific helper widgets private in the same file when that is already the pattern for the surrounding code.
- Favor additive refactors over broad rewrites.

## Flutter Conventions

- Use null-safe Dart idioms and keep types explicit when they help readability.
- Respect the existing lint baseline from `analysis_options.yaml` and `package:flutter_lints/flutter.yaml`.
- Use `snake_case` for file names, `PascalCase` for types, and `_privateName` for file-private helpers.
- Prefer immutable widget inputs and `const` constructors where practical.
- Keep widget trees readable by extracting focused private widgets when a build method becomes too dense, but avoid creating unnecessary abstraction for tiny one-off UI fragments.
- For async UI actions, handle loading and failure states in the widget or provider that owns the interaction.
- Dispose owned controllers and notifiers such as `TextEditingController`, `ScrollController`, `PageController`, `TabController`, `AnimationController`, `VideoPlayerController`, and `ValueNotifier`.
- Use existing status/color conventions from `lib/core/constants/app_colors.dart` unless the task requires a new design rule.

## UI Rules

- Preserve the established visual system unless the task explicitly asks for a redesign.
- On new or changed screens, maintain mobile-first layout behavior and avoid overflow.
- Reuse existing spacing, typography, icon, and bottom-sheet patterns where possible instead of inventing a parallel style.
- If media, uploads, comments, or sheets already exist elsewhere in the app, mirror those interaction patterns before creating a new one.
- Long text, pills, tags, and action rows must be overflow-safe by using `Expanded`, `Flexible`, wrapping, or constrained layouts where appropriate.
- Media cards should use stable constraints. If a list or pager mixes images and videos, keep the video thumbnail container matched to the image container unless the task explicitly asks for a different treatment.

## Data And Media Rules

- Prefer local feature data shaping inside providers/controllers instead of scattering UI-specific transforms across widgets.
- Keep business logic, status mapping, and display label mapping out of widget trees when the logic is reused or non-trivial.
- When adding media selection or upload flows, use existing dependencies already present in the repo such as `image_picker` or `file_picker`.
- If a feature already distinguishes image/video/document states, preserve that distinction through the UI and comments/detail sheets.
- When a detail sheet opens from a tapped media item, keep the selected item in sync so the sheet shows the same image or video the user opened.
- Do not introduce another picker, player, or caching package if the repo already has a suitable dependency.

## Commands

Run the minimum relevant checks for the touched area.

- Install dependencies:
  `flutter pub get`
- Format touched files:
  `dart format <files>`
- Analyze relevant files:
  `flutter analyze <paths>`
- Run full analyzer when changes are broad:
  `flutter analyze`
- Run tests when logic changes or tests are touched:
  `flutter test`

## Constraints And Do-Not Rules

- Do not edit `third_party/` packages unless explicitly requested.
- Do not manually edit generated folders or build artifacts.
- Do not add new dependencies, state-management approaches, or major architectural patterns without approval.
- Do not rename or move large parts of the repo unless the task specifically asks for that.
- Do not silently change status semantics, route behavior, or upload behavior across features unless the task requires it.
- Do not do broad formatting-only churn in unrelated files.

## Done When

A change is complete only when all of the following are true:

- The requested behavior is implemented in the relevant feature.
- The touched Dart files are formatted.
- `flutter analyze` passes for the touched scope at minimum.
- Any important limitations, skipped checks, or follow-up risks are clearly reported.
- The final response names the main files changed and what was verified.

## Good Defaults For Codex

- Read the relevant feature folder before editing.
- Prefer the smallest change that satisfies the request.
- Verify UI changes with analyzer-friendly, overflow-safe widget code.
- When a bug repeats, update this file with a concrete rule rather than adding vague guidance.

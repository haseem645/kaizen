# AGENTS.md

## Purpose

This file defines repository-level rules for Codex in this Flutter project.
Favor small, targeted changes that preserve existing architecture, naming, and UI behavior.

## Repository Expectations

This is a feature-first Flutter application organized under `lib/features`.
Most features follow `data`, `domain`, and `presentation` layers, but Codex should match the local pattern of the touched feature instead of forcing a rewrite.

## Architecture Principles

- Favor feature ownership first. Keep feature-specific models, providers, widgets, and helpers inside the owning feature unless at least two features actively reuse them.
- Preserve dependency direction: `presentation -> domain -> data`. UI code must not reach directly into remote/local data sources when a provider, controller, or repository already owns that interaction.
- Treat repositories as the boundary for data access. API calls, persistence, and external SDK interactions should stay out of widgets and out of simple UI helpbber methods.
- Keep domain logic framework-light when practical. Business rules, validation, filtering, mapping, and status decisions should be easy to test without depending on widget code.
- Prefer view models or provider-owned presentation data when the UI needs formatted labels, grouped sections, or display-ready flags. Do not spread repeated mapping logic across multiple widgets.
- Add to `lib/core/` only when behavior is truly shared, stable, and generic. Do not move code into `core` just to avoid importing from a feature.
- Avoid circular feature dependencies. If two features need the same behavior, extract the smallest shared abstraction into `core` or keep one feature as the clear owner and depend on its public-facing contract only when that pattern already exists.
- Extend existing layers before creating new folders such as `services`, `helpers`, or `managers` inside a feature. New structure is justified only when the feature already has enough complexity to support it clearly.
- Prefer additive refactors and seam creation over architectural rewrites. If a feature is inconsistent, improve the touched path and leave the rest stable unless the task explicitly asks for broader cleanup.
- Keep side effects explicit. Navigation, analytics, network calls, storage writes, and uploads should flow through the owning provider/controller or repository instead of being triggered deep inside reusable widgets.
- When introducing shared abstractions, optimize for clarity over cleverness. Use simple interfaces, focused methods, and names that reflect current app behavior rather than speculative future use cases.
- Document architecture by example through file placement and naming consistency. New files should make it obvious where business logic, state, and UI behavior live without needing extra explanation.

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

## UI File Structure And Widget Organization

- **Main Screen File**: Keep the main screen widget lightweight; extract UI logic into focused private helper widgets when the build method exceeds 30-40 lines.
- **Reusable Widget Pattern**: Create private `_CustomWidgetName()` methods or separate private widget classes for UI components that are used more than once in the same feature or across the app.
- **Widget Granularity**: Break down complex layouts into smaller widgets with clear responsibilities (e.g., `_HeaderSection()`, `_ContentCard()`, `_ActionButtons()`, `_EmptyStateView()`).
- **Widget Naming**: Use descriptive names that reflect the widget's purpose. Prefix private widgets with underscore (e.g., `_UserProfileCard`, `_FilterChip`).
- **Immutability**: Ensure private widget methods accept all necessary data as parameters and remain pure functions. Avoid capturing mutable state directly.
- **Documentation**: For complex private widgets, add brief inline comments explaining the widget's purpose and expected parameters.

## String And Localization Rules

- **String Declaration**: All user-facing strings must be declared in `lib/core/constants/app_strings.dart` or the feature-specific strings file (e.g., `lib/features/<feature>/presentation/strings.dart`).
- **No Hardcoded Strings**: Do not hardcode strings directly in widget files or UI builders. Always reference strings from the AppStrings file.
- **String Organization**: Group related strings logically with clear naming conventions (e.g., `buttonSubmit`, `labelEmail`, `errorInvalidInput`, `messageWelcome`).
- **Reuse Pattern**: Import strings at the top of the UI file and reference them as `AppStrings.stringName`.
- **Pluralization and Parameters**: For strings with dynamic content, use `String.format()` or string interpolation patterns defined in AppStrings.

## State And Variable Declaration Rules

- **Controller/Provider Declaration**: All mutable state, input values, and business logic variables must be declared in the feature's controller or provider (e.g., `UserProfileController`, `SettingsNotifier`).
- **Variable Exposure**: Use getter methods or exposed stream properties to make variables available to the UI widget.
- **Local-Only State**: Only use `ValueNotifier` or `State` local variables for strictly UI-local state (e.g., collapsed/expanded sections, tab indices) when the feature controller does not already manage it.
- **Avoid Direct Mutation**: UI widgets should never directly mutate controller state. All state changes must go through controller methods.
- **Type Safety**: Always use typed providers and controllers; avoid raw `dynamic` types when accessing state from the UI.
- **Cleanup**: Ensure all streams, listeners, and notifiers subscribed to in the UI are properly unsubscribed or disposed when the widget is disposed.

## Feature-Specific Best Practices

- **Separation of Concerns**: Keep UI presentation logic in the screen file, business logic in the controller, and data access in the repository.
- **Error Handling**: Display error messages from AppStrings and always show user-friendly error states using controllers' error properties.
- **Loading States**: Implement loading indicators and disable user interactions during async operations by tracking a loading state in the controller.
- **Naming Convention for Screens**: Name screen files as `<feature>_screen.dart` and controller files as `<feature>_controller.dart`.
- **File Organization**: For complex features, organize presentation layer as: `screens/`, `widgets/`, `controllers/`.

## Data And Media Rules

- Prefer local feature data shaping inside providers/controllers instead of scattering UI-specific transforms across widgets.
- Keep business logic, status mapping, and display label mapping out of widget trees when the logic is reused or non-trivial.
- For Kaizengram Learning tab posts, `description` will not be present. UI, models, and mappers must not expect description content, must not reserve empty layout space for it, and must keep those posts visually correct without a description field.
- For Kaizengram Groups home feed, do not show a suggested groups section below the main joined-groups list.
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
- Prefer the canonical `.codex` routing skill at `.codex/skills/repo-navigation/SKILL.md`, then open only the relevant feature reference under `.codex/skills/repo-navigation/references/features/`.
- If a workflow or older instruction points to `lib/features/SKILLS.md` or `lib/features/<feature>/SKILL.md`, treat those files as compatibility shims that redirect to the canonical `.codex` references.
- Prefer the smallest change that satisfies the request.
- Verify UI changes with analyzer-friendly, overflow-safe widget code.
- When a bug repeats, update this file with a concrete rule rather than adding vague guidance.

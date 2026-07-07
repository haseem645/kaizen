# compliance_skills.md

This file is a lightweight routing index for `lib/features/compliance`.

Path style in this file:

- Use shortened repo-root paths starting with `.../`
- Treat `.../` as "this repository root"

## Compliance Shell And Tab Entry

Use for overall compliance navigation, shell UI, tab switching, and main entry behavior.

- First file: `.../lib/features/compliance/presentation/pages/compliance_screen.dart`
- Next if top-level state changes: `.../lib/features/compliance/presentation/providers/compliance_controller.dart`
- Next for shared tab widgets: `.../lib/features/compliance/presentation/widgets/compliance_tab_switcher.dart`

## Learning Track And Training Flow

Use for learning-track lists, compliance tracks, training pages, quizzes, video flow, and certificates.

- First file: `.../lib/features/compliance/presentation/pages/compliance_learning_track_tab_screen.dart`
- Next for track lists: `.../lib/features/compliance/presentation/pages/compliance_tracks_screen.dart`
- Next for training details: `.../lib/features/compliance/presentation/pages/training/compliance_training_screen.dart`
- Next if controller/state changes: `.../lib/features/compliance/presentation/providers/compliance_learning_track_controller.dart`

## Compliance Documents And Uploads

Use for document-tab behavior, full-screen document/image pages, document upload sheets, and compliance document states.

- First file: `.../lib/features/compliance/presentation/pages/compliance_document_tab_screen.dart`
- Next for document upload behavior: `.../lib/features/compliance/presentation/pages/document/compliance_document_upload_sheet.dart`
- Next for document controller/state: `.../lib/features/compliance/presentation/providers/compliance_document_controller.dart`
- Next if remote fetch/upload behavior changes: `.../lib/features/compliance/data/datasources/compliance_remote_data_source.dart`

## Compliance Data Mapping And Repositories

Use for compliance overview/documents mapping, repository behavior, remote API changes, and entity/model adjustments.

- First file: `.../lib/features/compliance/data/datasources/compliance_remote_data_source.dart`
- Next for repository behavior: `.../lib/features/compliance/data/repositories/compliance_repository_impl.dart`
- Next if presentation output changes: `.../lib/features/compliance/presentation/providers/compliance_controller.dart`

## Default Compliance Rule

If the task is ambiguous, start with `.../lib/features/compliance/presentation/pages/compliance_screen.dart`, then move into learning or document paths only after confirming which tab owns the behavior.

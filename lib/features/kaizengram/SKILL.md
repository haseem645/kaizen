# Kaizengram Skill

This file is a lightweight routing index for `lib/features/kaizengram`.

Path style in this file:

- Use shortened repo-root paths starting with `.../`
- Treat `.../` as "this repository root"

Use it to keep context small:

- Read only the one section that matches the task.
- Open the first linked file in that section first.
- Open the next linked file only if the touched path clearly crosses UI, state, data, or routing boundaries.
- Do not scan the whole Kaizengram module by default.

## Kaizengram Feed Shell

Use for tab layout, feed ordering, compose UI, weekly check-in social posts, inline comments, comment sheets, media preview, and most visual Kaizengram changes.

- First file: `.../lib/features/kaizengram/presentation/pages/kaizengram_screen.dart`
- Next if state/data is involved: `.../lib/features/kaizengram/presentation/providers/kaizengram_controller.dart`
- Next if fetched compliance/document data is involved: `.../lib/features/kaizengram/data/datasources/kaizengram_remote_data_source.dart`

## Kaizengram Feed State And Models

Use for feed item shaping, dummy feed items, social post creation, comment threading, notification data, model updates, and status decisions.

- First file: `.../lib/features/kaizengram/presentation/providers/kaizengram_controller.dart`
- Next if UI rendering is involved: `.../lib/features/kaizengram/presentation/pages/kaizengram_screen.dart`
- Next if upstream compliance/document mapping is involved: `.../lib/features/kaizengram/data/datasources/kaizengram_remote_data_source.dart`

## Kaizengram Remote Data Mapping

Use for compliance learning/document feed population, media URL normalization, title/description shaping, and remote-source behavior.

- First file: `.../lib/features/kaizengram/data/datasources/kaizengram_remote_data_source.dart`
- Next if mapped output behavior is visible in the feed: `.../lib/features/kaizengram/presentation/providers/kaizengram_controller.dart`
- Next if final rendering must change: `.../lib/features/kaizengram/presentation/pages/kaizengram_screen.dart`

## Kaizengram Notifications

Use for notification list UI, section grouping, notification taps, unread presentation, and post-preview behavior inside notifications.

- First file: `.../lib/features/kaizengram/presentation/pages/notifications/kaizengram_notifications_screen.dart`
- Next if notification buckets, seeds, or target IDs change: `.../lib/features/kaizengram/presentation/providers/kaizengram_controller.dart`
- Next if notification navigation entry changes: `.../lib/features/kaizengram/presentation/pages/kaizengram_screen.dart`

## Kaizengram Chat Shell

Use for main chat screen layout, app bar actions, message list behavior, channel switching entry points, and sheet/dialog launch behavior.

- First file: `.../lib/features/kaizengram/presentation/chat/pages/kaizengram_chat_screen.dart`
- Next if message/channel state changes: `.../lib/features/kaizengram/presentation/chat/providers/kaizengram_chat_controller.dart`
- Next if composing messages changes: `.../lib/features/kaizengram/presentation/chat/widgets/chat_message_composer.dart`

## Kaizengram Chat Channels And Membership

Use for channel list UI, create/delete channel flows, add/remove people flows, and users-sheet behavior.

- First file: `.../lib/features/kaizengram/presentation/chat/pages/kaizengram_channels_screen.dart`
- Next for state changes: `.../lib/features/kaizengram/presentation/chat/providers/kaizengram_chat_controller.dart`
- Supporting sheets/dialogs:
- `.../lib/features/kaizengram/presentation/chat/widgets/create_channel_bottom_sheet.dart`
- `.../lib/features/kaizengram/presentation/chat/widgets/chat_users_bottom_sheet.dart`
- `.../lib/features/kaizengram/presentation/chat/widgets/add_people_dialog.dart`
- `.../lib/features/kaizengram/presentation/chat/widgets/remove_user_confirmation_dialog.dart`
- `.../lib/features/kaizengram/presentation/chat/widgets/delete_channel_confirmation_dialog.dart`

## Kaizengram Chat Mentions And Message Text

Use for mention parsing, mention highlighting, text-editing behavior, and chat text presentation details.

- First file: `.../lib/features/kaizengram/presentation/chat/widgets/chat_mention_text_editing_controller.dart`
- Next for rendered mention text: `.../lib/features/kaizengram/presentation/chat/widgets/chat_mention_text.dart`
- Next if the composer is involved: `.../lib/features/kaizengram/presentation/chat/widgets/chat_message_composer.dart`
- Next if avatar/initial display changes: `.../lib/features/kaizengram/presentation/chat/widgets/chat_user_initial_avatar.dart`

## Kaizengram Strings And Shared Touchpoints

Open these only when the task changes labels, route entry, or current-user resolution behavior.

- Shared Kaizengram labels: `.../lib/core/constants/app_strings.dart`
- Chat-only labels: `.../lib/features/kaizengram/presentation/chat/chat_strings.dart`
- Kaizengram route entry: `.../lib/routes/app_router.dart`
- Current user lookup used by compose/feed entry: `.../lib/core/managers/app_manager.dart`

## Default Kaizengram Rule

If the task is ambiguous, start with `.../lib/features/kaizengram/presentation/pages/kaizengram_screen.dart` only. Expand to the controller or chat files only after confirming the touched path requires it.

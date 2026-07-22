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

## Kaizengram Feed Shell And Screen Orchestration

Use for tab layout, feed ordering, app-bar actions, compose entry, notifications launch, groups entry, chat entry, and top-level feed wiring.

- First file: `.../lib/features/kaizengram/presentation/pages/kaizengram_screen.dart`
- Next if screen-owned async actions or navigation behavior change: `.../lib/features/kaizengram/presentation/widgets/kaizengram_screen_actions.dart`
- Next if fetched state/data is involved: `.../lib/features/kaizengram/presentation/providers/kaizengram_controller.dart`
- Next if upstream compliance/document mapping is involved: `.../lib/features/kaizengram/data/datasources/kaizengram_remote_data_source.dart`

## Kaizengram Feed Sections And Entry Widgets

Use for stories, power-list cards, feed tabs, social preview cards, compose header, and top-of-feed Kaizengram UI sections.

- First file: `.../lib/features/kaizengram/presentation/widgets/kaizengram_feed_widgets.dart`
- Next if the shell screen changes too: `.../lib/features/kaizengram/presentation/pages/kaizengram_screen.dart`
- Next if current-user or feed state changes: `.../lib/features/kaizengram/presentation/providers/kaizengram_controller.dart`

## Kaizengram Feed Posts, Media, And Post Detail UI

Use for feed post cards, description expansion, media pagers, audit media page rendering, and main Kaizengram feed post visuals.

- First file: `.../lib/features/kaizengram/presentation/widgets/kaizengram_post_widgets.dart`
- Next for audit/status/meta support widgets: `.../lib/features/kaizengram/presentation/widgets/kaizengram_audit_widgets.dart`
- Next if feed state or models change: `.../lib/features/kaizengram/presentation/providers/kaizengram_controller.dart`

## Kaizengram Comments, Compose Sheets, And Attachment UI

Use for create-post bottom sheets, comment sheets, inline comment flows, paged audit comment threads, composers, and attachment preview widgets.

- First file: `.../lib/features/kaizengram/presentation/widgets/kaizengram_comment_widgets.dart`
- Next for shared compose action buttons: `.../lib/features/kaizengram/presentation/widgets/kaizengram_screen_common_widgets.dart`
- Next for attachment picking behavior: `.../lib/features/kaizengram/presentation/kaizengram_message_attachment.dart`
- Next if comment/thread state changes: `.../lib/features/kaizengram/presentation/providers/kaizengram_controller.dart`

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

Open these only when the task changes labels, route entry, current-user resolution behavior, or shared text across feed/chat/groups.

- Shared Kaizengram, chat, and groups labels: `.../lib/core/constants/app_strings.dart`
- Kaizengram route entry: `.../lib/routes/app_router.dart`
- Current user lookup used by compose/feed entry: `.../lib/core/managers/app_manager.dart`

## Default Kaizengram Rule

If the task is ambiguous, start with `.../lib/features/kaizengram/presentation/pages/kaizengram_screen.dart` only. Expand to the controller or the matching widget library only after confirming the touched path requires it.

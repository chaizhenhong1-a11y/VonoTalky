# VonoTalky Phase 9 — Recent Chat Quick Actions

Base commit: `c32a6b3` (`small change`, 2026-08-15)

## Added

- Long-press actions for direct conversations in Recent Chats.
- Pin / unpin conversation action.
- Mark conversation as read.
- Mark conversation as unread.
- Open-chat shortcut inside the action sheet.
- Visible pin indicator beside pinned conversation titles.
- Subtle pinned-row background treatment.
- Floating confirmation/error SnackBars for conversation actions.

## Architecture

- Reuses the existing `ContactDetailService.setPreference()` API.
- Reuses the existing `contactPreferences/{contactId}` Firestore subcollection.
- Reuses `ChatService.markRead()` and `ChatService.markUnread()`.
- No new package dependencies.
- No Firestore schema migration required.
- No Firestore rules changes required.

## Scope

This incremental patch changes only:

- `lib/features/home/presentation/widgets/unified_recent_chats.dart`
- `CHANGELOG_PHASE_9.md`

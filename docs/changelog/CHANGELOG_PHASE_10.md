# VonoTalky Phase 10 — Group Recent Chat Quick Actions

This patch continues directly from the Phase 9 Recent Chats patch.

## Added

- Long-press quick actions for group conversations.
- Pin / unpin group conversations.
- Mark groups as read.
- Mark groups as unread.
- Open-group shortcut from the action sheet.
- Pinned group indicator and pinned-row background.
- Group pin state participates in the same Recent Chats ordering as direct chats.

## Data design

- Group pin preferences are stored in the current user's existing
  `contactPreferences` subcollection with `group_<groupId>` document IDs.
- Group unread reminders reuse `groups/{groupId}.unreadCounts.<uid>`.

## Compatibility

- No package dependency changes.
- No Firestore schema migration.
- No Firestore Rules changes required.
- Reuses the existing `GroupService.markRead()` implementation.

## Patch contents

- `lib/features/home/presentation/widgets/unified_recent_chats.dart`
- `lib/features/groups/data/services/group_recent_chat_service.dart`
- `CHANGELOG_PHASE_10.md`

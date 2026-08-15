# VonoTalky Phase 15 — Group Drafts

## Added

- Group chat composer drafts are saved automatically.
- Existing group drafts are restored when reopening a group.
- Recent Chats shows group drafts with the same purple `Draft:` treatment as direct chats.
- Group draft timestamps participate in Recent Chats ordering.
- Successfully sending the text clears the saved draft.
- Draft saving is debounced to reduce unnecessary Firestore writes.

## Storage

- Group drafts reuse the existing user-owned `contactPreferences` collection.
- Group preference document id: `group_<groupId>`.
- Stored fields: `draft`, `draftUpdatedAt`, `type`.

## Compatibility

- Continues directly from Phase 14.
- No new Flutter packages.
- No Firestore Rules changes.
- No schema migration.

## Changed files

- `lib/features/groups/presentation/pages/group_chat_room_page.dart`
- `lib/features/groups/data/services/group_recent_chat_service.dart`
- `lib/features/home/presentation/widgets/unified_recent_chats.dart`
- `CHANGELOG_PHASE_15.md`

# VonoTalky Phase 11 — Archive Recent Chats

## Added
- Archive action for direct chats.
- Archive action for group chats.
- Archived conversations are hidden from Recent Chats immediately.
- Direct-chat archive state reuses `contactPreferences/{contactId}.archived`.
- Group archive state uses `contactPreferences/group_<groupId>.archived`.

## Compatibility
- Continues directly from Phase 10.
- No new package dependencies.
- No Firestore Rules changes.
- No schema migration.

## Changed files
- `lib/features/home/presentation/widgets/unified_recent_chats.dart`
- `lib/features/groups/data/services/group_recent_chat_service.dart`
- `CHANGELOG_PHASE_11.md`

# VonoTalky Phase 14 — Draft Preview

## Added

- Recent Chats now shows unsent direct-message drafts.
- Draft rows use a purple `Draft:` prefix so they are visually distinct from sent messages.
- Line breaks inside drafts are flattened for a clean one-line preview.
- A newer draft can move its conversation upward based on `draftUpdatedAt`.
- Pinned conversations still stay above normal conversations.
- Existing draft persistence and restoration are reused; no duplicate storage layer is introduced.

## Existing architecture reused

- `RealChatRoomPage` already saves drafts with `ContactDetailService.setDraft()`.
- `RealChatRoomPage` already restores a saved draft when reopening a conversation.
- `ContactDetailService` already stores `draft` and `draftUpdatedAt` in the user's contact preferences.

## Compatibility

- Continues directly from Phase 13.
- No new Flutter packages.
- No Firestore Rules changes.
- No schema migration.

## Changed files

- `lib/features/home/presentation/widgets/unified_recent_chats.dart`
- `CHANGELOG_PHASE_14.md`

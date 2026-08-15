# VonoTalky Phase 12 — Archived Chats Manager (Rebased)

## Added
- Dedicated Archived Chats page.
- Archived direct chats and groups shown together.
- One-tap Unarchive restores conversations to Recent Chats.
- Archived Chats entry is placed directly above the Recent Chats list.

## Why this patch is rebased
- It does not modify `chat_home_page.dart`.
- It applies directly on top of the Phase 11.1 `unified_recent_chats.dart` baseline.

## Changed / added files
- `lib/features/home/presentation/widgets/unified_recent_chats.dart`
- `lib/features/home/presentation/pages/archived_chats_page.dart`
- `CHANGELOG_PHASE_12_REBASED.md`

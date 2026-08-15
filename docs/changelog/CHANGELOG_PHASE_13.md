# VonoTalky Phase 13 — Swipe Actions

## Added

- Swipe right on a direct chat to toggle read / unread.
- Swipe left on a direct chat to archive it.
- Swipe right on a group chat to toggle read / unread.
- Swipe left on a group chat to archive it.
- Purple action backgrounds with clear icons and labels.
- Firestore remains the source of truth; swipe gestures do not remove rows locally before data updates.

## Compatibility

- Continues directly from Phase 12 rebased patch.
- No new Flutter packages.
- No Firestore Rules changes.
- No schema migration.
- Reuses existing archive and unread services.

## Changed files

- `lib/features/home/presentation/widgets/unified_recent_chats.dart`
- `CHANGELOG_PHASE_13.md`

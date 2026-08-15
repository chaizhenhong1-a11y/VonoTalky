# VonoTalky Phase 17.2 — Pinned Messages Manager Read Fix

## Fixed

- Pinned Messages management page no longer depends on a Stream object passed
  from the chat room.
- The page now receives the exact Firestore contact-preference document id and
  creates its own snapshot stream.
- Direct chats read:
  `users/<currentUid>/contactPreferences/<otherUserId>`
- Group chats read:
  `users/<currentUid>/contactPreferences/group_<groupId>`
- The top pinned banner keeps its live stream behavior.
- Management page now surfaces Firestore stream errors instead of silently
  falling back to an empty state.
- Message ids, previews, senders and types are normalized with `toString()`.

## Why

Firestore Console confirmed that `pinnedMessages` is stored correctly, including
multiple entries. The remaining failure was therefore isolated to the manager
page's read path.

## Compatibility

- Continues directly from Phase 17.1.
- Existing pinned data is preserved.
- No package changes.
- No Firestore Rules changes.
- No migration required.

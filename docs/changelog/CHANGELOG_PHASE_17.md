# VonoTalky Phase 17 — Multiple Pinned Messages

## Added

- Up to 20 pinned messages per direct chat or group.
- Existing Phase 16 single pinned messages remain readable and migrate automatically when another message is pinned.
- Pinned banner displays `current / total`.
- Previous / next controls cycle through pinned messages.
- New Pinned Messages management page.
- Tap a pinned item to return to the original message.
- Remove one pinned message without clearing the others.

## Storage

Pinned messages remain in the authenticated user's existing
`contactPreferences` document.

New field:
- `pinnedMessages`: list of pinned-message summaries.

## Compatibility

- Continues directly from Phase 16 fixed v2.
- No new Flutter packages.
- No Firestore Rules changes.
- No schema migration required.

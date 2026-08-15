# VonoTalky Phase 22 — Group Message Info

## Added
- Long-press your own group message and choose `Message info`.
- Message preview for text, image, voice and file messages.
- Sent date/time.
- Seen-by member count.
- List of members who have read the message.
- Member avatar, display name and email when available.

## Data
- Reuses the existing group message `readBy` field.
- Reads existing user profiles for names and avatars.
- No new collections or fields.

## Compatibility
- Continues directly from Phase 21 fixed.
- No new Flutter packages.
- No Firestore Rules changes.
- No schema migration.

# VonoTalky - Phase 5

## Message and presence states

- Added unread conversation counters.
- Added delivered/read indicators and message timestamps.
- Added automatic read marking when a room is opened.
- Added online and last-seen presence updates.
- Added real-time typing indicators.
- Added sender-only message recall.
- Hardened Firestore rules for state-specific message updates.

Deploy the updated rules:

```powershell
firebase deploy --only firestore:rules
```

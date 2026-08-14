# VonoTalky - Phase 4

## Real-time private chat

- Replaced demo chats with Firestore conversations.
- Added registered-user search and new-chat flow.
- Added deterministic private room IDs.
- Added real-time text messages and conversation previews.
- Added participant-only Firestore security rules.

After applying the increment, deploy the updated rules:

```powershell
firebase deploy --only firestore:rules
```

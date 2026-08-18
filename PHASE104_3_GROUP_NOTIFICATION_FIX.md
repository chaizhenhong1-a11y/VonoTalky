# Phase 104.3 — Group Notification Fix

## Root cause

The backend had an `onDirectMessageCreated` trigger for direct messages, but no
Cloud Function listening to `groups/{groupId}/messages/{messageId}`. Group
messages were therefore written correctly to Firestore but no server-side FCM
send was started.

## Fixed

- Adds `onGroupMessageCreated`.
- Sends to all group members except the sender.
- Supports text, photo, file and voice previews.
- Uses the group name as the notification title and `sender: preview` as body.
- Skips a device currently inside that same group conversation.
- Adds server logs for diagnosis.

## Apply

Extract the outer `vonotalky` folder over:

`C:\flutter project\vonotalky`

Then run:

```powershell
cd "C:\flutter project\vonotalky"
powershell -ExecutionPolicy Bypass -File .\scripts\apply_phase104_3_group_notifications.ps1

dart format lib/features/groups/presentation/pages/group_chat_room_page.dart
flutter analyze
```

## REQUIRED deployment

This fix changes Cloud Functions. Merely hot-reloading/rebuilding Flutter is not
enough. Deploy the new trigger:

```powershell
firebase deploy --only functions:onGroupMessageCreated
```

If Firebase CLI says the function filter is unsupported in your setup, deploy
all project functions instead:

```powershell
firebase deploy --only functions
```

After deployment, test with two different accounts/devices: keep the receiver
outside the target group chat, send a group message from the other account, and
check the system notification.

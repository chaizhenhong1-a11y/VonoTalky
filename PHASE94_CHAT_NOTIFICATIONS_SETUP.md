# Phase 94 — Global FCM + Chat Message Notifications v1

## Global FCM initialization

Phase 92 initialized FCM only when a shared-pet detail page opened.

Phase 94 moves initialization to:

`MainShellPage`

That means once a signed-in user reaches the main app shell, the phone immediately:

- requests notification permission;
- retrieves its FCM token;
- stores/refreshes it in Firestore;
- starts listening for foreground/tapped notifications.

The pet detail page no longer owns FCM initialization.

## Direct-message push trigger

New Cloud Function:

`onDirectMessageCreated`

Trigger:

`conversations/{conversationId}/messages/{messageId}`

The function:
1. reads the new message;
2. reads the parent conversation;
3. validates that `senderId` belongs to the two-person conversation;
4. finds the other member as the receiver;
5. reads the sender profile for notification title;
6. sends FCM to every enabled receiver device.

This intentionally does not require a message-level `receiverId`, so it works with the existing conversation `memberIds` model.

## Notification body

Text:
`Alice`
`Are you free tonight?`

Image:
`Alice`
`📷 Sent a photo`

Voice:
`Alice`
`🎤 Voice message`

File:
`Alice`
`📎 report.pdf`

## Data payload

`type=direct_message`

Also includes:
- conversationId
- messageId
- friendId

A later navigation phase can use those fields to open the exact chat after tapping the notification.

## Deploy

```powershell
.\apply_phase94.ps1
```

Or manually:

```powershell
dart format lib/features/shell/presentation/pages/main_shell_page.dart lib/features/pet/data/services/pet_notification_service.dart lib/features/pet/presentation/pages/shared_pet_detail_page.dart
flutter analyze

cd functions
npm install
cd ..

firebase deploy --only "functions:onPetInviteCreated,functions:onPetCareRequestCreated,functions:onDirectMessageCreated"
```

## Two-phone test

1. Install/run VonoTalky on Phone B.
2. Log in as B and allow notifications.
3. B only needs to reach the main shell; opening Pet Detail is no longer required.
4. Put B in the background.
5. A sends B a normal direct-chat text.
6. B should receive a system notification.
7. Repeat with image / voice / file.
8. Test pet invite and care request again to confirm Phase 93 still works.

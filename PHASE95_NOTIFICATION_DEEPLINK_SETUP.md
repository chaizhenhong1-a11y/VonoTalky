# Phase 95 — Notification Tap Routing v1

This phase wires FCM notification taps into the signed-in app shell.

## Routing

- `direct_message` → switches directly to the Chats tab.
- `pet_care_request` with `petId` → opens the matching Shared Pet detail page.
- `pet_invite` with an existing `petId` → opens the matching Shared Pet detail page.
- `pet_invite` without `petId` → switches to Pet center, where the existing invitation inbox can handle the pending invite.

## Why direct-message v1 opens Chats instead of fabricating a room

The Phase 94 push payload contains IDs but not a complete `ChatUser` model. The current `RealChatRoomPage` requires a full `ChatUser`. Phase 95 therefore routes safely to the existing Chats UI instead of constructing incomplete user data.

A later increment can add a repository lookup by `friendId` and open the exact room after the user document is resolved.

## Apply

Overwrite the included files, then run:

```powershell
dart format lib/features/pet/data/services/pet_notification_service.dart lib/features/shell/presentation/pages/main_shell_page.dart
flutter analyze
```

No Cloud Function redeploy is required for this v1 routing increment.

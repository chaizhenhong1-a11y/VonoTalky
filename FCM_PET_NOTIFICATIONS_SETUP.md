# Phase 92 — FCM Pet Notifications Setup

## 1. Add the Flutter dependency

From the VonoTalky project root:

```powershell
flutter pub add firebase_messaging
```

Or run:

```powershell
.\apply_phase92_dependencies.ps1
```

## 2. Firebase Console

In Firebase Console:

- Open Project settings.
- Confirm the Android app is registered.
- Confirm `google-services.json` is already in:
  `android/app/google-services.json`.

VonoTalky already uses Firebase, so this should normally already be configured.

## 3. Android notification permission

`firebase_messaging` requests permission at runtime on supported Android versions through:

```dart
FirebaseMessaging.instance.requestPermission(...)
```

Phase 92 calls this automatically when a shared-pet detail page initializes.

## 4. Token storage

The current device token is stored under:

```text
users/{uid}/devices/{deviceDocumentId}
```

Fields:

```text
fcmToken
platform
notificationsEnabled
updatedAt
```

Your existing Firestore rules already allow the signed-in owner to read/write:

```text
users/{userId}/devices/{deviceId}
```

So no Firestore Rules change is required for Phase 92.

## 5. Planned notification payload

Future Cloud Functions should send data payloads using keys such as:

```text
type
petId
friendId
inviteId
careRequestId
```

Planned `type` values:

```text
pet_invite
care_request
streak_risk
level_up
evolution
daily_reward
```

## 6. What Phase 92 does now

- Requests push notification permission.
- Retrieves the FCM registration token.
- Saves the token to Firestore.
- Updates Firestore when the FCM token rotates.
- Listens to foreground FCM messages.
- Listens to notifications that open the app.
- Reads the initial notification when the app was terminated.

## 7. What is intentionally deferred

Phase 92 is the client foundation only.

A later phase will add trusted Cloud Functions that actually send push notifications when:

- a pet invitation is created;
- a care request is created;
- a streak is at risk;
- a pet levels up / evolves;
- a daily reward becomes available.

That server-side work should not be emulated from the client because it would be easy to abuse.

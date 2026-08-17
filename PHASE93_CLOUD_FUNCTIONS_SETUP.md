# Phase 93 — Cloud Functions Pet Push v1

## What this phase sends

### 1. Shared-pet invitation

Trigger:

```text
petInvites/{inviteId}
```

When a new `pending` invitation is created, the receiver gets a push notification such as:

```text
Raise a pet together 🐾
Alice invited you to raise Mochi together.
```

Payload:

```text
type=pet_invite
inviteId=<invite id>
friendId=<sender uid>
petId=
```

### 2. Care request

Trigger:

```text
sharedPets/{petId}/careRequests/{requestId}
```

Examples:

```text
Mochi is hungry 🍪
Alice asked you to feed Mochi.
```

```text
Mochi wants to play 🎮
Alice asked you to play with Mochi.
```

```text
Mochi needs some love 💗
Alice asked you to pet Mochi.
```

Payload:

```text
type=care_request
petId=<shared pet id>
careRequestId=<request id>
friendId=<sender uid>
inviteId=
```

## Requirements

Phase 92 must already be installed so the phone stores its FCM token at:

```text
users/{uid}/devices/{deviceId}
```

## Cloud Functions setup

This package uses 2nd generation Firestore triggers.

The included Functions package targets Node.js 22.

From the VonoTalky project root:

```powershell
cd functions
npm install
cd ..
```

Then deploy:

```powershell
firebase deploy --only functions:onPetInviteCreated,functions:onPetCareRequestCreated
```

Or run:

```powershell
.\apply_phase93_functions.ps1
```

## If this is the project's first Functions deployment

Firebase may ask you to enable Google Cloud APIs and/or upgrade the Firebase project billing plan.

Cloud Functions deployment requirements are controlled by Firebase / Google Cloud and can change, so follow the Firebase CLI output if it requests project-level setup.

## Invalid FCM tokens

When FCM reports that a registration token is no longer valid, Phase 93 marks that device document:

```text
notificationsEnabled=false
invalidatedAt=<server timestamp>
```

This prevents future notification attempts to dead tokens.

## Security model

Push messages are sent using Firebase Admin SDK from Cloud Functions.

The Flutter app never receives permission to send arbitrary FCM messages to other users.

The functions validate relevant IDs and, for care requests, verify that both users are members of the shared pet before sending.

## Phase 94

The next phase can connect FCM notification taps to actual app navigation:

```text
pet_invite    -> friend chat / Pet Center invite
care_request  -> exact shared pet detail
```

# Firebase Shared Pets Setup

Phase 73 uses a top-level Firestore collection:

```text
sharedPets/{petId}
```

Example document:

```json
{
  "petName": "Mochi",
  "memberIds": ["uidA", "uidB"],
  "memberNames": {
    "uidA": "Alice",
    "uidB": "You"
  },
  "streakDays": 12,
  "level": 3,
  "xp": 120,
  "affection": 220,
  "energy": 80,
  "chatProgress": 0,
  "contributions": {
    "uidA": 60,
    "uidB": 40
  }
}
```

## Firestore Security Rules

Merge this match block into your existing authenticated Firestore rules.
Do not replace unrelated existing rules blindly.

```rules
match /sharedPets/{petId} {
  allow read: if request.auth != null
    && request.auth.uid in resource.data.memberIds;

  allow create: if request.auth != null
    && request.resource.data.memberIds is list
    && request.resource.data.memberIds.size() == 2
    && request.auth.uid in request.resource.data.memberIds;

  allow update: if request.auth != null
    && request.auth.uid in resource.data.memberIds
    && request.resource.data.memberIds == resource.data.memberIds;

  allow delete: if request.auth != null
    && request.auth.uid in resource.data.memberIds;
}
```

## Index

The Pet Center query only uses:

```dart
where('memberIds', arrayContains: uid)
```

This normally works with Firestore's automatic single-field indexes and does not require a custom composite index.

## Phase 74

The next phase can connect `createSharedPet()` to the real friend-chat UI so users can send/accept a co-raising invitation instead of creating documents manually.

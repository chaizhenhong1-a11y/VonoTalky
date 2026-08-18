# Phase 104.4 — Floating Pet Chat Fix

This UI/UX hotfix continues directly from Phase 104.3.

## Changed

- Removed the full-width pet card from the top of direct chats.
- The shared pet now floats above the chat content instead of taking layout space.
- Drag the pet to reposition it.
- Tap the pet to open pet details.
- Long-press the pet for quick care.
- Tap the small close control to hide it.
- When hidden, a small fire/pet button remains at the top-right so the pet can be shown again.
- Position and visibility are remembered per contact.

## Persistence

The existing owner-only contact preference document is reused:

`users/{currentUserId}/contactPreferences/{contactId}`

Fields:

- `floatingPetX`
- `floatingPetY`
- `floatingPetVisible`

No Firestore Rules change is required.
No Cloud Functions deployment is required.

## Apply

Copy the outer `vonotalky` folder over:

`C:\flutter project\vonotalky`

Then run:

```powershell
cd "C:\flutter project\vonotalky"
dart format lib/features/chat/presentation/pages/real_chat_room_page.dart
flutter analyze
```

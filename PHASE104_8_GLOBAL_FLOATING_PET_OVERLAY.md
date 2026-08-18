# Phase 104.8 — Global Floating Pet Overlay

This increment continues directly from Phase 104.7.2.

## Root cause

Mochi was still a child of the same chat `Stack` that contains the conversation
`ListView`. Even with a larger hit target, mouse/touch drag recognition could
still feel sticky because the conversation was part of the same route gesture
tree.

## Fix

Mochi now lives in a root Flutter `OverlayEntry`.

Benefits:

- visually unchanged Vector Mochi
- independent top-level gesture layer
- no chat ListView drag competition
- Edge mouse dragging behaves much more like a floating desktop control
- mobile touch drag stays independent from chat scrolling
- only the overlay rebuilds during movement
- location remains normalized and saved per contact

## Apply

Overlay the outer `vonotalky` folder, then:

```powershell
cd "C:\flutter project\vonotalky"

dart format lib/features/chat/presentation/pages/real_chat_room_page.dart lib/features/pet/animation/pet_actor.dart lib/features/pet/presentation/widgets/floating_pet_actor.dart

flutter analyze
```

No Firebase deployment is required.

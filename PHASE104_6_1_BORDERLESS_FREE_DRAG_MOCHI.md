# Phase 104.6.1 — Borderless Free-Drag Mochi

This hotfix continues directly from Phase 104.6.

## Fixed

- All 28 Mochi frames were rebuilt onto a transparent canvas.
- The visible rectangular/pastel card edge around Mochi is removed.
- Mochi can be dragged over the entire chat overlay.
- Mochi may sit partially outside any screen edge like a floating control.
- Only a 24 px reachable grip remains onscreen so it can always be dragged back.

## Apply

Overlay the `vonotalky` folder, then run:

```powershell
cd "C:\flutter project\vonotalky"

flutter pub get

dart format lib/features/pet/animation lib/features/pet/presentation/widgets/floating_pet_actor.dart lib/features/chat/presentation/pages/real_chat_room_page.dart

flutter analyze
```

No Firebase deployment is required.

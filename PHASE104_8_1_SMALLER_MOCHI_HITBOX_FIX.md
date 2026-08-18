# Phase 104.8.1 — Smaller Mochi + Smaller Hitbox

This hotfix continues directly from Phase 104.8.

## Changed

- Visual Mochi: `118px -> 92px`
- Invisible drag target: `176px -> 108px`
- Minimum reachable grip: `28px -> 20px`
- Keeps the root `OverlayEntry` drag architecture
- Clears the remaining curly-braces lint

## Apply

Overlay the outer `vonotalky` folder, then run:

```powershell
cd "C:\flutter project\vonotalky"

dart format lib/features/chat/presentation/pages/real_chat_room_page.dart lib/features/pet/animation/pet_actor.dart lib/features/pet/presentation/widgets/floating_pet_actor.dart

flutter analyze
```

No Firebase deployment is required.

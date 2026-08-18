# Phase 104.6.2 — Easy Drag + Full Tail Mochi

This hotfix continues directly from Phase 104.6.1.

## Fixed

- Rebuilt the Mochi sprite set from a cleaner source with the full tail visible.
- Visual pet remains compact, but the invisible touch/drag target is much larger.
- Dragging uses raw pointer movement, so it follows the finger immediately.
- Chat scrolling no longer wins the drag gesture as easily.
- Tap and drag are separated by a small movement threshold.
- Mochi can still be moved to screen edges or partly offscreen.

## Apply

Overlay the `vonotalky` folder, then:

```powershell
cd "C:\flutter project\vonotalky"

flutter pub get

dart format lib/features/pet/animation lib/features/pet/presentation/widgets/floating_pet_actor.dart lib/features/chat/presentation/pages/real_chat_room_page.dart

flutter analyze
```

No Firebase deployment is required.

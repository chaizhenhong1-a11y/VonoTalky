# Phase 104.7.1 — Mochi Drag Gesture Fix

This hotfix continues directly from Phase 104.7.

## Root cause

The previous implementation used `Listener` for raw pointer events. `Listener`
does not win Flutter's gesture arena, so the chat `ListView` could still scroll
while the user tried to drag Mochi.

## Fix

Mochi now uses a real `GestureDetector` pan recognizer:

- large 176 px invisible touch target
- `dragStartBehavior: DragStartBehavior.down`
- `onPanStart`
- `onPanUpdate`
- `onPanEnd`
- `onPanCancel`

This lets Mochi claim the drag gesture instead of fighting the chat list.

## Apply

Overlay the outer `vonotalky` folder, then run:

```powershell
cd "C:\flutter project\vonotalky"

dart format lib/features/pet/animation/pet_actor.dart

flutter analyze
```

No Firebase deployment is required.

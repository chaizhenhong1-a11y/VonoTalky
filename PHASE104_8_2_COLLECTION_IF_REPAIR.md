# Phase 104.8.2 — Collection-if Repair

Phase 104.8.1 accidentally converted a Dart collection-if inside the AppBar
avatar Stack into a statement-style braced if.

Broken:

```dart
if (widget.user.isOnline) {
  Positioned(
}
```

Restored:

```dart
if (widget.user.isOnline)
  Positioned(
    ...
  ),
```

This one syntax corruption caused the large cascade of red lines.

## Apply

Overlay the outer `vonotalky` folder, then run:

```powershell
cd "C:\flutter project\vonotalky"

dart format lib/features/chat/presentation/pages/real_chat_room_page.dart

flutter analyze
```

No Firebase deployment is required.

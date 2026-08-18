# Phase 104.8.4 — Collection-if Final Repair

This hotfix is generated directly from the user's current
`real_chat_room_page.dart` content.

Only the malformed AppBar collection-if is repaired.

Correct Dart collection-if:

```dart
if (widget.user.isOnline)
  Positioned(
    ...
  ),
```

Do not convert this collection-if to a braced statement-style if.

After overlaying:

```powershell
cd "C:\flutter project\vonotalky"

dart format lib/features/chat/presentation/pages/real_chat_room_page.dart

flutter analyze
```

No Firebase deployment is required.

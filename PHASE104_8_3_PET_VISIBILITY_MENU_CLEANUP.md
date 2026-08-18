# Phase 104.8.3 — Pet Visibility Menu Cleanup

The floating paw button is removed.

Use the chat `⋮` menu:

- `Hide pet` when Mochi is visible
- `Show pet` when Mochi is hidden

When hidden, Mochi's Overlay does not place any visible button over the AppBar.

## Apply

```powershell
cd "C:\flutter project\vonotalky"

dart format lib/features/chat/presentation/pages/real_chat_room_page.dart

flutter analyze
```

No Firebase deployment is required.

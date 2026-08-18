# Phase 104.4.1 — Real Chat Tail Restore Hotfix

Phase 104.4 accidentally truncated helper widgets located after the old pet card widget.

Restored:

- `_PetInviteBanner`
- `_MessageDetailRow`
- `_SelectionToolbar`

The floating pet implementation is not changed.

After overlaying this ZIP, run:

```powershell
cd "C:\flutter project\vonotalky"
dart format lib/features/chat/presentation/pages/real_chat_room_page.dart
flutter analyze
```

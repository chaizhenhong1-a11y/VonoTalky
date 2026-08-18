# Phase 104.1 — Composer Alignment Hotfix

This hotfix continues directly from Phase 104.

## Fixed

- Direct chat composer now uses vertical center alignment instead of bottom alignment.
- Group chat composer explicitly uses the same vertical center alignment.
- Microphone/keyboard, emoji, plus and send controls now stay on the same visual row as the text field in the normal one-line state.
- Multiline input can still grow without dragging the controls downward.

## Apply

Copy the outer `vonotalky` folder over:

`C:\flutter project\vonotalky`

Then run:

```powershell
cd "C:\flutter project\vonotalky"
dart format lib/features/chat/presentation/pages/real_chat_room_page.dart lib/features/groups/presentation/pages/group_chat_room_page.dart
flutter analyze
```

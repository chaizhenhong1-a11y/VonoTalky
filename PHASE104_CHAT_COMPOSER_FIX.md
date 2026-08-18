# Phase 104 — Chat Composer UX Fix

This is a bug-fix increment continuing from Phase 103.

## Fixed

- Direct chat and group chat now share the same WeChat-style composer logic.
- Left-most toggle switches between keyboard/text and voice input.
- Voice mode shows a Hold to talk surface.
- Hold to talk: release sends; slide upward before release cancels.
- Sending text keeps the keyboard open and focus in the composer.
- Send and voice controls use stronger active purple contrast.
- Existing emoji, attachment, reply, image, file and voice-message services are retained.

## Apply

Copy the outer `vonotalky` folder over:

`C:\flutter project\vonotalky`

Then run:

```powershell
cd "C:\flutter project\vonotalky"
dart format lib/features/chat/presentation/pages/real_chat_room_page.dart lib/features/groups/presentation/pages/group_chat_room_page.dart
flutter analyze
```

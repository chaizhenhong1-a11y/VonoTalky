# VonoTalky - Phase 7A

## Voice messages

- Added microphone permission handling and WAV recording.
- Added Android and web-compatible voice uploads.
- Added recording duration and upload state.
- Added voice message playback, pause and progress.
- Added participant-only audio Storage rules with a 25 MB limit.

Install the new plugins and deploy Storage rules:

```powershell
flutter pub add record just_audio path_provider
flutterfire configure
firebase deploy --only storage
flutter run
```

On Edge, allow microphone access when the browser asks.

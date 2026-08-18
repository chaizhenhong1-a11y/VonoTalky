# Phase 104.5 — Mochi Floating Sprite

This increment continues Phase 104.4.1.

## Important
Run the included asset registration script once after overlaying the ZIP:

```powershell
cd "C:\flutter project\vonotalky"
powershell -ExecutionPolicy Bypass -File .\scripts\apply_phase104_5_mochi_asset.ps1
flutter pub get
dart format lib/features/chat/presentation/pages/real_chat_room_page.dart
flutter analyze
```

No Firebase Functions deployment is required.

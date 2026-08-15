# VonoTalky - Phase 6

## Image messages

- Added gallery and camera image selection.
- Added cross-platform byte uploads to Firebase Storage.
- Added authenticated chat image messages and upload state.
- Added full-screen zoomable image previews.
- Added participant-only Storage rules with image and 10 MB limits.

Install and configure the new plugins:

```powershell
flutter pub add firebase_storage image_picker
flutterfire configure
firebase deploy --only storage
flutter run
```

Enable Firebase Storage in Firebase Console before testing.

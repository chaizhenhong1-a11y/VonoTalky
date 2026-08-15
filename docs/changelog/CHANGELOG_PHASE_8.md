# VonoTalky - Phase 8

## Professional profile

- Added the purple curved profile header and live online badge.
- Added real Firestore profile information and activity count.
- Added editable name, bio, phone and date of birth.
- Added profile photo selection and Firebase Storage upload.
- Added quick-action cards and authenticated sign-out.
- Added a personal VonoTalky contact QR code.
- Connected the home navigation Profile destination.

Install QR rendering and deploy updated Storage rules:

```powershell
flutter pub add qr_flutter
firebase deploy --only storage
flutter clean
flutter pub get
flutter run -d edge
```

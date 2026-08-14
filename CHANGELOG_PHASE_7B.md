# VonoTalky - Phase 7B

## File attachments

- Added PDF, Office, text and ZIP file selection.
- Added cross-platform Firebase Storage uploads.
- Added file name, type and size metadata.
- Added file message cards and external open/download actions.
- Added a 25 MB client and Storage Rules limit.

Install plugins and deploy the updated Storage rules:

```powershell
flutter pub add file_picker url_launcher
flutterfire configure
firebase deploy --only storage
flutter clean
flutter pub get
flutter run -d edge
```

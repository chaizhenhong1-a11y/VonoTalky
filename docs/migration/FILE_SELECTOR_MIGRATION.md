# Replace file_picker with file_selector

Run from the Flutter project root:

```powershell
flutter pub remove file_picker
flutter pub add file_selector
flutter clean
Remove-Item -Recurse -Force .dart_tool, build -ErrorAction SilentlyContinue
flutter pub get
flutter run
```

Do not edit `GeneratedPluginRegistrant.java`; Flutter regenerates it automatically.

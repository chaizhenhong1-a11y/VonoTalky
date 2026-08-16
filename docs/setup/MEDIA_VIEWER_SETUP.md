# Media viewer setup

Run these commands from the `vonotalky` project root after applying this increment:

```powershell
flutter pub add dio
flutter pub add open_filex
flutter pub add share_plus
flutter clean
flutter pub get
flutter run
```

Android downloads are stored persistently inside the app's `VonoTalky` documents directory and opened with an installed system app. Web downloads open in a new browser tab.

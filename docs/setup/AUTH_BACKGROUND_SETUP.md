# Auth background setup

Add the image directory under the existing `flutter:` section of `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

Keep only one `flutter:` section. Then run:

```powershell
flutter clean
flutter pub get
flutter run
```

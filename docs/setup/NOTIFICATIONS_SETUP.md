# VonoTalky notifications setup

## Flutter dependency

Run from the Flutter project root:

```powershell
flutter pub add firebase_messaging
```

## Firebase Functions

If `firebase.json` does not already contain a Functions target, add this property:

```json
{
  "functions": {
    "source": "functions"
  }
}
```

Then install and deploy:

```powershell
cd functions
npm install
cd ..
firebase deploy --only "functions,firestore:rules"
```

For Android 13+, ensure the app targets API 33 or newer. For iOS, enable Push Notifications and Background Modes > Remote notifications in Xcode, then upload an APNs key in Firebase Console.

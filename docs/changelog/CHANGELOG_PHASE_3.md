# VonoTalky - Phase 3

## Real Firebase authentication

- Initialized Firebase with generated multi-platform options.
- Added email/password sign-in and account registration.
- Added password reset email support.
- Added persistent authentication state routing.
- Added Cloud Firestore user profile creation.
- Added friendly Firebase error handling and loading states.
- Added sign-out from the home-page account menu.
- Added initial Firestore security rules for user profiles.

## Required setup

Run these commands inside the `vonotalky` project before launching:

```powershell
flutter pub add firebase_core firebase_auth cloud_firestore
dart pub global activate flutterfire_cli
flutterfire configure
firebase deploy --only firestore:rules
flutter run
```

In Firebase Console, enable **Authentication > Sign-in method > Email/Password**
and create a Cloud Firestore database.

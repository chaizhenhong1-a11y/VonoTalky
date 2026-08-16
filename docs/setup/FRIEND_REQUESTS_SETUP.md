# Friend requests setup

After applying this increment, deploy the included Firestore rules:

```powershell
firebase deploy --only "firestore:rules"
flutter clean
flutter pub get
flutter run
```

No new Flutter dependency is required.

New accounts automatically receive `displayNameLower` for username-prefix search. Existing accounts remain searchable by their full email immediately; saving the profile once adds username-prefix search support.

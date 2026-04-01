# SheCares MVP

SheCares is a Flutter Phase 1 MVP for discreet delivery of sanitary pads, baby diapers, and adult diapers in Ahmedabad.

## What is implemented

- Customer app routes for splash, login, profile setup, home, product listing, product detail, cart, order success, orders, tracking, profile, and wellness stub
- Firebase-aware auth and Firestore service layers with local demo fallback when Firebase is not configured
- 21-product Phase 1 seed catalog and demo delivery agents
- Admin panel for dashboard, products, orders, agents, and NGO partner stub
- Separate Flutter web admin entrypoint in `lib/main_admin.dart`
- Firestore security rules in `firestore.rules`

## Demo mode

If `lib/firebase_options.dart` still contains placeholder values, the app runs in demo mode.

- Demo OTP: `123456`
- Demo admin phone number: `9999999999`
- Web admin PIN: `123456`

## Firebase setup

1. Create the Firebase project and enable Phone Authentication, Firestore, and Cloud Messaging.
2. Replace the placeholder values in `lib/firebase_options.dart` with real project values from `flutterfire configure`.
3. Add `android/app/google-services.json` for Android.
4. Deploy `firestore.rules` after validating them in the emulator.

## Run the app

```bash
flutter pub get
flutter run
```

## Run the admin web panel

```bash
flutter run -d chrome --target lib/main_admin.dart
```

## Suggested checks

```bash
flutter analyze
flutter test
```

## Notes

- Phase 1 is English-first. Language preference is collected now but Gujarati and Hindi copy are intentionally deferred.
- The customer app supports demo/local fallback so the UI can still be exercised before Firebase credentials are available.
- The admin web PIN gate is a Phase 1 convenience layer. For production, pair it with proper Firebase-admin user authentication before relying on strict Firestore rules.

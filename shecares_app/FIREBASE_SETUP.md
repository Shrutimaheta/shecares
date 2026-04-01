# SheCares Firebase Setup

This app is now wired for a production Firebase flow, but your real Firebase project files still need to be added locally.

## 1. Install the Firebase tools once

```bash
npm install -g firebase-tools
flutter pub global activate flutterfire_cli
```

## 2. Log in to Firebase

```bash
firebase login
```

## 3. Generate the real FlutterFire config

Run this from the project root:

```bash
flutterfire configure
```

Choose your SheCares Firebase project and register the Android, iOS, and Web apps.
This command should replace the placeholder values in `lib/firebase_options.dart` with real ones.

## 4. Add the Android Firebase file

Put your Firebase Android config file here:

```text
android/app/google-services.json
```

You already mentioned you have this file.

## 5. Add the iOS Firebase file

In Firebase console, add an iOS app if you have not already done it.
Download `GoogleService-Info.plist` and place it here:

```text
ios/Runner/GoogleService-Info.plist
```

## 6. Enable the required Firebase products

In Firebase console:
- Authentication -> enable Phone
- Firestore Database -> create database
- Storage -> create the default bucket
- Firestore Rules -> deploy the rules from `firestore.rules`
- Storage Rules -> deploy the rules from `storage.rules`

Deploy rules with:

```bash
firebase deploy --only firestore:rules,storage
```

## 7. Run the app

Customer app:

```bash
flutter run
```

Admin web app:

```bash
flutter run -d chrome -t lib/main_admin.dart
```

## 8. Create the first admin account

1. Sign in once with the phone number you want to use as admin.
2. Open Firestore in Firebase console.
3. Open the `users` collection.
4. Find that signed-in user document.
5. Change `role` from `customer` to `super_admin` or `admin`.
6. Open the admin app again.
7. Use the `Seed Phase 1 data` button in the top bar.

## 9. What is live now

After the Firebase files are added correctly:
- phone OTP login uses Firebase Auth
- admin access is role-based, not PIN-based
- products, orders, agents, and NGO partners are Firestore-backed
- cart sync is persisted through Firestore
- checkout validates pincode, cart limits, and stock
- order placement decrements stock and clears the saved cart
- admin order status updates appear live in customer tracking
- product image uploads store the file in Firebase Storage and save the linked metadata on the product document

## 10. If login or uploads still do not work

Check these first:
- `lib/firebase_options.dart` no longer contains placeholder values
- Phone Auth is enabled in Firebase
- Firestore and Storage are both created in Firebase
- Your signed-in user has `role: admin` or `role: super_admin` for admin access
- Storage rules from `storage.rules` are deployed
- You are running the admin panel with `-t lib/main_admin.dart`

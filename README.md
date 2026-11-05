# Campus Access

Android Flutter app for In-Class Activity 13B. The app uses Firebase Authentication for email/password registration, sign-in, sign-out, and password changes. An auth-state stream selects the signed-out form or the protected profile.

## Setup

1. Create a Firebase project and enable Email/Password in Authentication.
2. Run `flutterfire configure --platforms=android` in this folder. This generates the Android client configuration, which is kept local.
3. Run `flutter pub get` and `flutter run -d DEVICE_ID` using an Android device from `flutter devices`.

## Verify the release

Run `flutter analyze` and `flutter build apk --release`. Install the resulting APK on Android. Use a fictional test email and verify registration, profile email, session restoration after restart, sign-out, invalid form feedback, and sign-in. Change the password while signed in, sign out, then check that the old password fails and the new one works. If Firebase asks for a recent sign-in, enter the current password in the recovery form and retry.

Passwords are sent to Firebase Authentication and are never stored in Firestore. The auth gate controls which screen appears. If a future feature adds user records, enforce ownership with server-side rules.

The live Android integration check uses a generated fictional account and passwords. Run it only in a disposable lab project with Email/Password enabled.

```sh
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/auth_flow_test.dart -d DEVICE_ID
```

The driver saves screenshots in the local submission folder. To test persistence with the release APK after this run, add `--keep-app-running`, install the release APK over the test build without clearing data, and restart the app. The test run does not cover the recent-login challenge.

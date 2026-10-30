# BRAINX Global Arena — starter source

This is a real Flutter source project for Android and iOS. It includes four playable mini-game modes, a timer, scoring, local persistence, a player nickname, and a local leaderboard.

## Important status
This is a **working starter build**, not a published production game. The local leaderboard is real on that device only. Firebase cloud score submission is attempted only when Firebase is configured and a user is signed in. It is not yet a verified worldwide leaderboard. Do not advertise it as cheat-proof or global until a trusted server validates game sessions and scores.

## Run
1. Install Flutter SDK and Android Studio (Android) / Xcode on a Mac (iOS).
2. In this folder run `flutter create .`
3. Run `flutter pub get`
4. Configure Firebase using FlutterFire CLI (`dart pub global activate flutterfire_cli`, then `flutterfire configure`) for Android and iOS. This generates `lib/firebase_options.dart`; then change `main()` to `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` and add `import 'firebase_options.dart';`.
5. Enable Firebase Authentication providers and create Firestore.
6. Deploy `firestore/firestore.rules` as a starting point, then replace client score submission with a trusted backend/Cloud Function before public competitive launch.
7. Run `flutter run`.

## iPhone and Android
One Flutter codebase targets both platforms. iOS builds require macOS/Xcode. Android builds require Android SDK. Store publishing needs the developer accounts, signing, privacy policy, and store review.

## Admin and ads
Admin panel and ad network integration are deliberately not faked in this starter. Add them only after secure backend roles and ad-network approval/configuration exist. Never put service-account private keys in the app. Never give admin rights based only on a client-side Firestore document check.

## Next production milestones
- Firebase Auth screens and account linking.
- Trusted score validation API / Cloud Functions and anti-cheat.
- Global, country, weekly, and all-time leaderboards using server-approved score records.
- Admin custom claims, protected admin APIs, audit logs.
- AdMob native integration and consent/privacy compliance.
- Automated tests, accessibility, localization, and device QA.

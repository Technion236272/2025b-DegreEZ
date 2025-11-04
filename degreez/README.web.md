This document explains how to configure and run the DegreEZ Flutter app for Web.

Quick overview
- The project supports building for web, but Firebase (Auth/Firestore) and Google Sign-In must be configured for web separately.
- You can either use the FlutterFire CLI to auto-generate `lib/services/firebase_options.dart` or provide web credentials through `.env` (see `.env.example`).

1) Prerequisites
- Install Flutter (stable channel) and enable web:

  flutter channel stable
  flutter upgrade
  flutter config --enable-web
  flutter devices

- Install Dart pub global tools (optional):
  dart pub global activate flutterfire_cli

2) Configure Firebase (recommended)
Option A — FlutterFire CLI (recommended, automated):
- Run from the project root (`degreez` folder):

  dart pub global activate flutterfire_cli
  flutterfire configure

- The CLI will ask you to select a Firebase project and platforms. Choose the web app (or create one) and the CLI will generate `lib/services/firebase_options.dart` with web options.
- After that run:

  flutter pub get
  flutter run -d chrome

Option B — Manual (.env) (quick, works for development):
- Copy `.env.example` to `.env` and fill the WEB_* and WEB_GOOGLE_CLIENT_ID values with your Firebase Web App configuration.
- The app reads these values at startup (via `flutter_dotenv`) and will initialize Firebase when running web.

3) Google Sign-In on Web
- You must create an OAuth client for Web in the Google Cloud Console and either:
  - Put the web client id value in `.env` as `WEB_GOOGLE_CLIENT_ID`, or
  - Replace the placeholder meta tag in `web/index.html` with your client id:

    <meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">

- The app now attempts to use the client id from `.env` automatically when running on web.

4) Run locally in Chrome

  flutter pub get
  flutter run -d chrome

If Firebase is not configured, the app will start but Firebase-backed features will be unavailable (login, Firestore, etc.).

5) Build for production & deploy
- Build:

  flutter build web --release

- Deploy options:
  - Firebase Hosting (recommended):
    npm i -g firebase-tools
    firebase login
    firebase init hosting
    # set public directory to build/web
    firebase deploy --only hosting

  - Netlify / Vercel: connect repo and set build command `flutter build web` with publish directory `build/web`.

6) Notes and next steps
- Mobile-only APIs (dart:io file access, native location flows) may require web implementations:
  - PDF/file flows: adapt to use bytes and web file pickers.
  - Location: use geolocator or browser geolocation on web.
- After you get Firebase configured and running, test the app end-to-end and I can help convert mobile-only services (pdf, file, location) to web-safe implementations.

If you want, I can now:
- Run the FlutterFire CLI in your workspace and apply the generated `firebase_options.dart` (requires interactive auth), or
- Continue adding small web-safe stubs (PDF/file stubs) so the app UI compiles and runs without Firebase, or
- Walk you through the FlutterFire CLI steps and validate the generated files.

Tell me which next step you prefer and I'll proceed.

# Premisave

Flutter app for the Premisave real estate platform. It talks to the auth-service
(Spring Boot) and runs on Android, iOS, web and desktop.

## Run it

```bash
flutter pub get
dart run flutter_launcher_icons      # once, writes the launcher icons
flutter run -d chrome --web-port=3000
```

Point the app at your backend with `--dart-define`:

| Define | Default | Purpose |
| --- | --- | --- |
| `BASE_URL` | `http://localhost:8080` (web, desktop, iOS) or `http://10.0.2.2:8080` (Android emulator) | auth-service address |
| `GOOGLE_SERVER_CLIENT_ID` | empty | web client ID used to get a Google ID token |
| `GOOGLE_CLIENT_ID` | empty | iOS or web Google client ID |

```bash
flutter run --dart-define=BASE_URL=https://api.example.com
```

On a physical phone use your computer's LAN address, for example
`--dart-define=BASE_URL=http://192.168.1.20:8080`.

## What is connected

* Sign in, sign up, email verification, resend activation, forgot and reset password
* Google and Facebook sign in
* Rotating refresh tokens, remembered device, session expiry handling
* Profile, photo upload, change password, location, who viewed you
* Security center: sessions, devices, sign-in history, security events, security reports
* People: directory, follow, like, reviews, public profiles
* Home owner application: guided form, document upload, status, withdraw, reapply
* Staff review queue and decisions, administrator approval
* Administrator user management and audit trail

The finance, operations, support and booking modules still show sample data until
their services exist. The Home screen says so.

## Layout

```
lib/
  main.dart
  src/
    core/        theme, branding, config, network, storage, shared widgets
    data/        models, repositories, social sign in
    state/       Riverpod providers and the session controller
    router/      go_router with role guards
    features/    auth, home, account, security, people, application, staff, admin, modules
```

## Environments

Development, staging and production each have a JSON file in `config/env/`.

```bash
flutter run -d chrome --web-port=3000 --dart-define-from-file=config/env/development.json
APP_ENV=staging ./run_web.sh
flutter build web --release --dart-define-from-file=config/env/production.json
```

See `config/env/README.md` for the keys.

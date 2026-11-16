# Environments

One JSON file per environment, passed to Flutter with `--dart-define-from-file`.

| File | Use |
| --- | --- |
| `development.json` | local backend |
| `staging.json` | staging backend |
| `production.json` | live backend |

```bash
flutter run -d chrome --web-port=3000 --dart-define-from-file=config/env/development.json
flutter run --dart-define-from-file=config/env/staging.json
flutter build apk --release --dart-define-from-file=config/env/production.json
flutter build web --release --dart-define-from-file=config/env/production.json
```

Keys:

* `BASE_URL`: auth-service address. Leave empty in development to use the platform default.
* `GOOGLE_SERVER_CLIENT_ID`, `GOOGLE_CLIENT_ID`: Google sign-in client IDs.
* `GITHUB_CLIENT_ID`, `GITHUB_REDIRECT_URI`: GitHub sign in. The redirect must equal the callback URL of the GitHub OAuth app. Leave it empty to hide the button.
* `FACEBOOK_APP_ID`: Facebook app ID, needed on web and desktop.
* `SUPPORT_EMAIL`: shown on help screens.
* `GEOCODER_URL` (optional): address search server. Defaults to the free public Photon server `https://photon.komoot.io`, which is meant for modest traffic. For a large launch run your own Photon server or use a compatible provider.
* `GOOGLE_MAPS_ANDROID_KEY`, `GOOGLE_MAPS_IOS_KEY`, `GOOGLE_MAPS_WEB_KEY` (optional): public Google Maps keys, one per platform. When a platform's key is set, the app draws Google Maps there. When it is empty, or on Linux, Windows and macOS, it uses OpenStreetMap. Create each key in the Google Cloud console and restrict it: Android to the app's package name and signing SHA-1 with the Maps SDK for Android, iOS to the bundle ID with the Maps SDK for iOS, and web to your site's addresses (HTTP referrers) with the Maps JavaScript API. These are not the auth-service key, which is a secret and must never be placed here. Android reads its key from this same file at build time. iOS also needs the key in `ios/Flutter/Maps.xcconfig`, see below.
* `MAP_TILE_URL` (optional): map tile template such as `https://tiles.example.com/{z}/{x}/{y}.png`. Defaults to the free OpenStreetMap server, which has a fair use policy. For a large launch use a tile provider with an account.

A Flutter app ships inside the download, so anything in these files can be read by users.
Only put public values here (URLs, client IDs). Never put passwords, API secrets or private keys.

For personal overrides that must not be committed, create `config/env/<name>.local.json`.
Files ending in `.local.json` are git ignored.

## Google Maps on iOS

The iOS key is read by the native app, so put it in `ios/Flutter/Maps.xcconfig` as well (this file is git ignored):

```
GOOGLE_MAPS_IOS_KEY=your-ios-key
```

Without that line the app still starts, but keep `GOOGLE_MAPS_IOS_KEY` empty in the JSON too, so it uses OpenStreetMap on iOS instead of a blank map.

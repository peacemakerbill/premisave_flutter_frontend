# Environments

One JSON file per environment, handed to Flutter with `--dart-define-from-file`. This page explains every key, which file to edit, and how to keep your own settings out of git.

| File | Use | Committed |
| --- | --- | :---: |
| `development.json` | A backend on your own computer | yes |
| `staging.json` | A shared test backend | yes |
| `production.json` | The live backend | yes |
| `<anything>.local.json` | Your personal overrides | **no**, git ignores it |

```bash
# develop: copy a file to a .local.json name first, so your changes stay private
cp config/env/development.json config/env/dev.local.json
flutter run -d chrome --web-port=3000 --dart-define-from-file=config/env/dev.local.json

# the other environments
flutter run --dart-define-from-file=config/env/staging.json
flutter build apk --release --dart-define-from-file=config/env/production.json
flutter build web --release --dart-define-from-file=config/env/production.json
APP_ENV=staging ./run_web.sh        # web on port 3000, with the file named by APP_ENV
```

> **Restart after every change.** Flutter reads these values only when the app launches. Hot reload and hot restart do not see an edited file: stop the app and run the command again.

## What goes in these files

**A Flutter app ships inside the download, so anything in these files can be read by users.** Only public values belong here: addresses, public client IDs, public map keys. Never put a password, a client secret, an API secret or a private key here, and never the Google key the backend uses for places search. Those live in the backend's `.env`.

If you are unsure whether something is public, ask: *would it matter if anyone who downloads the app could read this?* If yes, it belongs on the server.

## Keys

### Backend

| Key | Meaning | If empty |
| --- | --- | --- |
| `BASE_URL` | Address of the auth-service, with no trailing slash, for example `https://api.example.com` | A default for the platform: `http://localhost:8080`, or `http://10.0.2.2:8080` on the Android emulator |
| `MESSENGER_URL` | Address of the messenger service, with no trailing slash. The chat socket is opened on the same host at `/ws-messenger` | A default for the platform: `http://localhost:8081`, or `http://10.0.2.2:8081` on the Android emulator |
| `GROUP_INVITE_BASE_URL` | Start of the group invite links the app shows when the server does not send a full link, for example `https://premisave.com/join` | `https://premisave.com/join` |
| `SUPPORT_EMAIL` | The address shown on help and contact screens | A development address. **Set it for production** |

On a real phone `localhost` means the phone itself, so set `BASE_URL` to your computer's address on the network, for example `http://192.168.1.20:8080`.

### Social sign in

| Key | Meaning | If empty |
| --- | --- | --- |
| `GOOGLE_SERVER_CLIENT_ID` | The OAuth **web** client ID. Android needs it, or Google returns no ID token | The project's own client |
| `GOOGLE_CLIENT_ID` | The client ID for web, iOS and the desktop code flow. Usually the same as above | The project's own client |
| `GITHUB_CLIENT_ID` | The GitHub OAuth app's client ID (public) | The project's own app |
| `GITHUB_REDIRECT_URI` | The address every browser based sign in returns to. Must equal the callback URL registered with the provider | `http://localhost:3000/auth.html` in debug builds, nothing in release builds |
| `FACEBOOK_APP_ID` | The Facebook app ID (public). Needed on web, macOS, Linux and Windows | The project's own app |

`GITHUB_REDIRECT_URI` is shared by Google and Facebook on desktop as well, in spite of its name. A sign in button is always shown, and tapping one that cannot work here names the key that is missing. All the detail, provider by provider, is in [docs/SIGN_IN_PROVIDERS.md](../../docs/SIGN_IN_PROVIDERS.md).

### Maps and address search

| Key | Meaning | If empty |
| --- | --- | --- |
| `GOOGLE_MAPS_ANDROID_KEY` | Public Google Maps key for Android, restricted to the app's package name and signing SHA-1 and to the Maps SDK for Android | Android uses OpenStreetMap |
| `GOOGLE_MAPS_IOS_KEY` | Public key for iOS, restricted to the bundle ID and the Maps SDK for iOS. Also needed in `ios/Flutter/Maps.xcconfig`, see below | iOS uses OpenStreetMap |
| `GOOGLE_MAPS_WEB_KEY` | Public key for the web, restricted to your site's addresses (HTTP referrers) and the Maps JavaScript API | The web uses OpenStreetMap |
| `GEOCODER_URL` | An address search server compatible with Photon | The free public `https://photon.komoot.io`, meant for modest traffic |
| `MAP_TILE_URL` | A tile template such as `https://tiles.example.com/{z}/{x}/{y}.png` | The free OpenStreetMap server, which has a fair use policy |

Linux, Windows and macOS always use OpenStreetMap, because Google has no map component for them. For a large launch, use a tile provider and a search server with an account, and set the last two keys. How to create and restrict the Google keys is in [docs/MAPS_AND_PLACES.md](../../docs/MAPS_AND_PLACES.md).

## Google Maps on iOS

The iOS key is read by the native app, so it also goes in `ios/Flutter/Maps.xcconfig`. That file is git ignored, so your key never reaches the repository. Create it once:

```bash
printf 'GOOGLE_MAPS_IOS_KEY=your-ios-key\n' > ios/Flutter/Maps.xcconfig
cd ios && pod install && cd ..
```

Without that file the app still builds and starts. In that case keep `GOOGLE_MAPS_IOS_KEY` **empty in the JSON too**, so iOS uses OpenStreetMap instead of showing a blank map. Android needs no such file: it reads its key from this same JSON while building.

## A complete example

A `dev.local.json` for a computer running the backend locally, with Google Maps on the web only:

```json
{
  "BASE_URL": "",
  "SUPPORT_EMAIL": "you@example.com",
  "GITHUB_REDIRECT_URI": "http://localhost:3000/auth.html",
  "GOOGLE_MAPS_WEB_KEY": "your-web-key"
}
```

Keys you leave out behave as if empty, so a file can be as short as you like.

## Checklist before a release

- [ ] `production.json` has your real `https` `BASE_URL` and a `SUPPORT_EMAIL` you read.
- [ ] `GITHUB_REDIRECT_URI` is your production address, registered with every provider and listed in the backend's `OAUTH_ALLOWED_REDIRECT_URIS`.
- [ ] Each map key is restricted, and your production domain and release signing SHA-1 are on the right ones.
- [ ] You searched the file for anything that looks like a secret, and found nothing.

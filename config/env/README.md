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

A Flutter app ships inside the download, so anything in these files can be read by users.
Only put public values here (URLs, client IDs). Never put passwords, API secrets or private keys.

For personal overrides that must not be committed, create `config/env/<name>.local.json`.
Files ending in `.local.json` are git ignored.

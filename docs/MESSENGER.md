# Messenger

The Messages tab talks to the **premisave-messenger-service**. It is a second backend next to the auth-service. The app signs in once, with the auth-service, and sends the same access token to the messenger service. When the token expires the auth-service refreshes it, for both.

## What it does

| Area | What you can do |
| --- | --- |
| Chats | Private chats, search, mark as unread, delete a chat, unread badge on the Messages tab |
| Messages | Send text, reply, edit within the allowed time, delete for me or for everyone, copy, retry a failed send, search inside a chat, mention people in a group |
| Reactions | Tap an emoji under a message, or long press for the full emoji list |
| Files | Photos, videos, audio and documents with a progress ring. Photos open full screen |
| Live | New messages, delivery ticks and read receipts, typing, online and last seen, reactions and group changes all arrive over the socket |
| Groups | Create, picture, name, description, add and remove members, admins, make someone the owner, leave. An owner must choose a new owner before leaving |
| Invites | Invite link and QR code with an expiry and a use limit, revoke, join by link, join by scanning a QR code, tap an invite link inside a message |
| Statuses | Text, photo, video and audio statuses for up to a day, view, like, react, comment, who saw it, past statuses |

## Settings

Two keys, both optional, in the files under `config/env/`:

| Key | Default |
| --- | --- |
| `MESSENGER_URL` | `http://localhost:8081`, or `http://10.0.2.2:8081` on the Android emulator |
| `GROUP_INVITE_BASE_URL` | `https://premisave.com/join` |

On a real phone use your computer's address on the network, for example `--dart-define=MESSENGER_URL=http://192.168.1.20:8081`. Restart the app after changing a key.

## Running it

1. Start the auth-service on port 8080.
2. Start the messenger service on port 8081. It needs MongoDB and Redis, and it must use the same `JWT_SECRET` as the auth-service so the token is accepted.
3. Run the app as usual.

The messenger service must also allow the app's origin when you run on the web (CORS and the STOMP endpoint `/ws-messenger`). On the web the socket cannot send headers, so the app sends the token in the STOMP CONNECT frame, which is what the service reads.

## Where the code is

| Folder or file | Job |
| --- | --- |
| `lib/src/core/network/messenger_socket.dart` | STOMP over a plain WebSocket, with reconnect and heartbeat |
| `lib/src/data/repositories/messenger_repository.dart` | Every REST call |
| `lib/src/data/models/messenger_models.dart` | Chats, messages, groups, invites, statuses |
| `lib/src/state/messenger_controller.dart` | Holds the chats and open conversations, sends optimistically, reacts to live events |
| `lib/src/state/messenger_providers.dart` | Group, invite and status data for the screens |
| `lib/src/features/messenger/` | All the screens and widgets |

## Group invite links from outside the app

A link such as `https://premisave.com/join/CODE` opens `/join/CODE` in the app, which shows the group and a Join button. Opening links from the system into the app needs the usual platform setup (Android app links, iOS associated domains) and is not part of this change. Scanning the QR code inside the app, or pasting the link on the join screen, works everywhere.

## Camera permission for scanning

- **Android** and **iOS**: the camera permission and the iOS usage text are already declared in `AndroidManifest.xml` and `Info.plist`. The first scan asks the person to allow the camera.
- **macOS**: add `NSCameraUsageDescription` to the macOS `Info.plist` and the camera entitlement if you want scanning there.
- **Web**: needs HTTPS or localhost.
- **Linux and Windows**: no camera scanner. The join screen asks for the pasted link instead.

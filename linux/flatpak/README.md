# Premisave as a Flatpak

A Flatpak carries the libraries the app needs, so a person installs the app and nothing else. They only need Flatpak
itself, which most Linux desktops already have.

## Build it

On the machine that has Flutter:

```bash
sudo apt install flatpak flatpak-builder
bash linux/flatpak/build_flatpak.sh
```

The script gets the GNOME runtime, builds the app, packs it, checks that no library is missing, and writes
`build/premisave.flatpak`. Use `config/env/production.json` (the default) for something you give to other people,
because `development.json` points at localhost.

## Install and run it

```bash
flatpak install --user build/premisave.flatpak
flatpak run com.premisave.premisave_frontend
```

## What is inside and what is not

Inside the Flatpak: GTK, the web view used by sign in, GStreamer for audio, libsecret for the saved sign in, the file
windows, PDF rendering (bundled with the app).

Still provided by the person's computer: the secret service that stores the saved sign in (GNOME Keyring or KWallet,
through the Flatpak portal) and Flatpak's own portal service, which opens links and files in other apps. Without a
secret service the app still works, but the sign in is not remembered after the app closes.

Permissions are listed under `finish-args` in `com.premisave.premisave_frontend.yml`.

## Files

| File | Job |
| --- | --- |
| `com.premisave.premisave_frontend.yml` | The Flatpak recipe |
| `build_flatpak.sh` | Builds and packs everything |
| `premisave.sh` | Starts the app inside the Flatpak |
| `*.desktop`, `*.metainfo.xml`, `*.png` | The menu entry, the description and the icon |

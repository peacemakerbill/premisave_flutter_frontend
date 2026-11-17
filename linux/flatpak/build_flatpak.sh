#!/usr/bin/env bash
# Builds the Premisave Linux app as a Flatpak, and a single file you can give to other people.
#
#   bash linux/flatpak/build_flatpak.sh                          uses config/env/production.json
#   bash linux/flatpak/build_flatpak.sh config/env/staging.json  uses another environment file
#
# Run it from the project folder. The result is build/premisave.flatpak. Anyone installs it with
#   flatpak install --user premisave.flatpak
# and needs nothing else except Flatpak itself.
#
# This machine (the one that builds) needs: flutter, flatpak and flatpak-builder, and the Linux build tools Flutter asks for.
set -euo pipefail

APP_ID="com.premisave.premisave_frontend"
RUNTIME="50"
ENV_FILE="${1:-config/env/production.json}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
cd "$ROOT"

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing: $1" >&2
    echo "$2" >&2
    exit 1
  fi
}
need flutter "Install Flutter and put it on your PATH."
need flatpak "Install it with: sudo apt install flatpak"
need flatpak-builder "Install it with: sudo apt install flatpak-builder"

if [ ! -f "$ENV_FILE" ]; then
  echo "Environment file not found: $ENV_FILE" >&2
  exit 1
fi

echo "1/5 Getting the Flatpak runtime (once, about 1 GB)"
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user -y flathub "org.gnome.Platform//$RUNTIME" "org.gnome.Sdk//$RUNTIME"

echo "2/5 Building the app with $ENV_FILE"
flutter build linux --release --dart-define-from-file="$ENV_FILE"

echo "3/5 Packing the Flatpak"
cd "$HERE"
flatpak-builder --user --force-clean --install --repo=repo build-dir "$APP_ID.yml"

echo "4/5 Checking that the runtime has every library the app needs"
if flatpak run --command=sh "$APP_ID" -c '
  bad=0
  for f in /app/premisave/premisave_frontend /app/premisave/lib/*.so*; do
    out="$(LD_LIBRARY_PATH=/app/premisave/lib ldd "$f" 2>&1 | grep "not found" || true)"
    if [ -n "$out" ]; then echo "$f"; echo "$out"; bad=1; fi
  done
  exit $bad
'; then
  echo "Every library was found."
else
  echo "" >&2
  echo "The libraries listed above are not in the runtime. Send me this output." >&2
  exit 1
fi

echo "5/5 Making the single file to share"
mkdir -p "$ROOT/build"
flatpak build-bundle --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo repo "$ROOT/build/premisave.flatpak" "$APP_ID"

cat <<DONE

Done.
  Run it here:        flatpak run $APP_ID
  File to give away:  $ROOT/build/premisave.flatpak
  Install elsewhere:  flatpak install --user premisave.flatpak
DONE

#!/usr/bin/env bash
# Premisave App - Flutter Web Runner (Linux)

set -e

# Colors
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

# Logo
echo -e "${GREEN}
  _____                         _
 |  __ \                       | |
 | |__) | __ ___ _ __ ___   ___| |__   __ _ _ __ ___
 |  ___/ '__/ _ \ '_ \` _ \ / _ \ '_ \ / _\` | '__/ _ \\
 | |   | | |  __/ | | | | |  __/ |_) | (_| | | |  __/
 |_|   |_|  \___|_| |_| |_|\___|_.__/ \__,_|_|  \___|
                APP${RESET}"
echo -e "${YELLOW}Premisave App - Flutter Web${RESET}\n"

# Check Flutter
if ! command -v flutter >/dev/null 2>&1; then
    echo -e "${RED}Error: Flutter not found${RESET}"
    exit 1
fi

# Detect browser
if command -v chromium >/dev/null 2>&1; then
    BROWSER="chromium"
elif command -v google-chrome >/dev/null 2>&1; then
    BROWSER="chrome"
elif command -v brave-browser >/dev/null 2>&1; then
    BROWSER="brave"
else
    echo -e "${RED}Error: No supported browser found (Chrome/Chromium/Brave)${RESET}"
    exit 1
fi

echo -e "${GREEN}✓ Browser: $BROWSER${RESET}"
echo -e "${GREEN}✓ Running on port 3000...${RESET}\n"

# Run Flutter web
flutter run -d "$BROWSER" --web-port=3000
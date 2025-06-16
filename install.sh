#!/usr/bin/env bash

set -e

INSTALL_DIR="/opt/discord-updater"
DESKTOP_FILE="/usr/share/applications/discord-updater.desktop"
ICON_NAME="discord-updater"
ICON_SRC="assets/discord-staff-badge.svg"
ICON_DEST="/usr/share/icons/hicolor/scalable/apps/${ICON_NAME}.svg"

echo "🔧 Installing Discord Updater..."

# Copy main script
sudo mkdir -p "$INSTALL_DIR"
sudo cp discord-updater.sh "$INSTALL_DIR"
sudo chmod +x "$INSTALL_DIR/discord-updater.sh"

# Copy icon
echo "🎨 Installing icon..."
sudo mkdir -p "$(dirname "$ICON_DEST")"
sudo cp "$ICON_SRC" "$ICON_DEST"

# Copy .desktop file
echo "📋 Creating desktop entry..."
sudo cp assets/discord-updater.desktop "$DESKTOP_FILE"

# Update icon cache (required for desktop environments to recognize new icons)
if command -v gtk-update-icon-cache &>/dev/null; then
    sudo gtk-update-icon-cache /usr/share/icons/hicolor
fi

echo "✅ Installation complete!"
echo "🚀 You can now search for 'Discord Updater' in your application menu."

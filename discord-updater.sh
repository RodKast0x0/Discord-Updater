#!/usr/bin/env bash

set -e

CACHE_FILE="$HOME/.discord_latest_version"
CACHE_EXPIRY=$((24 * 60 * 60))
DISCORD_DEB_URL="https://discord.com/api/download?platform=linux&format=deb"
TEMP_DEB="/tmp/discord.deb"

get_latest_version() {
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_time version now
        now=$(date +%s)
        cache_time=$(jq -r .timestamp "$CACHE_FILE" | cut -d. -f1)  # Strip decimals
        version=$(jq -r .version "$CACHE_FILE")

        if [[ $((now - cache_time)) -lt $CACHE_EXPIRY && -n "$version" ]]; then
            echo "📂 Using cached latest version" >&2
            echo "$version"
            return
        else
            echo "⏳ Cache expired, refreshing..." >&2
        fi
    else
        echo "📂 No cache found, fetching from web..." >&2
    fi

    local redirected_url version
    redirected_url=$(curl -sI -L -o /dev/null -w '%{url_effective}' "$DISCORD_DEB_URL")
    version=$(echo "$redirected_url" | grep -oP 'discord-\K[0-9]+\.[0-9]+\.[0-9]+(?=\.deb)')

    if [[ -n "$version" ]]; then
        echo "🌐 Fetched and cached latest version" >&2
        jq -n --arg v "$version" --argjson t "$(date +%s)" \
            '{version: $v, timestamp: $t}' > "$CACHE_FILE"
        echo "$version"
    else
        echo "⚠️ Failed to extract version from URL" >&2
        return 1
    fi
}

get_installed_version() {
    if dpkg -s discord &>/dev/null; then
        dpkg -s discord | awk -F': ' '/^Version:/ { print $2 }'
    else
        echo "⚠️ Discord not installed." >&2
        return 1
    fi
}

update_discord() {
    echo "🔄 Downloading latest Discord version..."
    wget --quiet --show-progress "$DISCORD_DEB_URL" -O "$TEMP_DEB"

    echo "🔄 Installing update (requires sudo)..."
    sudo dpkg -i "$TEMP_DEB" || true

    echo "🔄 Resolving dependencies..."
    sudo apt-get install -f -y

    echo "🧹 Cleaning up..."
    rm -f "$TEMP_DEB"

    echo "✅ Discord updated successfully!"
}

main() {
    echo -e "\n🔍 Checking Discord versions..."

    latest_version=$(get_latest_version) || exit 1
    installed_version=$(get_installed_version) || exit 1

    echo -e "• Installed: $installed_version\n• Latest:    $latest_version"

    if dpkg --compare-versions "$installed_version" lt "$latest_version"; then
        echo -e "\n🎉 New version available! Updating..."
        if update_discord; then
            echo -e "\n🔄 Update completed!"
        else
            echo -e "\n❌ Update failed!"
            exit 1
        fi
    else
        echo -e "\n✅ Discord is up to date"
    fi
}

main

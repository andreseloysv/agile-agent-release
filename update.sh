#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Agile Agent — Auto-updater
# Runs hourly via a LaunchAgent. Silently pulls the latest release and
# restarts the main service only when something actually changed.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

INSTALL_DIR="${AGILE_AGENT_HOME:-$HOME/.agile-agent}"
PLIST_NAME="com.agile-agent"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"
LOG="/tmp/agile-agent-update.log"

# ── Helper: locate the VS Code CLI wherever VS Code is installed ───────────
# PATH first, then Spotlight (finds VS Code even if the app was moved or renamed,
# or lives in ~/Applications or on another volume), then the usual locations.
find_vscode_cli() {
    local home="${1:-$HOME}" app c
    if command -v code >/dev/null 2>&1; then command -v code; return 0; fi
    local apps=()
    if command -v mdfind >/dev/null 2>&1; then
        while IFS= read -r app; do
            [[ "$app" == *.app ]] && apps+=("$app")
        done < <(mdfind "kMDItemCFBundleIdentifier == 'com.microsoft.VSCode*'" 2>/dev/null || true)
    fi
    apps+=("/Applications/Visual Studio Code.app" "$home/Applications/Visual Studio Code.app" \
           "/Applications/Visual Studio Code - Insiders.app" "$home/Applications/Visual Studio Code - Insiders.app")
    for app in "${apps[@]}"; do
        for c in "$app/Contents/Resources/app/bin/code" "$app/Contents/Resources/app/bin/code-insiders"; do
            if [[ -x "$c" ]]; then echo "$c"; return 0; fi
        done
    done
    for c in /usr/local/bin/code /opt/homebrew/bin/code /usr/bin/code /snap/bin/code; do
        if [[ -x "$c" ]]; then echo "$c"; return 0; fi
    done
    return 1
}

log() { echo "[$(date '+%H:%M:%S')] $1" >> "$LOG"; }

log "Checking for updates..."

cd "$INSTALL_DIR" || { log "Install dir not found, skipping."; exit 0; }

# Capture current commit before pulling
BEFORE=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

# Remove stale index.lock from crashed git processes
rm -f "$INSTALL_DIR/.git/index.lock" 2>/dev/null || true

# Git LFS is no longer required as binaries are pulled from GitHub Releases directly

# Pull latest (quietly), forcing through any local changes
echo "Fetching latest from origin..."
git fetch --quiet origin main 2>>"$LOG" || { log "Network error, skipping."; echo "❌ Network error. Check your connection."; exit 0; }
echo "Applying updates..."
git reset --hard origin/main --quiet 2>>"$LOG" || { log "Cannot reset to origin/main, skipping."; echo "❌ Cannot apply update."; exit 0; }

# Download updated binaries from GitHub Releases
echo "Downloading latest binaries..."
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then BINARY_NAME="agile-agent-arm64"; else BINARY_NAME="agile-agent-x86_64"; fi
curl -L --fail -s "https://github.com/andreseloysv/agile-agent-release/releases/latest/download/$BINARY_NAME" -o "$INSTALL_DIR/$BINARY_NAME" || log "WARNING: Failed to download $BINARY_NAME"
chmod +x "$INSTALL_DIR/$BINARY_NAME" 2>/dev/null || true

curl -L --fail -s "https://github.com/andreseloysv/agile-agent-release/releases/latest/download/Agile.Agent.dmg" -o "$INSTALL_DIR/Agile Agent.dmg" || true
curl -L --fail -s "https://github.com/andreseloysv/agile-agent-release/releases/latest/download/copilot-bridge.vsix" -o "$INSTALL_DIR/copilot-bridge.vsix" || true
if [[ -f "$INSTALL_DIR/copilot-bridge.vsix" ]] && CODE_CMD="$(find_vscode_cli "$HOME")"; then
    env -u ELECTRON_RUN_AS_NODE "$CODE_CMD" --install-extension "$INSTALL_DIR/copilot-bridge.vsix" --force >>"$LOG" 2>&1 \
        && log "VS Code extension updated via $CODE_CMD" || log "WARNING: VS Code extension update failed"
fi

# ⚠️ DO NOT use `git clean -fd` here!
# The install dir contains untracked user data:
#   data/agile-agent.db  — SQLite database (projects, conversations, env vars)
#   data/memories/        — long-term memory store
# git clean -fd would DELETE all of it, causing total data loss.
# Only remove known obsolete files if needed:
# rm -f "$INSTALL_DIR/some-old-file" 2>/dev/null || true

AFTER=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

if [[ "$BEFORE" == "$AFTER" ]]; then
    log "Already up to date ($AFTER)."
    echo "✅ Already up to date."
    exit 0
fi

log "Updated $BEFORE → $AFTER. Restarting service..."
echo "✅ Updated! Restarting service..."

# Graceful shutdown: check if the server is actively processing a request
# by checking for an active WebSocket connection. If busy, wait up to 30s.
if command -v curl &>/dev/null; then
    for i in {1..6}; do
        ACTIVE=$(curl -sf "http://localhost:4372/api/health" 2>/dev/null | grep -c '"activeRuns":[1-9]' || echo "0")
        if [[ "$ACTIVE" == "0" ]]; then
            break
        fi
        log "Server is busy (active run detected). Waiting 5s before restart... ($i/6)"
        sleep 5
    done
fi

# Restart the main LaunchAgent so the new binary / frontend are loaded
launchctl unload "$PLIST_PATH" 2>>"$LOG" || true
sleep 1
launchctl load -w "$PLIST_PATH" 2>>"$LOG" || true

# Update the macOS UI App if DMG exists
DMG_PATH="$INSTALL_DIR/Agile Agent.dmg"
if [[ -f "$DMG_PATH" ]]; then
    log "Mounting DMG to update Agile Agent.app..."
    MOUNT_OUT=$(hdiutil attach "$DMG_PATH" -nobrowse -noverify -noautoopen 2>/dev/null || true)
    MOUNT_DIR=$(echo "$MOUNT_OUT" | grep "/Volumes/" | tail -1 | awk -F'\t' '{print $NF}')

    if [[ -n "$MOUNT_DIR" && -d "$MOUNT_DIR/Agile Agent.app" ]]; then
        log "Closing existing app and copying new version..."
        pkill -f "Agile Agent.app" || true
        sleep 1

        APP_DEST="/Applications/Agile Agent.app"
        rm -rf "$APP_DEST" 2>/dev/null || true
        
        if ! cp -R "$MOUNT_DIR/Agile Agent.app" "$APP_DEST" 2>/dev/null; then
            mkdir -p "$HOME/Applications"
            APP_DEST="$HOME/Applications/Agile Agent.app"
            rm -rf "$APP_DEST" 2>/dev/null || true
            cp -R "$MOUNT_DIR/Agile Agent.app" "$APP_DEST"
        fi

        xattr -rd com.apple.quarantine "$APP_DEST" 2>>"$LOG" || true
        hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true

        log "Starting updated Agile Agent menu bar app..."
        open "$APP_DEST"
    else
        log "WARNING: Could not mount DMG or find app bundle inside."
    fi
fi

log "Restart complete. Update done."
echo "✅ Update complete!"

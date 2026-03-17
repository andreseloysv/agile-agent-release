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

log() { echo "[$(date '+%H:%M:%S')] $1" >> "$LOG"; }

log "Checking for updates..."

cd "$INSTALL_DIR" || { log "Install dir not found, skipping."; exit 0; }

# Capture current commit before pulling
BEFORE=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

# Pull latest (quietly), forcing through any local changes
git fetch --quiet origin main 2>>"$LOG" || { log "Network error, skipping."; exit 0; }
git reset --hard origin/main --quiet 2>>"$LOG" || { log "Cannot reset to origin/main, skipping."; exit 0; }

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
    exit 0
fi

log "Updated $BEFORE → $AFTER. Restarting service..."

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

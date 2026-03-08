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

# Pull latest (quietly)
git fetch --quiet origin main 2>>"$LOG" || { log "Network error, skipping."; exit 0; }
git merge --ff-only origin/main --quiet 2>>"$LOG" || { log "Cannot fast-forward, skipping."; exit 0; }

AFTER=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

if [[ "$BEFORE" == "$AFTER" ]]; then
    log "Already up to date ($AFTER)."
    exit 0
fi

log "Updated $BEFORE → $AFTER. Restarting service..."

# Restart the main LaunchAgent so the new binary / frontend are loaded
launchctl unload "$PLIST_PATH" 2>>"$LOG" || true
sleep 1
launchctl load -w "$PLIST_PATH" 2>>"$LOG" || true

log "Restart complete. Update done."

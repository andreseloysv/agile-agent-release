#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# agile-agent stop — Stops the Agile Agent server (dev or production)
#
# Usage:
#   agile-agent-stop         # stop the server gracefully
#   agile-agent-stop --force # force kill
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

LABEL="com.agile-agent"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
PID_FILE="/tmp/agile-agent-dev.pid"
PORT=4373

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "▸ Stopping Agile Agent..."

stopped=false

# 1. Stop dev mode PID if tracked
if [[ -f "$PID_FILE" ]]; then
    pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        echo -e "  Stopping dev server (PID $pid)..."
        kill "$pid" 2>/dev/null || true
        # Also kill child processes (concurrently spawns children)
        pkill -P "$pid" 2>/dev/null || true
        stopped=true
    fi
    rm -f "$PID_FILE"
fi

# 2. Kill anything on port
port_pid=$(lsof -ti :${PORT} 2>/dev/null | head -1 || echo "")
if [[ -n "$port_pid" ]]; then
    echo -e "  Killing process on port ${PORT} (PID $port_pid)..."
    if [[ "${1:-}" == "--force" ]]; then
        kill -9 "$port_pid" 2>/dev/null || true
    else
        kill "$port_pid" 2>/dev/null || true
    fi
    # Kill all processes on that port (server + web dev server)
    lsof -ti :${PORT} 2>/dev/null | xargs kill 2>/dev/null || true
    stopped=true
fi

# 3. Unload LaunchAgent
if launchctl list "$LABEL" &>/dev/null; then
    echo -e "  Unloading LaunchAgent..."
    launchctl unload "$PLIST" 2>/dev/null || true
    stopped=true
fi

sleep 1

if $stopped; then
    echo -e "${GREEN}✔${NC} Agile Agent stopped."
else
    echo -e "${YELLOW}●${NC} Agile Agent was already stopped."
fi

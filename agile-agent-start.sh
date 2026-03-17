#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# agile-agent start — Starts the Agile Agent server (dev or production)
#
# Usage:
#   agile-agent-start            # start the server
#   agile-agent-start --status   # show if server is running
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Pre-flight: Xcode Command Line Tools ─────────────────────────────────
# The agile-agent binary requires git (part of Xcode CLT) at runtime.
# Without it, the binary crashes immediately with cryptic "command not found" errors.
if ! command -v git &>/dev/null; then
    echo -e "\033[0;31m✗\033[0m Xcode Command Line Tools are not installed."
    echo -e "  Agile Agent requires \033[1mgit\033[0m which is included in the CLT."
    echo ""
    echo -e "  Installing now (a system dialog will appear)..."
    xcode-select --install 2>/dev/null || true
    echo ""
    echo -e "  \033[1;33m⚠\033[0m After the installation completes, re-run this script:"
    echo -e "    \033[2m$0\033[0m"
    exit 1
fi

# Also verify git actually works (catches partial Xcode installs where the
# binary exists but the xctoolchain is broken/missing)
if ! git --version &>/dev/null; then
    echo -e "\033[0;31m✗\033[0m git is installed but appears broken (missing Xcode toolchain)."
    echo -e "  Try running:"
    echo -e "    \033[2msudo xcode-select --reset\033[0m"
    echo -e "    \033[2mxcode-select --install\033[0m"
    echo ""
    echo -e "  \033[1;33m⚠\033[0m After the installation completes, re-run this script."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LABEL="com.agile-agent"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
PID_FILE="/tmp/agile-agent-dev.pid"
PORT=4373

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Detect mode: dev (repo with package.json) vs production (LaunchAgent)
is_dev() {
    [[ -f "$REPO_ROOT/package.json" ]] && grep -q '"agile-agent"' "$REPO_ROOT/package.json" 2>/dev/null
}

status() {
    # Check dev mode PID
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            echo -e "${GREEN}●${NC} Agile Agent is ${GREEN}running${NC} (dev mode, PID $pid)"
            echo -e "  URL: http://localhost:${PORT}"
            return 0
        else
            rm -f "$PID_FILE"
        fi
    fi
    # Check if port is in use (dev via npm run dev)
    local port_pid
    port_pid=$(lsof -ti :${PORT} 2>/dev/null | head -1 || echo "")
    if [[ -n "$port_pid" ]]; then
        echo -e "${GREEN}●${NC} Agile Agent is ${GREEN}running${NC} (PID $port_pid on port ${PORT})"
        echo -e "  URL: http://localhost:${PORT}"
        return 0
    fi
    # Check LaunchAgent
    if launchctl list "$LABEL" &>/dev/null; then
        local la_pid
        la_pid=$(launchctl list "$LABEL" 2>/dev/null | grep -oE '^\d+' || echo "")
        if [[ -n "$la_pid" && "$la_pid" != "-" ]]; then
            echo -e "${GREEN}●${NC} Agile Agent is ${GREEN}running${NC} (production, PID $la_pid)"
            echo -e "  Logs: /tmp/agile-agent.log"
            return 0
        fi
    fi
    echo -e "${RED}●${NC} Agile Agent is ${RED}stopped${NC}"
    return 1
}

if [[ "${1:-}" == "--status" ]]; then
    status
    exit 0
fi

# Check if already running
if status 2>/dev/null; then
    echo -e "${YELLOW}Already running.${NC} Use agile-agent-stop to stop first."
    exit 0
fi

echo -e "▸ Starting Agile Agent..."

if is_dev; then
    echo -e "  Mode: ${GREEN}development${NC}"
    cd "$REPO_ROOT"
    # Start dev server in background
    nohup npm run dev > /tmp/agile-agent-dev.log 2>&1 &
    DEV_PID=$!
    echo "$DEV_PID" > "$PID_FILE"
    # Wait for server to come up
    for i in {1..10}; do
        if curl -sf "http://localhost:${PORT}" >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done
else
    echo -e "  Mode: production"
    if [[ ! -f "$PLIST" ]]; then
        echo -e "${RED}✗${NC} LaunchAgent plist not found at: $PLIST"
        echo "  Run the installer first or check your installation."
        exit 1
    fi
    launchctl load "$PLIST" 2>/dev/null || true
    launchctl start "$LABEL" 2>/dev/null || true
    sleep 1
fi

if status; then
    echo -e "\n${GREEN}✔${NC} Agile Agent started successfully!"
    # Launch the menu bar app if installed
    for app in "/Applications/Agile Agent.app" "$HOME/Applications/Agile Agent.app"; do
        if [[ -d "$app" ]]; then
            open "$app" 2>/dev/null || true
            echo -e "  Menu bar app launched"
            break
        fi
    done
else
    echo -e "\n${RED}✗${NC} Failed to start. Check logs:"
    if is_dev; then
        echo "  tail -f /tmp/agile-agent-dev.log"
    else
        echo "  tail -f /tmp/agile-agent.err"
    fi
    exit 1
fi

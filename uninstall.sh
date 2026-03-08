#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Agile Agent — Uninstaller for macOS
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

INSTALL_DIR="${AGILE_AGENT_HOME:-$HOME/.agile-agent}"
PLIST_NAME="com.agile-agent"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"
UPDATER_PLIST_PATH="$HOME/Library/LaunchAgents/com.agile-agent.updater.plist"

info()    { echo -e "\033[0;34m▸\033[0m $1"; }
success() { echo -e "${GREEN}✔${RESET} $1"; }

echo -e "
${RED}${BOLD}  ╭─────────────────────────────────────╮${RESET}
${RED}${BOLD}  │     🗑️  Agile Agent Uninstaller      │${RESET}
${RED}${BOLD}  ╰─────────────────────────────────────╯${RESET}
"

# Stop and remove the main LaunchAgent
if [[ -f "$PLIST_PATH" ]]; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm -f "$PLIST_PATH"
    success "LaunchAgent service stopped and removed"
else
    info "No LaunchAgent service found (already removed)"
fi

# Stop and remove the auto-updater LaunchAgent
if [[ -f "$UPDATER_PLIST_PATH" ]]; then
    launchctl unload "$UPDATER_PLIST_PATH" 2>/dev/null || true
    rm -f "$UPDATER_PLIST_PATH"
    success "Auto-updater stopped and removed"
fi

# Remove installation directory
if [[ -d "$INSTALL_DIR" ]]; then
    echo -e ""
    read -p "$(echo -e "${YELLOW}Remove ${INSTALL_DIR} and all data (including databases)? [y/N] ${RESET}")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        success "Removed ${INSTALL_DIR}"
    else
        info "Kept ${INSTALL_DIR} — you can remove it manually later"
    fi
else
    info "No installation found at ${INSTALL_DIR}"
fi

echo -e "
${GREEN}${BOLD}  Agile Agent has been uninstalled.${RESET}
  ${CYAN}Thanks for trying it out! 👋${RESET}
"

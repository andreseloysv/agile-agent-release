#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Agile Agent — Uninstaller for macOS
#
#   ~/.agile-agent/uninstall.sh                # remove the app, keep your data
#   ~/.agile-agent/uninstall.sh --remove-data  # remove everything
#
# Removes the background service and the hourly updater, the menu bar app, the
# VS Code extension, the program files and the logs. Your data
# (~/.agile-agent/data: projects, conversations, settings) is kept unless you
# pass --remove-data. Works the same when piped through curl | bash (no prompts).
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

INSTALL_DIR="${AGILE_AGENT_HOME:-$HOME/.agile-agent}"
INSTALL_DIR="${INSTALL_DIR%/}"
case "$INSTALL_DIR" in
    ""|"/"|"$HOME"|"${HOME%/}") echo "Refusing to uninstall from '$INSTALL_DIR'"; exit 1 ;;
esac
REMOVE_DATA=false
for arg in "$@"; do
    case "$arg" in
        --remove-data) REMOVE_DATA=true ;;
    esac
done

info()    { echo -e "\033[0;34m▸\033[0m $1"; }
success() { echo -e "${GREEN}✔${RESET} $1"; }

find_vscode_cli() {
    local app c
    if command -v code >/dev/null 2>&1; then command -v code; return 0; fi
    local apps=()
    if command -v mdfind >/dev/null 2>&1; then
        while IFS= read -r app; do
            [[ "$app" == *.app ]] && apps+=("$app")
        done < <(mdfind "kMDItemCFBundleIdentifier == 'com.microsoft.VSCode*'" 2>/dev/null || true)
    fi
    apps+=("/Applications/Visual Studio Code.app" "$HOME/Applications/Visual Studio Code.app")
    for app in "${apps[@]}"; do
        for c in "$app/Contents/Resources/app/bin/code" "$app/Contents/Resources/app/bin/code-insiders"; do
            if [[ -x "$c" ]]; then echo "$c"; return 0; fi
        done
    done
    return 1
}

echo -e "
${RED}${BOLD}  ╭─────────────────────────────────────╮${RESET}
${RED}${BOLD}  │     🗑️  Agile Agent Uninstaller      │${RESET}
${RED}${BOLD}  ╰─────────────────────────────────────╯${RESET}
"

# 1. Background service and hourly updater
for label in com.agile-agent com.agile-agent.updater; do
    plist="$HOME/Library/LaunchAgents/${label}.plist"
    if [[ -f "$plist" ]]; then
        launchctl unload "$plist" 2>/dev/null || true
        rm -f "$plist"
        success "Removed LaunchAgent ${label}"
    fi
done

# 2. Menu bar app (only our bundle, identified by its bundle id)
pkill -f "Agile Agent.app/Contents/MacOS/" 2>/dev/null || true
for app in "/Applications/Agile Agent.app" "$HOME/Applications/Agile Agent.app"; do
    if [[ -d "$app" ]] && [[ "$(defaults read "$app/Contents/Info" CFBundleIdentifier 2>/dev/null)" == "com.agile-agent.app" ]]; then
        rm -rf "$app" && success "Removed $app"
    fi
done

# 3. VS Code extension
if CODE_CMD="$(find_vscode_cli)"; then
    env -u ELECTRON_RUN_AS_NODE "$CODE_CMD" --uninstall-extension agile-agent.agile-agent-copilot-bridge >/dev/null 2>&1 \
        && success "Removed the VS Code extension" || true
fi

# 4. Logs
rm -f /tmp/agile-agent.log /tmp/agile-agent.err /tmp/agile-agent-update.log 2>/dev/null || true

# 5. Program files (keep data unless --remove-data)
if [[ -d "$INSTALL_DIR" ]]; then
    if [[ "$REMOVE_DATA" == "true" ]]; then
        rm -rf "$INSTALL_DIR"
        success "Removed ${INSTALL_DIR} including your data"
    else
        find "$INSTALL_DIR" -mindepth 1 -maxdepth 1 ! -name data -exec rm -rf {} + 2>/dev/null || true
        rm -f "$INSTALL_DIR/data/server.pid" "$INSTALL_DIR/data/server.port"  # runtime-only files
        success "Removed the program files. Your data was kept in ${INSTALL_DIR}/data"
        info "To delete it too: rm -rf \"${INSTALL_DIR}\"  (or run this uninstaller with --remove-data)"
    fi
else
    info "No installation found at ${INSTALL_DIR}"
fi

echo -e "
${GREEN}${BOLD}  Agile Agent has been uninstalled.${RESET}
  ${CYAN}Thanks for trying it out! 👋${RESET}
"

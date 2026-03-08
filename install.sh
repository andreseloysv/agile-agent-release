#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Agile Agent — One-line installer for macOS
#
#   curl -fsSL https://raw.githubusercontent.com/andreseloysv/agile-agent-release/main/install.sh | bash
#
# Flags:
#   --uninstall   Remove Agile Agent and its LaunchAgent service
#   --update      Pull latest version and restart
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Colors & helpers ─────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

INSTALL_DIR="${AGILE_AGENT_HOME:-$HOME/.agile-agent}"
REPO_URL="https://github.com/andreseloysv/agile-agent-release.git"
PLIST_NAME="com.agile-agent"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"
PORT=4372

info()    { echo -e "${BLUE}▸${RESET} $1"; }
success() { echo -e "${GREEN}✔${RESET} $1"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $1"; }
error()   { echo -e "${RED}✖${RESET} $1" >&2; }
step()    { echo -e "\n${CYAN}${BOLD}── $1 ──${RESET}"; }

# ── Pre-flight checks ───────────────────────────────────────────────────────
if [[ "$(uname -s)" != "Darwin" ]]; then
    error "This installer only supports macOS."
    exit 1
fi

# ── Uninstall mode ───────────────────────────────────────────────────────────
if [[ "${1:-}" == "--uninstall" ]]; then
    step "Uninstalling Agile Agent"

    if [[ -f "$PLIST_PATH" ]]; then
        launchctl unload "$PLIST_PATH" 2>/dev/null || true
        rm -f "$PLIST_PATH"
        success "LaunchAgent service removed"
    else
        info "No LaunchAgent service found"
    fi

    if [[ -d "$INSTALL_DIR" ]]; then
        read -p "$(echo -e "${YELLOW}Remove $INSTALL_DIR and all data? [y/N] ${RESET}")" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_DIR"
            success "Removed $INSTALL_DIR"
        else
            info "Kept $INSTALL_DIR"
        fi
    fi

    echo -e "\n${GREEN}${BOLD}🗑️  Agile Agent has been uninstalled.${RESET}\n"
    exit 0
fi

# ── Banner ───────────────────────────────────────────────────────────────────
echo -e "
${CYAN}${BOLD}  ╭─────────────────────────────────────╮${RESET}
${CYAN}${BOLD}  │       🤖 Agile Agent Installer       │${RESET}
${CYAN}${BOLD}  ╰─────────────────────────────────────╯${RESET}
"

# ── Step 1: Ensure Git ───────────────────────────────────────────────────────
step "Checking prerequisites"

if ! command -v git &>/dev/null; then
    info "Installing Xcode Command Line Tools (for git)..."
    xcode-select --install 2>/dev/null || true
    echo -e "${YELLOW}Please complete the Xcode CLT installation, then re-run this script.${RESET}"
    exit 1
fi
success "git is available"

# Ensure git-lfs is available (binary is tracked with LFS)
if ! command -v git-lfs &>/dev/null; then
    if command -v brew &>/dev/null; then
        info "Installing Git LFS..."
        brew install git-lfs
        git lfs install
    else
        warn "Git LFS not found. Installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        brew install git-lfs
        git lfs install
    fi
fi
success "git-lfs is available"

# ── Step 2: Download or update release ────────────────────────────────────────
step "Downloading Agile Agent"

if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Updating existing installation..."
    cd "$INSTALL_DIR"
    git pull --ff-only origin main 2>/dev/null || git pull origin main
    success "Updated to latest version"
else
    info "Downloading to $INSTALL_DIR..."
    git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
    success "Downloaded successfully"
fi

cd "$INSTALL_DIR"

# ── Step 3: Make binary executable ────────────────────────────────────────────
step "Setting up binary"

if [[ ! -f "$INSTALL_DIR/agile-agent" ]]; then
    error "Binary not found in release. The release may be corrupted."
    exit 1
fi

chmod +x "$INSTALL_DIR/agile-agent"
success "Binary ready ($(du -sh "$INSTALL_DIR/agile-agent" | cut -f1))"

# ── Step 4: Create data directory ─────────────────────────────────────────────
mkdir -p "$INSTALL_DIR/data"

# ── Step 5: Set up the LaunchAgent service ────────────────────────────────────
step "Setting up background service"

# Stop existing service if running
if [[ -f "$PLIST_PATH" ]]; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    info "Stopped existing service"
fi

# Create LaunchAgent plist
mkdir -p "$(dirname "$PLIST_PATH")"
cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>${PLIST_NAME}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${INSTALL_DIR}/agile-agent</string>
  </array>
  <key>WorkingDirectory</key><string>${INSTALL_DIR}</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>AGILE_AGENT_HOME</key><string>${INSTALL_DIR}</string>
    <key>AGILE_AGENT_STATIC</key><string>${INSTALL_DIR}/public</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>/tmp/agile-agent.log</string>
  <key>StandardErrorPath</key><string>/tmp/agile-agent.err</string>
</dict>
</plist>
EOF

launchctl load -w "$PLIST_PATH"
success "LaunchAgent service installed and started"

# ── Step 5b: Set up hourly auto-updater ──────────────────────────────────────
step "Setting up auto-updater (checks on start + every hour)"

UPDATER_PLIST_NAME="com.agile-agent.updater"
UPDATER_PLIST_PATH="$HOME/Library/LaunchAgents/${UPDATER_PLIST_NAME}.plist"

# Copy update.sh into the install dir
if [[ -f "$INSTALL_DIR/update.sh" ]]; then
    chmod +x "$INSTALL_DIR/update.sh"
fi

# Stop existing updater if running
if [[ -f "$UPDATER_PLIST_PATH" ]]; then
    launchctl unload "$UPDATER_PLIST_PATH" 2>/dev/null || true
fi

cat > "$UPDATER_PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>${UPDATER_PLIST_NAME}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${INSTALL_DIR}/update.sh</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>AGILE_AGENT_HOME</key><string>${INSTALL_DIR}</string>
    <key>HOME</key><string>${HOME}</string>
    <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>3600</integer>
  <key>StandardOutPath</key><string>/tmp/agile-agent-update.log</string>
  <key>StandardErrorPath</key><string>/tmp/agile-agent-update.log</string>
</dict>
</plist>
EOF

launchctl load -w "$UPDATER_PLIST_PATH"
success "Auto-updater installed (runs at login + every hour)"

# ── Step 6: Wait for server to be ready ───────────────────────────────────────
step "Starting Agile Agent"

info "Waiting for server to be ready..."
for i in {1..30}; do
    if curl -sf "http://localhost:${PORT}" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

if curl -sf "http://localhost:${PORT}" >/dev/null 2>&1; then
    success "Server is running on http://localhost:${PORT}"
else
    warn "Server is starting up — it may take a few more seconds"
    info "Check logs: ${DIM}cat /tmp/agile-agent.log${RESET}"
fi

# ── Step 7: Install VS Code Copilot Bridge extension ─────────────────────────
step "VS Code Copilot Bridge Extension"

VSIX_PATH="$INSTALL_DIR/copilot-bridge.vsix"

if [[ -f "$VSIX_PATH" ]]; then
    # Auto-detect VS Code CLI if not in PATH
    if ! command -v code &>/dev/null; then
        # Check common macOS VS Code locations
        VSCODE_PATHS=(
            "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
            "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
            "/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin/code-insiders"
        )
        for vsp in "${VSCODE_PATHS[@]}"; do
            if [[ -f "$vsp" ]]; then
                info "Found VS Code at: $(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$vsp")")")")")"
                # Create symlink in /usr/local/bin
                if [[ -d "/usr/local/bin" ]]; then
                    ln -sf "$vsp" /usr/local/bin/code 2>/dev/null && \
                        success "Linked 'code' CLI to /usr/local/bin/code" || \
                        info "Could not create symlink (try: sudo ln -sf \"$vsp\" /usr/local/bin/code)"
                fi
                export PATH="$(dirname "$vsp"):$PATH"
                break
            fi
        done
    fi

    if command -v code &>/dev/null; then
        info "Installing VS Code extension..."
        code --install-extension "$VSIX_PATH" --force 2>/dev/null && \
            success "Copilot Bridge extension installed in VS Code" || \
            warn "Failed to auto-install extension. Install manually: code --install-extension $VSIX_PATH"
    else
        warn "VS Code not found on this machine."
        echo -e "  ${DIM}To use the Copilot Bridge:${RESET}"
        echo -e "  ${DIM}1. Install VS Code: ${CYAN}https://code.visualstudio.com${RESET}"
        echo -e "  ${DIM}2. Then run:${RESET} ${CYAN}code --install-extension $VSIX_PATH${RESET}"
    fi
else
    info "No VS Code extension found in release — skipping"
fi

# ── Done! ─────────────────────────────────────────────────────────────────────
echo -e "
${GREEN}${BOLD}  ╭─────────────────────────────────────────────────────────╮${RESET}
${GREEN}${BOLD}  │              🎉 Agile Agent is ready!                   │${RESET}
${GREEN}${BOLD}  │                                                         │${RESET}
${GREEN}${BOLD}  │  Open:   ${RESET}${CYAN}http://localhost:${PORT}${GREEN}${BOLD}                       │${RESET}
${GREEN}${BOLD}  │                                                         │${RESET}
${GREEN}${BOLD}  │  No Node.js needed — runs as a native binary.           │${RESET}
${GREEN}${BOLD}  │  Starts automatically on boot.                          │${RESET}
${GREEN}${BOLD}  │                                                         │${RESET}
${GREEN}${BOLD}  │  Commands:                                              │${RESET}
${GREEN}${BOLD}  │    Update:     ${RESET}${DIM}cd ~/.agile-agent && git pull${GREEN}${BOLD}             │${RESET}
${GREEN}${BOLD}  │    Logs:       ${RESET}${DIM}cat /tmp/agile-agent.log${GREEN}${BOLD}                │${RESET}
${GREEN}${BOLD}  │    Uninstall:  ${RESET}${DIM}~/.agile-agent/uninstall.sh${GREEN}${BOLD}             │${RESET}
${GREEN}${BOLD}  ╰─────────────────────────────────────────────────────────╯${RESET}
"

# Open browser
if [[ "${CI:-}" != "true" ]]; then
    open "http://localhost:${PORT}" 2>/dev/null || true
fi

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

# Verify git actually works (catches broken/partial Xcode installations where
# the binary exists but xctoolchain is missing — error: "can't open file: ...")
if ! git --version &>/dev/null; then
    error "git is installed but appears broken (missing Xcode toolchain)."
    info "This usually means Xcode Command Line Tools need to be (re)installed."
    echo ""
    info "Try running:"
    echo -e "  ${CYAN}sudo xcode-select --reset${RESET}"
    echo -e "  ${CYAN}xcode-select --install${RESET}"
    echo ""
    echo -e "${YELLOW}After the installation completes, re-run this script.${RESET}"
    exit 1
fi
success "git is available"

# Ensure git-lfs is available (binary is tracked with LFS)
# Download ensure-deps.sh if not available locally (first install)
DEPS_SCRIPT="$INSTALL_DIR/scripts/ensure-deps.sh"
if [[ ! -f "$DEPS_SCRIPT" ]]; then
    DEPS_SCRIPT="$(mktemp /tmp/ensure-deps-XXXXXX)"
    curl -fsSL "https://raw.githubusercontent.com/andreseloysv/agile-agent-release/main/scripts/ensure-deps.sh" \
        -o "$DEPS_SCRIPT" 2>/dev/null || true
fi
if [[ -f "$DEPS_SCRIPT" ]]; then
    source "$DEPS_SCRIPT"
    ensure_git_lfs || true
fi
success "Prerequisites checked"

# ── Step 2: Download or update release ────────────────────────────────────────
step "Downloading Agile Agent"

if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Updating existing installation..."
    cd "$INSTALL_DIR"
    git fetch origin main 2>/dev/null || true
    git reset --hard origin/main 2>/dev/null || true
    # ⚠️ DO NOT use `git clean` here — it deletes untracked user data!
    # Protected paths (NEVER delete):
    #   data/               — SQLite DB, memories, all user data
    #   .env                — user environment config
    #   *.db, *.db-wal, *.db-shm — SQLite files that may be at root
    # Only remove specific known obsolete files:
    rm -f "$INSTALL_DIR/agile-agent" 2>/dev/null || true  # old single-binary symlink, re-created below
    # Pull LFS objects (binaries are stored in Git LFS)
    git lfs pull 2>/dev/null || true
    success "Updated to latest version"
else
    info "Downloading to $INSTALL_DIR..."
    git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    # Pull LFS objects (binaries are stored in Git LFS)
    git lfs pull 2>/dev/null || true
    success "Downloaded successfully"
fi

cd "$INSTALL_DIR"

# ── Step 3: Select and set up architecture-specific binary ────────────────
step "Setting up binary"

ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    BINARY_NAME="agile-agent-arm64"
elif [[ "$ARCH" == "x86_64" ]]; then
    BINARY_NAME="agile-agent-x86_64"
else
    error "Unsupported architecture: $ARCH"
    exit 1
fi

if [[ ! -f "$INSTALL_DIR/$BINARY_NAME" ]]; then
    # Fallback: check for the old single-binary name (pre-universal builds)
    if [[ -f "$INSTALL_DIR/agile-agent" ]]; then
        BINARY_NAME="agile-agent"
        warn "Using legacy single-architecture binary. Consider re-installing for best performance."
    else
        error "Binary not found for $ARCH in release. The release may be corrupted."
        exit 1
    fi
fi

# Safety check: ensure the binary is real (not a Git LFS pointer)
if head -1 "$INSTALL_DIR/$BINARY_NAME" 2>/dev/null | grep -q "^version https://git-lfs"; then
    error "Binary is a Git LFS pointer, not the actual file!"
    info "This means git-lfs failed to download the binary."
    info "Fix: install git-lfs, then re-pull:"
    echo ""
    echo -e "  ${CYAN}brew install git-lfs${RESET}"
    echo -e "  ${CYAN}cd $INSTALL_DIR && git lfs install && git lfs pull${RESET}"
    echo ""
    exit 1
fi

chmod +x "$INSTALL_DIR/$BINARY_NAME"

# Symlink to 'agile-agent' so LaunchAgent and scripts always find it
ln -sf "$INSTALL_DIR/$BINARY_NAME" "$INSTALL_DIR/agile-agent"
success "Binary ready for $ARCH ($(du -sh "$INSTALL_DIR/$BINARY_NAME" | cut -f1))"

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
  <key>RunAtLoad</key><false/>
  <key>KeepAlive</key><false/>
  <key>StandardOutPath</key><string>/tmp/agile-agent.log</string>
  <key>StandardErrorPath</key><string>/tmp/agile-agent.err</string>
</dict>
</plist>
EOF

launchctl load -w "$PLIST_PATH"
launchctl start "$PLIST_NAME"
success "LaunchAgent service installed and started"

# Copy start/stop scripts
for script in agile-agent-start.sh agile-agent-stop.sh; do
    if [[ -f "$INSTALL_DIR/$script" ]]; then
        chmod +x "$INSTALL_DIR/$script"
    fi
done
success "Start/stop scripts available"

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
    success "Server is running on http://agileagent.localhost:${PORT}"
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

# ── Step 8: Install macOS Menu Bar App ────────────────────────────────────────
step "Installing macOS App"

DMG_PATH="$INSTALL_DIR/Agile Agent.dmg"
if [[ -f "$DMG_PATH" ]]; then
    info "Mounting DMG..."
    # Mount silently
    MOUNT_OUT=$(hdiutil attach "$DMG_PATH" -nobrowse -noverify -noautoopen 2>/dev/null)
    MOUNT_DIR=$(echo "$MOUNT_OUT" | grep "/Volumes/" | tail -1 | awk -F'\t' '{print $NF}')

    if [[ -n "$MOUNT_DIR" && -d "$MOUNT_DIR/Agile Agent.app" ]]; then
        info "Closing existing app and copying new version to Applications..."
        # Force quit the app if it's currently running so we can overwrite it
        pkill -f "Agile Agent.app" || true
        sleep 1

        # Copy to /Applications, fallback to ~/Applications if permission denied
        APP_DEST="/Applications/Agile Agent.app"
        rm -rf "$APP_DEST" 2>/dev/null || true
        
        if ! cp -R "$MOUNT_DIR/Agile Agent.app" "$APP_DEST" 2>/dev/null; then
            mkdir -p "$HOME/Applications"
            APP_DEST="$HOME/Applications/Agile Agent.app"
            rm -rf "$APP_DEST" 2>/dev/null || true
            cp -R "$MOUNT_DIR/Agile Agent.app" "$APP_DEST"
        fi

        # Remove quarantine so it opens without the Gatekeeper prompt
        xattr -rd com.apple.quarantine "$APP_DEST" 2>/dev/null || true

        # Unmount
        hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true

        # Launch the app so the menu bar icon appears
        info "Starting Agile Agent menu bar app..."
        open "$APP_DEST"
        success "macOS app installed and launched"
        APP_LAUNCHED="true"
    else
        warn "Could not mount DMG or find app bundle inside."
    fi
else
    info "No Agile Agent.dmg found in release — skipping"
fi

# ── Done! ─────────────────────────────────────────────────────────────────────
echo -e "
${GREEN}${BOLD}  ╭─────────────────────────────────────────────────────────╮${RESET}
${GREEN}${BOLD}  │              🎉 Agile Agent is ready!                   │${RESET}
${GREEN}${BOLD}  │                                                         │${RESET}
${GREEN}${BOLD}  │  Open:   ${RESET}${CYAN}http://agileagent.localhost:${PORT}${GREEN}${BOLD}               │${RESET}
${GREEN}${BOLD}  │                                                         │${RESET}
${GREEN}${BOLD}  │  No Node.js needed — runs as a native binary.           │${RESET}
${GREEN}${BOLD}  │  Does NOT start automatically on boot.                  │${RESET}
${GREEN}${BOLD}  │                                                         │${RESET}
${GREEN}${BOLD}  │  Commands:                                              │${RESET}
${GREEN}${BOLD}  │    Start:      ${RESET}${DIM}~/.agile-agent/agile-agent-start.sh${GREEN}${BOLD}     │${RESET}
${GREEN}${BOLD}  │    Stop:       ${RESET}${DIM}~/.agile-agent/agile-agent-stop.sh${GREEN}${BOLD}      │${RESET}
${GREEN}${BOLD}  │    Update:     ${RESET}${DIM}cd ~/.agile-agent && git pull${GREEN}${BOLD}             │${RESET}
${GREEN}${BOLD}  │    Logs:       ${RESET}${DIM}cat /tmp/agile-agent.log${GREEN}${BOLD}                │${RESET}
${GREEN}${BOLD}  │    Uninstall:  ${RESET}${DIM}~/.agile-agent/uninstall.sh${GREEN}${BOLD}             │${RESET}
${GREEN}${BOLD}  ╰─────────────────────────────────────────────────────────╯${RESET}
"

# Open browser if not already launched by the mac app
if [[ "${CI:-}" != "true" && "${APP_LAUNCHED:-false}" != "true" ]]; then
    open "http://agileagent.localhost:${PORT}" 2>/dev/null || true
fi

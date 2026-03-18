#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Agile Agent — Shared dependency installer
#
# Ensures git-lfs and ripgrep are available. Used by both:
#   - install.sh (runs as user)
#   - pkg-scripts/postinstall (runs as root → delegates via RUN_CMD)
#
# Required env vars (must be set before sourcing):
#   INSTALL_DIR   — e.g. ~/.agile-agent
#
# Optional env vars:
#   RUN_CMD       — prefix for user-context commands (e.g. "sudo -u alice --")
#                   Defaults to empty (run directly as current user)
# ─────────────────────────────────────────────────────────────────────────────

GIT_LFS_VERSION="3.6.1"

# ── Detect Homebrew ──────────────────────────────────────────────────────────

_detect_brew() {
    for bp in "/opt/homebrew/bin/brew" "/usr/local/bin/brew"; do
        if [[ -x "$bp" ]]; then
            echo "$bp"
            return
        fi
    done
}

BREW_CMD="$(_detect_brew)"

# ── Ensure git-lfs ───────────────────────────────────────────────────────────

ensure_git_lfs() {
    if command -v git-lfs &>/dev/null; then
        return 0
    fi
    # Also check our own bin dir (from a previous install)
    if [[ -x "$INSTALL_DIR/bin/git-lfs" ]]; then
        export PATH="$INSTALL_DIR/bin:$PATH"
        return 0
    fi

    echo "[deps] git-lfs not found. Installing..."

    # Try 1: Homebrew
    if [[ -n "$BREW_CMD" ]]; then
        echo "[deps] Installing via Homebrew..."
        if ${RUN_CMD:-} "$BREW_CMD" install git-lfs < /dev/null 2>/dev/null; then
            # Rehash PATH so the freshly-installed binary is found immediately
            eval "$(${BREW_CMD} shellenv 2>/dev/null)" 2>/dev/null || true
            hash -r 2>/dev/null || true
            ${RUN_CMD:-} git lfs install < /dev/null 2>/dev/null || true
            if command -v git-lfs &>/dev/null; then
                return 0
            fi
        fi
    fi

    # Try 2: Direct binary download (no admin/sudo needed)
    echo "[deps] Homebrew not found. Downloading git-lfs binary directly..."
    local ARCH="$(uname -m)"
    local GIT_LFS_ARCH="amd64"
    [[ "$ARCH" == "arm64" ]] && GIT_LFS_ARCH="arm64"

    local GIT_LFS_URL="https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VERSION}/git-lfs-darwin-${GIT_LFS_ARCH}-v${GIT_LFS_VERSION}.tar.gz"
    local GIT_LFS_BIN_DIR="$INSTALL_DIR/bin"
    mkdir -p "$GIT_LFS_BIN_DIR"

    local TMPFILE="$(mktemp /tmp/git-lfs-XXXXXX)"
    if curl -fsSL "$GIT_LFS_URL" -o "$TMPFILE" 2>/dev/null; then
        tar xzf "$TMPFILE" -C "$GIT_LFS_BIN_DIR" --strip-components=1 \
            "git-lfs-${GIT_LFS_VERSION}/git-lfs" 2>/dev/null
        rm -f "$TMPFILE"
        chmod +x "$GIT_LFS_BIN_DIR/git-lfs"
        export PATH="$GIT_LFS_BIN_DIR:$PATH"
        ${RUN_CMD:-} "$GIT_LFS_BIN_DIR/git-lfs" install < /dev/null
        echo "[deps] ✔ git-lfs installed to $GIT_LFS_BIN_DIR/git-lfs"
        return 0
    fi

    rm -f "$TMPFILE"
    echo "[deps] ⚠ Could not install git-lfs. Continuing without it..." >&2
    return 1
}

# ── Ensure ripgrep ───────────────────────────────────────────────────────────

ensure_ripgrep() {
    if command -v rg &>/dev/null; then
        return 0
    fi

    echo "[deps] ripgrep not found."

    if [[ -n "$BREW_CMD" ]]; then
        echo "[deps] Installing via Homebrew..."
        ${RUN_CMD:-} "$BREW_CMD" install ripgrep < /dev/null 2>/dev/null && \
            echo "[deps] ✔ ripgrep installed" && return 0
    fi

    echo "[deps] ⚠ Skipping ripgrep. Code searches will use grep (slower)." >&2
    return 1
}

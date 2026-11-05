# 🤖 Agile Agent

AI-powered code review agent with multi-project support, long-term memory, and web UI.

## Install (macOS)

**Option A — Clickable installer** (no Terminal needed):

Download **[Agile Agent.dmg](https://github.com/andreseloysv/agile-agent-release/releases/latest/download/Agile.Agent.dmg)**, open it, and drag the app to Applications.
> First time: right-click → Open to bypass Gatekeeper.

**Option B — One-line terminal command:**

```bash
curl -fsSL https://raw.githubusercontent.com/andreseloysv/agile-agent-release/main/install.sh | bash
```

## Install (Windows 10/11)

Open PowerShell and run:
```powershell
irm https://raw.githubusercontent.com/andreseloysv/agile-agent-release/main/install.ps1 | iex
```
No Git, Bun or admin rights needed. It installs to `%USERPROFILE%\.agile-agent`, builds the tray
launcher, installs the VS Code extension, adds a Startup shortcut and opens Agile Agent.

## Update

Updates install automatically on macOS (hourly). On Windows use the tray menu
**Check for Updates**, or run the install command again.

## Uninstall

```bash
# macOS
~/.agile-agent/uninstall.sh
```
```powershell
# Windows (keeps your data; add -RemoveData to delete it too)
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.agile-agent\uninstall.ps1"
```

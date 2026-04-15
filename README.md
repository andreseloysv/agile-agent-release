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

## Install (Windows)

**Option A — Clickable installer (Recommended):**

Download **[Agile Agent.exe](./Agile%20Agent.exe)**, open it, and follow the prompt.
It will automatically install to `~/.agile-agent`, add a startup shortcut, and launch the system tray app.

**Option B — Terminal:**

Open PowerShell and run:
```powershell
irm https://raw.githubusercontent.com/andreseloysv/agile-agent-release/main/install.ps1 | iex
```

## Update

```bash
# macOS
cd ~/.agile-agent && git pull

# Windows
cd ~\.agile-agent && git pull
```

## Uninstall

```bash
# macOS
~/.agile-agent/uninstall.sh
```

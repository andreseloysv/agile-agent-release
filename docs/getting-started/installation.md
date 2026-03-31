# Installation

Get Agile Agent running on your machine in under 60 seconds.

## One-Line Install (macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/andreseloysv/agile-agent-release/main/install.sh | bash
```

**No Node.js required** — Agile Agent ships as a compiled binary.

This will automatically:
- Download the binary to `~/.agile-agent`
- Register as a **background service** (starts on boot via `launchd`)
- Open **http://localhost:4372** in your browser

## Developer Install (from source)

If you want to contribute or customize:

```bash
# 1. Install Bun (Agile Agent's runtime)
curl -fsSL https://bun.sh/install | bash

# 2. Clone the repo
git clone https://github.com/andreseloysv/agile-agent.git
cd agile-agent

# 3. Install dependencies
bun install

# 4. Start in development mode (hot reload)
bun run dev
```

The server starts on **http://localhost:4373** (dev) or **http://localhost:4372** (production).

## System Requirements

| Requirement | Minimum |
|-------------|---------|
| **OS** | macOS 12+ (Monterey or later) |
| **RAM** | 2 GB free |
| **Disk** | 500 MB |
| **Network** | Internet access (for LLM and integration API calls) |
| **VS Code** | VS Code with Copilot extension (provides the AI bridge) |

## Update

```bash
cd ~/.agile-agent && git pull
```

## Uninstall

```bash
~/.agile-agent/uninstall.sh
```

This removes the binary, stops the background service, and cleans up launch agents.

## What's Next?

Once installed, head to [First Run](/docs/getting-started/first-run) to set up your first project.

# Architecture

Agile Agent consists of a **TypeScript backend** and a **Vue 3 frontend**, shipped as a single compiled binary.

## High-Level Overview

```mermaid
graph TB
    subgraph Frontend["Web Application"]
        UI[Web UI]
        WSC[Real-time Client]
    end

    subgraph Backend["Platform Backend"]
        API[REST API]
        WSS[Real-time Server]
        AR[Agent Engine]
        MCP[MCP Gateway]
        CS[Scheduler]
        SA[Multi-Agent]
    end

    subgraph Channels["External Channels"]
        CLI[Claude CLI / Cursor]
    end

    subgraph Services["External Services"]
        GL[GitLab]
        GH[GitHub]
        JR[Jira]
        CF[Confluence]
        LLM["VS Code Bridge (Copilot API)"]
    end

    UI -->|HTTP| API
    WSC -->|WebSocket| WSS
    WSS --> AR
    API --> AR
    CLI -->|JSON-RPC| MCP
    MCP --> AR
    CS -->|scheduled| AR
    SA -->|recursive| AR
    AR --> LLM
    AR --> GL
    AR --> JR
    AR --> CF
```

## How Requests Reach the Agent

All channels converge on a single **Agent Engine** that orchestrates every request.

| Channel | Protocol | Description |
|---------|----------|-------------|
| **Web UI** | WebSocket | Real-time chat with streamed events |
| **REST API** | HTTP | Programmatic access and test runs with optional SSE streaming |
| **MCP Gateway** | JSON-RPC | External AI clients (Claude CLI, Cursor, etc.) |
| **Scheduler** | Internal | Automated cron-based agent runs |
| **Multi-Agent** | Internal | One agent can spawn specialist sub-agents |

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Runtime** | Bun | Compiled binary, no Node.js required |
| **Backend** | Fastify | HTTP server, REST API, WebSocket |
| **AI** | VS Code Bridge | LLM via VS Code Copilot API — enterprise-ready, provider-agnostic. Expandable to additional providers |
| **Database** | SQLite | Projects, conversations, agents, tools, cron jobs |
| **Frontend** | Vue 3 + Vite | Reactive web UI |
| **Communication** | WebSocket + SSE | Real-time event streaming |

## Data Flow

The primary interaction path:

```mermaid
sequenceDiagram
    participant U as User
    participant W as Web UI
    participant WS as Real-time Server
    participant R as Agent Engine
    participant L as LLM (VS Code Bridge)
    participant T as Tools

    U->>W: Type prompt
    W->>WS: Send request
    WS->>R: Execute agent
    R->>R: Detect intent
    R->>L: Generate task plan
    L-->>R: Task DAG
    loop For each task
        R->>L: Execute with tools
        L-->>R: Tool call request
        R->>T: Execute tool
        T-->>R: Tool result
        R-->>W: Stream event
    end
    R->>L: Synthesize final response
    L-->>R: Response text
    R-->>W: Stream response
    W-->>U: Rendered result
```

The platform also supports **human-in-the-loop** interactions:
- **Interrupt** — inject additional context while the agent is running
- **Permission approval** — approve or reject tool execution requests
- **Question answering** — respond to agent questions in real-time

# Configuration

Fine-tune Agile Agent for your team's workflow.

## Environment Variables

Manage API keys and global settings from **Settings** in the sidebar.

| Key | Required | Description |
|-----|----------|-------------|
| `VSCODE_BRIDGE_URL` | ✅ | VS Code Bridge URL (default: `http://localhost:6888`) — routes LLM calls through VS Code Copilot API |
| `GITLAB_API_KEY` | — | GitLab Personal Access Token |
| `JIRA_TOKEN` | — | Jira API bearer token |
| `JIRA_DOMAIN` | — | Jira instance URL (e.g., `https://jira.example.com/`) |
| `CONFLUENCE_BASE_URL` | — | Confluence instance URL |
| `CONFLUENCE_TOKEN` | — | Confluence API token |
| `JSM_URL` | — | Jira Service Management URL |
| `JSM_TOKEN` | — | JSM API token |

## Project Settings

Each project has its own isolated configuration. Navigate to **Projects → Configure**.

| Setting | Description | Default |
|---------|-------------|---------|
| **Project Name** | Display name in sidebar and chat | — |
| **AI Model** | LLM to use (routed via VS Code Bridge) | Provider-dependent |
| **Max Iterations** | Maximum tool-call loops per request | `60` |
| **Project Root** | Local filesystem path for file tools | — |
| **GitLab Project** | Full GitLab URL — base URL and project path are auto-parsed | — |
| **System Prompt** | Custom instructions injected into every agent conversation | — |

## System Prompt Tips

The system prompt is the most powerful configuration lever. Use it to:

```
You are a senior backend engineer at Acme Corp.
Our stack is Java 17, Spring Boot 3, PostgreSQL 15.
We follow trunk-based development with feature flags.
All code reviews must check for:
- SQL injection vulnerabilities
- Missing input validation
- Proper error handling with our ErrorResponse class
```

## Long-Term Memory

Each project maintains a **memory store** — facts that persist across conversations. Navigate to **Memories** in the project sub-nav.

Memories are automatically injected into every conversation, giving the agent persistent context about your project's conventions, team preferences, and past decisions.

## Favorites

Mark frequently-used projects and agents as **favorites** using the star icon. Favorited items appear at the top of their respective lists.

# First Run

After installation, Agile Agent opens the **Setup Wizard** to guide you through initial configuration.

## Setup Wizard

The wizard walks you through 4 steps:

### Step 1 — API Keys

Enter your integration credentials:

| Key | Required | Description |
|-----|----------|-------------|
| **VS Code Bridge** | ✅ Yes | Routes all LLM calls through VS Code Copilot API — enterprise-ready and provider-agnostic |
| **GitLab Token** | Optional | For code search, file reading, and MR reviews |
| **Jira Token** | Optional | For ticket fetching and story generation |
| **Confluence Token** | Optional | For reading design documents |

### Step 2 — Create Your First Project

A project is a workspace that groups conversations, agents, tools, and settings:

- **Project Name** — a display name (e.g., "Backend API")
- **GitLab Project URL** — full URL like `https://gitlab.com/my-group/my-project`
- **AI Model** — select the model available through your VS Code Bridge (depends on your Copilot subscription)
- **System Prompt** — custom instructions for the agent (optional)

### Step 3 — Choose Your Avatar

Pick a character from the avatar carousel. Your avatar appears next to agent responses in the chat UI. Each character has its own personality and set of expressions.

## Your First Conversation

After setup, click **New Chat** in the sidebar. Try one of these prompts:

```
Review the merge request at https://gitlab.com/my-group/my-project/-/merge_requests/42
```

```
Create user stories from epic PVG-123
```

```
What is the blast radius if we change the authentication API?
```

The agent will:
1. **Detect your intent** (code review, story creation, etc.)
2. **Generate a task plan** (DAG of subtasks)
3. **Execute tools** (GitLab, Jira, local files)
4. **Stream the response** in real-time via WebSocket

## What's Next?

Learn how to [configure your projects](/docs/getting-started/configuration) for optimal results.

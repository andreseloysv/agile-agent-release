# Jira Integration

Fetch tickets, generate stories, and write back to Jira — all from a single prompt.

## What It Does

The Jira integration powers ticket review, story generation, and sprint automation:

- **Fetch tickets** with full details (description, Acceptance Criteria, links)
- **Traverse ticket trees** (Epic → Features → Stories → Subtasks)
- **Search with JQL** for advanced queries
- **Write back** comments, transitions, story points, and field updates

> **For POs & Scrum Masters:** Ask the agent "review PVG-4523" and it fetches the ticket, all linked stories, and gives you a structured quality assessment — INVEST scoring, Definition of Ready gaps, and suggested improvements.

## Setup

1. Go to **Settings** → set:
   - `JIRA_TOKEN` — your Jira API bearer token
   - `JIRA_DOMAIN` — your Jira URL (e.g., `https://jira.example.com/`)

## Available Tools

| Tool | What It Does |
|------|-------------|
| `fetch_jira_ticket` | Get full ticket details by key |
| `fetch_jira_ticket_tree` | Traverse the complete ticket hierarchy |
| `jira_search` | Search tickets via JQL queries |
| `jira_write` | Update tickets (add comments, change status, set story points) |

## Example Prompts

```
Review ticket PVG-4523
```

```
Create user stories from epic BACKEND-891
```

```
Find all open bugs in sprint 42 assigned to the backend team
```

```
Add 5 story points to PVG-4523 and move it to "In Progress"
```

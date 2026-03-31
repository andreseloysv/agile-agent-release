# GitLab Integration

Connect Agile Agent to your GitLab repositories for code search, file reading, MR reviews, and automated comments.

## What It Does

GitLab is the primary code platform integration. Once configured, the agent can:

- **Search code** across your repositories
- **Read files** from any branch
- **Fetch MR diffs** for code review
- **Post inline comments** on Merge Requests
- **Create and update files** for automated code changes

> **For teams:** The agent reads your code directly from GitLab — no need to copy-paste. Just paste a MR link and it reviews the code, or ask it to find where a function is used across your projects.

## Setup

1. Go to **Settings** → set `GITLAB_API_KEY` to your Personal Access Token
2. In your project configuration, set **GitLab Project** to the full URL:
   ```
   https://gitlab.com/my-group/my-project
   ```
   The base URL and project path are auto-parsed.

### Required Token Scopes

| Scope | Required For |
|-------|-------------|
| `read_api` | Code search, file reading, MR diffs |
| `api` | Posting comments, creating files |

## Available Tools

| Tool | What It Does |
|------|-------------|
| `gitlab_search` | Full-text search across repository code |
| `gitlab_file` | Read a specific file from any branch |
| `gitlab_diff` | Get the diff of a Merge Request |
| `gitlab_mr` | Get MR metadata (title, reviewers, status) |
| `gitlab_comment` | Post inline or general comments on MRs |
| `gitlab_write` | Create or update files in a branch |

## URL Auto-Parsing

The agent automatically parses GitLab URLs in your prompts:

```
Review https://gitlab.com/my-group/my-project/-/merge_requests/42
```

It extracts the base URL, project path, and MR ID — no additional configuration needed.

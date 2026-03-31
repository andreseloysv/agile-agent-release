# Confluence Integration

Read design documents and architecture docs directly from Confluence during reviews and analysis.

## What It Does

The Confluence integration allows the agent to cross-reference design documents when reviewing code or analyzing architecture:

- **Fetch pages** by ID or title
- **Search spaces** for relevant documentation
- **Read design documents** to validate implementation against specifications

> **For teams:** During a code review, the agent can automatically check if the implementation matches the design document in Confluence — catching drift between spec and code.

## Setup

1. Go to **Settings** → set:
   - `CONFLUENCE_BASE_URL` — your Confluence URL (e.g., `https://confluence.example.com/`)
   - `CONFLUENCE_TOKEN` — your Confluence API token

## Example Prompts

```
Review MR !42 and check it against the authentication design doc in Confluence
```

```
Search Confluence for the API migration guide
```

# REST API Reference

Complete reference for all Agile Agent REST endpoints.

## Base URL

```
http://localhost:4372/api
```

## Authentication

No authentication required for local instances. All endpoints are accessible without tokens.

---

## Projects

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/projects` | List all projects (favorites first) |
| `POST` | `/api/projects` | Create a new project |
| `GET` | `/api/projects/:id` | Get project details |
| `PUT` | `/api/projects/:id` | Update project settings |
| `DELETE` | `/api/projects/:id` | Delete project and all its data |
| `POST` | `/api/projects/:id/favorite` | Mark project as favorite |
| `DELETE` | `/api/projects/:id/favorite` | Remove from favorites |

---

## Conversations

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/projects/:pid/conversations` | List conversations |
| `POST` | `/api/projects/:pid/conversations` | Create a conversation |
| `GET` | `/api/conversations/:id` | Get conversation detail |
| `DELETE` | `/api/conversations/:id` | Delete a conversation |
| `GET` | `/api/conversations/:id/messages` | Get message history |

---

## Chat

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/chat` | Send a message to the agent |

**Body:**
```json
{
    "projectId": "abc123",
    "conversationId": "conv456",
    "message": "Review MR !42"
}
```

Responses are streamed via **WebSocket** (see [WebSocket Events](/docs/api-reference/websocket-events)).

---

## Agent Definitions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/projects/:pid/agents` | List agents for project |
| `GET` | `/api/agents` | List all agents (with favorites) |
| `POST` | `/api/agents` | Create a new agent |
| `GET` | `/api/agents/:id` | Get agent detail |
| `PUT` | `/api/agents/:id` | Update agent |
| `DELETE` | `/api/agents/:id` | Delete agent |
| `POST` | `/api/agents/:id/clone` | Clone an agent |
| `POST` | `/api/agents/:id/export` | Export agent as JSON |
| `POST` | `/api/agents/import` | Import agent from JSON |
| `GET` | `/api/agents/:id/versions` | List version history |
| `POST` | `/api/agents/:id/rollback` | Rollback to a version |
| `GET` | `/api/agents/:id/test-cases` | List test cases |
| `POST` | `/api/agents/:id/test-cases` | Create test case |
| `POST` | `/api/agents/:id/favorite` | Mark as favorite |
| `DELETE` | `/api/agents/:id/favorite` | Remove from favorites |

---

## Custom Tools

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/projects/:pid/custom-tools` | List tools |
| `POST` | `/api/projects/:pid/custom-tools` | Create tool |
| `GET` | `/api/custom-tools/:id` | Get tool detail |
| `PUT` | `/api/custom-tools/:id` | Update tool |
| `DELETE` | `/api/custom-tools/:id` | Delete tool |
| `POST` | `/api/custom-tools/:id/compile` | Compile & validate |
| `POST` | `/api/custom-tools/:id/test` | Test with sample input |
| `GET` | `/api/custom-tools/check-name?name=...` | Check name availability |

---

## Cron Jobs

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/projects/:pid/cron` | List cron jobs |
| `POST` | `/api/projects/:pid/cron` | Create cron job |
| `PUT` | `/api/cron/:id` | Update cron job |
| `DELETE` | `/api/cron/:id` | Delete cron job |
| `POST` | `/api/cron/:id/run-now` | Trigger immediate run |

---

## Environment Variables

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/env-vars` | List all environment variables |
| `PUT` | `/api/env-vars` | Update environment variables |

---

## Memories

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/projects/:pid/memories` | List memories |
| `POST` | `/api/projects/:pid/memories` | Create memory |
| `DELETE` | `/api/memories/:id` | Delete memory |

---

---

## MCP

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/mcp` | JSON-RPC 2.0 endpoint |

See [MCP Protocol](/docs/api-reference/mcp-protocol) for method details.

---

## Documentation

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/docs/tree` | Documentation sidebar tree |
| `GET` | `/api/docs/:path+` | Get rendered doc page |
| `GET` | `/api/docs/search?q=...` | Full-text doc search |
| `GET` | `/api/docs/llms.txt` | LLM-optimized doc dump |

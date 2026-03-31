# MCP Protocol Reference

Agile Agent implements the **Model Context Protocol (MCP)** over HTTP, using JSON-RPC 2.0 on `POST /api/mcp`.

## Methods

### `initialize`

Handshake that returns server capabilities.

**Request:**
```json
{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
        "protocolVersion": "2024-11-05",
        "capabilities": {},
        "clientInfo": { "name": "my-client", "version": "1.0" }
    }
}
```

**Response:**
```json
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "protocolVersion": "2024-11-05",
        "capabilities": { "tools": {} },
        "serverInfo": { "name": "agile-agent", "version": "1.1.0" }
    }
}
```

### `tools/list`

Returns all available tools with JSON Schema parameter definitions.

**Request:**
```json
{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/list"
}
```

**Response:**
```json
{
    "jsonrpc": "2.0",
    "id": 2,
    "result": {
        "tools": [
            {
                "name": "run_agent",
                "description": "Execute a full agent workflow",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "prompt": { "type": "string" },
                        "agent_id": { "type": "string" },
                        "agent_intent": { "type": "string" },
                        "live_apis": { "type": "boolean" }
                    },
                    "required": ["prompt"]
                }
            }
        ]
    }
}
```

### `tools/call`

Execute a tool by name.

**Request:**
```json
{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
        "name": "fetch_jira_ticket",
        "arguments": {
            "ticket_key": "PVG-4523"
        }
    }
}
```

**Response:**
```json
{
    "jsonrpc": "2.0",
    "id": 3,
    "result": {
        "content": [
            {
                "type": "text",
                "text": "Ticket PVG-4523: Implement login feature..."
            }
        ]
    }
}
```

## Key MCP Tools

| Tool | Parameters | Description |
|------|-----------|-------------|
| `run_agent` | `prompt`, `agent_id?`, `agent_intent?`, `live_apis?` | Run a full agent workflow |
| `validate_agent` | `agent_id` | Check for missing configParams |
| `update_agent_config` | `agent_id`, `params` | Update configParams |
| `list_projects` | — | List all projects |
| `switch_active_project` | `project_id` | Change active project |

All 30+ built-in tools are also exposed via MCP.

## Error Handling

Errors follow JSON-RPC 2.0 error format:

```json
{
    "jsonrpc": "2.0",
    "id": 3,
    "error": {
        "code": -32602,
        "message": "Unknown tool: nonexistent_tool"
    }
}
```

| Code | Meaning |
|------|---------|
| `-32600` | Invalid request |
| `-32601` | Method not found |
| `-32602` | Invalid params |
| `-32603` | Internal error |

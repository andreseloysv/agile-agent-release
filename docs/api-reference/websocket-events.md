# WebSocket Events

Agile Agent streams events in real-time via WebSocket during agent execution.

## Connection

Connect to the WebSocket endpoint:

```javascript
const ws = new WebSocket('ws://localhost:4372/ws');
```

## Event Types

Events are JSON objects with a `type` field and a `data` payload.

### Pipeline Events

| Type | Payload | Description |
|------|---------|-------------|
| `model_info` | `{ model, maxIterations }` | LLM model being used |
| `intent` | `{ intent, confidence }` | Detected intent |
| `plan` | `{ tasks: TaskNode[] }` | Generated task DAG |
| `task_progress` | `{ taskId, status }` | Task started/completed |
| `tool_call` | `{ tool, args }` | Tool being called |
| `tool_result` | `{ tool, result }` | Tool execution result |
| `critique` | `{ issues }` | Plan self-critique |
| `replan` | `{ tasks }` | Revised plan after critique |
| `thinking` | `{ text }` | LLM thinking/reasoning |
| `response` | `{ text }` | Final response text |
| `error` | `{ message }` | Error during execution |
| `trace` | `{ timings, counts }` | Performance trace |
| `audit_trail` | `{ steps[] }` | Complete execution log |
| `done` | `{}` | Pipeline complete |

### Transformer Events (Large MR Reviews)

| Type | Payload | Description |
|------|---------|-------------|
| `transformer_activated` | `{ fileCount }` | Transformer triggered (50+ files) |
| `transformer_pass` | `{ pass, progress }` | Current pass (1-6) |
| `transformer_validation` | `{ results }` | Script validation results |
| `transformer_chunk` | `{ chunkIndex, files }` | File chunk sent for review |
| `transformer_complete` | `{ report }` | Final merged report |

## Example Client

```javascript
const ws = new WebSocket('ws://localhost:4372/ws');

ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    
    switch (data.type) {
        case 'intent':
            console.log(`Intent: ${data.data.intent}`);
            break;
        case 'tool_call':
            console.log(`Calling: ${data.data.tool}`);
            break;
        case 'response':
            console.log(`Response: ${data.data.text}`);
            break;
        case 'error':
            console.error(`Error: ${data.data.message}`);
            break;
    }
};
```

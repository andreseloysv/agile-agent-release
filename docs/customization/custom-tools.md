# Custom Tools

Write your own TypeScript tools and give them to any agent — compiled and sandboxed server-side.

## What It Does

Custom tools extend what agents can do beyond the 30+ built-in tools. Write TypeScript in the browser, and the platform compiles, sandboxes, and registers it automatically.

> **For developers:** This is the extension point for team-specific integrations. Need to call an internal API? Query a custom database? Parse a proprietary file format? Write a custom tool.

## Creating a Tool

Navigate to **Custom Tools** in your project sub-nav:

### Tool Definition

```typescript
// Tool name: calculate_sprint_velocity
// Description: Calculate the average velocity for a team over N sprints

interface SprintVelocityParams {
    teamName: string;
    sprints: number;
}

export async function execute(params: SprintVelocityParams): Promise<string> {
    const response = await fetch(
        `https://internal-api.example.com/velocity?team=${params.teamName}&n=${params.sprints}`
    );
    const data = await response.json();
    return `Average velocity for ${params.teamName}: ${data.average} story points`;
}
```

### Parameters Schema

Define the JSON Schema for your tool's parameters:

```json
{
    "type": "object",
    "properties": {
        "teamName": { "type": "string", "description": "Team name (e.g., 'Backend API')" },
        "sprints": { "type": "number", "description": "Number of sprints to average" }
    },
    "required": ["teamName", "sprints"]
}
```

## Security Sandbox

Custom tools are compiled with **security validation** that blocks:

| Blocked | Why |
|---------|-----|
| `require()`, `import()` | No access to Node.js built-ins |
| `fs`, `path`, `child_process` | No filesystem or process access |
| `eval()`, `Function()` | No dynamic code execution |
| `process`, `global` | No runtime API access |

Your tool runs in an isolated context with access to:
- `fetch()` for HTTP requests
- Standard JS/TS APIs (String, Array, JSON, etc.)
- The parameters passed by the LLM

## Using Custom Tools

Once created, add the tool to any agent in the Agent Builder's **Tools** section. The tool appears in the tool list alongside built-in tools.

## REST API

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/projects/:pid/custom-tools` | List all custom tools |
| `POST` | `/api/projects/:pid/custom-tools` | Create a new tool |
| `PUT` | `/api/custom-tools/:id` | Update tool code or schema |
| `DELETE` | `/api/custom-tools/:id` | Delete a tool |
| `POST` | `/api/custom-tools/:id/compile` | Compile and validate |
| `POST` | `/api/custom-tools/:id/test` | Test with sample input |

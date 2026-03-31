# JSM Integration

Create and manage Jira Service Management requests from the agent.

## What It Does

The JSM integration enables automated service request creation:

- **Create service requests** with predefined templates
- **Configure parameters** (JSM URL, project key, request type) per agent

> **For teams:** Agents can automatically create JSM tickets when they detect issues — for example, a security review agent could create a vulnerability report in JSM.

## Setup

1. Go to **Settings** → set:
   - `JSM_URL` — your JSM instance URL
   - `JSM_TOKEN` — your JSM API token

2. In the Agent Builder, add `create_jsm_request` to your agent's tool set and configure the required `configParams`:
   - `jsm_url` — the JSM service desk URL
   - `jsm_project_key` — the JSM project key

## Configuration Parameters

The `create_jsm_request` tool uses **configParams** — static parameters set in the Agent Builder's Properties panel, not by the LLM. This ensures requests always go to the correct service desk.

```
validate_agent → find missing jsm_url → update_agent_config → set it → run_agent
```

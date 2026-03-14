-- Migration 015: Add agent_runs for Metrics Dashboard
CREATE TABLE IF NOT EXISTS agent_runs (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    intent TEXT NOT NULL,
    started_at INTEGER NOT NULL,
    ended_at INTEGER NOT NULL,
    total_duration_ms INTEGER NOT NULL,
    llm_call_count INTEGER NOT NULL,
    tool_call_count INTEGER NOT NULL,
    task_count INTEGER NOT NULL,
    FOREIGN KEY(project_id) REFERENCES projects(id)
);

CREATE INDEX IF NOT EXISTS idx_agent_runs_project ON agent_runs(project_id);

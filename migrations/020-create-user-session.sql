CREATE TABLE IF NOT EXISTS user_sessions (
    id TEXT PRIMARY KEY,
    active_project_id TEXT,
    preferences TEXT NOT NULL DEFAULT '{}',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (active_project_id) REFERENCES projects(id) ON DELETE SET NULL
);

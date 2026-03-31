CREATE TABLE IF NOT EXISTS notification_rules (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    channel TEXT NOT NULL,       -- 'whatsapp' | 'webhook' | 'email'
    recipient TEXT NOT NULL,     -- phone number / URL / email
    events TEXT NOT NULL,        -- JSON array: ['review_complete', 'stories_created', 'blast_radius_warning']
    enabled INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS cron_jobs (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    name TEXT NOT NULL,
    cron_expression TEXT NOT NULL,
    prompt TEXT NOT NULL,
    intent_override TEXT,
    enabled INTEGER DEFAULT 1,
    last_run_at TEXT,
    last_result TEXT,           -- 'success' | 'error'
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
);

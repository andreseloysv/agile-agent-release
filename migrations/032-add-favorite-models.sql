CREATE TABLE IF NOT EXISTS favorite_models (
    id TEXT PRIMARY KEY,
    model_id TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

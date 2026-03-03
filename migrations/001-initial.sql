-- Projects: each with own config
CREATE TABLE IF NOT EXISTS projects (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  system_prompt   TEXT NOT NULL DEFAULT '',
  project_root    TEXT,
  gitlab_url      TEXT,
  gitlab_project  TEXT,
  model           TEXT DEFAULT 'gemini-2.5-pro',
  max_iterations  INTEGER DEFAULT 60,
  created_at      TEXT DEFAULT (datetime('now')),
  updated_at      TEXT DEFAULT (datetime('now'))
);

-- Conversations: per project
CREATE TABLE IF NOT EXISTS conversations (
  id          TEXT PRIMARY KEY,
  project_id  TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title       TEXT,
  created_at  TEXT DEFAULT (datetime('now')),
  updated_at  TEXT DEFAULT (datetime('now'))
);

-- Messages: full chat history
CREATE TABLE IF NOT EXISTS messages (
  id                TEXT PRIMARY KEY,
  conversation_id   TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  role              TEXT NOT NULL CHECK(role IN ('user', 'assistant', 'tool')),
  content           TEXT NOT NULL,
  tool_name         TEXT,
  tool_args         TEXT,
  thinking          TEXT,
  created_at        TEXT DEFAULT (datetime('now'))
);

-- Long-term memories: extracted facts/decisions per project
CREATE TABLE IF NOT EXISTS memories (
  id                      TEXT PRIMARY KEY,
  project_id              TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  type                    TEXT NOT NULL CHECK(type IN ('fact', 'decision', 'summary', 'context')),
  content                 TEXT NOT NULL,
  source_conversation_id  TEXT REFERENCES conversations(id) ON DELETE SET NULL,
  relevance_keywords      TEXT,
  created_at              TEXT DEFAULT (datetime('now'))
);

-- Environment variables: shared across projects
CREATE TABLE IF NOT EXISTS env_vars (
  id          TEXT PRIMARY KEY,
  key         TEXT NOT NULL UNIQUE,
  value       TEXT NOT NULL,
  is_secret   INTEGER DEFAULT 0,
  created_at  TEXT DEFAULT (datetime('now')),
  updated_at  TEXT DEFAULT (datetime('now'))
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_conversations_project ON conversations(project_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_memories_project ON memories(project_id);
CREATE INDEX IF NOT EXISTS idx_env_vars_key ON env_vars(key);

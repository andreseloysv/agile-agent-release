-- Agent definitions (core table)
CREATE TABLE IF NOT EXISTS agent_definitions (
  id            TEXT PRIMARY KEY,
  project_id    TEXT REFERENCES projects(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  description   TEXT NOT NULL DEFAULT '',
  icon          TEXT,
  version       INTEGER NOT NULL DEFAULT 1,
  intent        TEXT NOT NULL,
  config_json   TEXT NOT NULL,
  is_builtin    INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT DEFAULT (datetime('now')),
  updated_at    TEXT DEFAULT (datetime('now'))
);

-- Test cases
CREATE TABLE IF NOT EXISTS agent_test_cases (
  id              TEXT PRIMARY KEY,
  agent_id        TEXT NOT NULL REFERENCES agent_definitions(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  input_prompt    TEXT NOT NULL,
  expected_output TEXT,
  last_result     TEXT,
  last_status     TEXT CHECK(last_status IN ('pass', 'fail', 'pending', NULL)),
  last_run_at     TEXT,
  created_at      TEXT DEFAULT (datetime('now'))
);

-- Version history
CREATE TABLE IF NOT EXISTS agent_versions (
  id          TEXT PRIMARY KEY,
  agent_id    TEXT NOT NULL REFERENCES agent_definitions(id) ON DELETE CASCADE,
  version     INTEGER NOT NULL,
  config_json TEXT NOT NULL,
  created_at  TEXT DEFAULT (datetime('now'))
);

-- Custom tools (TypeScript source stored here)
CREATE TABLE IF NOT EXISTS custom_tools (
  id            TEXT PRIMARY KEY,
  project_id    TEXT REFERENCES projects(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  description   TEXT NOT NULL,
  parameters    TEXT NOT NULL,
  source_code   TEXT NOT NULL,
  compiled_js   TEXT,
  is_builtin    INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT DEFAULT (datetime('now')),
  updated_at    TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_agent_defs_project ON agent_definitions(project_id);
CREATE INDEX IF NOT EXISTS idx_agent_defs_intent ON agent_definitions(intent);
CREATE INDEX IF NOT EXISTS idx_agent_tests_agent ON agent_test_cases(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_versions_agent ON agent_versions(agent_id);
CREATE INDEX IF NOT EXISTS idx_custom_tools_project ON custom_tools(project_id);

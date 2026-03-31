-- Add favorite flag to agent definitions
ALTER TABLE agent_definitions ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0;

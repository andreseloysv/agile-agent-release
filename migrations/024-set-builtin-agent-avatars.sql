-- Set manga avatar for all built-in agents that don't have one yet.
-- The avatar ID matches the folder name under /avatars/agent-{intent}/
UPDATE agent_definitions
SET avatar = 'agent-' || intent,
    updated_at = datetime('now')
WHERE is_builtin = 1
  AND (avatar IS NULL OR avatar = '');

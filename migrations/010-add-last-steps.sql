-- Add last_steps column to conversations (stores JSON of per-task step logs for persistence across reloads)
ALTER TABLE conversations ADD COLUMN last_steps TEXT DEFAULT NULL;

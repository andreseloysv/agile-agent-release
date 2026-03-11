-- Add last_events column to conversations (stores JSON of agent events for persistence across reloads)
ALTER TABLE conversations ADD COLUMN last_events TEXT DEFAULT NULL;

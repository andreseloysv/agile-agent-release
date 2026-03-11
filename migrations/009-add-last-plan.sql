-- Add last_plan column to conversations (stores JSON of the last plan for persistence across reloads)
ALTER TABLE conversations ADD COLUMN last_plan TEXT DEFAULT NULL;

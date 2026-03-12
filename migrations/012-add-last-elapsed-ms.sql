-- Add last_elapsed_ms column to conversations (stores total agent execution time in milliseconds)
ALTER TABLE conversations ADD COLUMN last_elapsed_ms INTEGER DEFAULT NULL;

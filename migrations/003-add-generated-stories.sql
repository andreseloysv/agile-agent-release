-- Add generated_stories column to conversations (stores JSON array of generated user stories)
ALTER TABLE conversations ADD COLUMN generated_stories TEXT DEFAULT NULL;

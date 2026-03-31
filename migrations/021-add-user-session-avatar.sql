-- Add avatar selection column to user_sessions
ALTER TABLE user_sessions ADD COLUMN avatar TEXT DEFAULT 'chibi-01';

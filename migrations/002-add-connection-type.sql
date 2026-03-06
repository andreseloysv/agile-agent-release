-- Add connection_type column to projects (gemini | api)
-- Existing projects default to 'gemini' for backwards compatibility
ALTER TABLE projects ADD COLUMN connection_type TEXT DEFAULT 'gemini';

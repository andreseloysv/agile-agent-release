-- Add per-project Teams channel configuration
ALTER TABLE projects ADD COLUMN teams_channel TEXT DEFAULT NULL;

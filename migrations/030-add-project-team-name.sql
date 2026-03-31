-- Add per-project team name for cron job comment deduplication
ALTER TABLE projects ADD COLUMN team_name TEXT DEFAULT NULL;

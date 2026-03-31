-- Add jira_team_group column to cron_jobs
ALTER TABLE cron_jobs ADD COLUMN jira_team_group TEXT DEFAULT NULL;

-- Add pipeline_id column to cron_jobs for pipeline-based execution
ALTER TABLE cron_jobs ADD COLUMN pipeline_id TEXT;

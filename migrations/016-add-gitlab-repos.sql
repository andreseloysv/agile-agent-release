-- Add gitlab_repos column for multiple GitLab repository URLs (JSON array)
ALTER TABLE projects ADD COLUMN gitlab_repos TEXT DEFAULT NULL;

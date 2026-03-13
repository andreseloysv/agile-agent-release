-- Add mr_iid column to conversations (stores the GitLab MR IID for code reviews)
ALTER TABLE conversations ADD COLUMN mr_iid INTEGER DEFAULT NULL;

-- Add story_generation_rules to projects table to hold learned behaviors from user story edits
ALTER TABLE projects ADD COLUMN story_generation_rules TEXT;

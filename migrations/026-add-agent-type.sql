-- Add agent_type column to distinguish between regular agents and orchestrators
ALTER TABLE agent_definitions ADD COLUMN agent_type TEXT DEFAULT 'agent' NOT NULL;

-- Add recommended LLM model and cost tier to agent definitions
ALTER TABLE agent_definitions ADD COLUMN recommended_model TEXT;
ALTER TABLE agent_definitions ADD COLUMN cost_tier TEXT CHECK(cost_tier IN ('free', 'economy', 'standard', 'premium'));

-- Feedback: thumbs up/down on agent messages
CREATE TABLE IF NOT EXISTS feedback (
  id              TEXT PRIMARY KEY,
  message_id      TEXT NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  rating          TEXT NOT NULL CHECK(rating IN ('positive', 'negative')),
  comment         TEXT,
  intent          TEXT,
  model           TEXT,
  tool_call_count INTEGER DEFAULT 0,
  response_length INTEGER DEFAULT 0,
  created_at      TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_feedback_message ON feedback(message_id);
CREATE INDEX IF NOT EXISTS idx_feedback_conversation ON feedback(conversation_id);

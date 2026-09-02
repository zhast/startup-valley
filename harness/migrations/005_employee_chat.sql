CREATE TABLE IF NOT EXISTS employee_chat_messages (
  id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  sender TEXT NOT NULL CHECK (sender IN ('player', 'employee')),
  content TEXT NOT NULL,
  input_tokens INTEGER NOT NULL DEFAULT 0,
  output_tokens INTEGER NOT NULL DEFAULT 0,
  cost REAL,
  created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_employee_chat_history
  ON employee_chat_messages(employee_id, created_at DESC, id DESC);

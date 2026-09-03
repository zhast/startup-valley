ALTER TABLE employees ADD COLUMN employment_status TEXT NOT NULL DEFAULT 'hired';
ALTER TABLE employees ADD COLUMN hired_day INTEGER;
ALTER TABLE work_orders ADD COLUMN milestone_id TEXT;
ALTER TABLE work_orders ADD COLUMN revision_of_job_id TEXT;
ALTER TABLE work_orders ADD COLUMN game_day INTEGER NOT NULL DEFAULT 1;
ALTER TABLE employee_chat_messages ADD COLUMN game_day INTEGER NOT NULL DEFAULT 1;
CREATE TABLE company_state (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  cash_cents INTEGER NOT NULL DEFAULT 0 CHECK (cash_cents >= 0),
  earned_cents INTEGER NOT NULL DEFAULT 0,
  reputation INTEGER NOT NULL DEFAULT 0,
  chapter INTEGER NOT NULL DEFAULT 1,
  player_json TEXT NOT NULL DEFAULT '{}'
);
INSERT INTO company_state (id) VALUES (1);
CREATE TABLE milestone_progress (
  id TEXT PRIMARY KEY,
  job_id TEXT,
  completed INTEGER NOT NULL DEFAULT 0,
  overridden INTEGER NOT NULL DEFAULT 0,
  completed_day INTEGER
);
CREATE TABLE milestone_evaluations (
  job_id TEXT PRIMARY KEY REFERENCES work_orders(id),
  status TEXT NOT NULL,
  result_json TEXT,
  error TEXT
);
CREATE TABLE evaluation_usage (
  id TEXT PRIMARY KEY,
  job_id TEXT NOT NULL,
  input_tokens INTEGER NOT NULL,
  output_tokens INTEGER NOT NULL,
  cost REAL NOT NULL,
  created_at TEXT NOT NULL,
  game_day INTEGER NOT NULL DEFAULT 1
);
CREATE TABLE company_transactions (
  id TEXT PRIMARY KEY,
  day INTEGER NOT NULL,
  cash_delta INTEGER NOT NULL,
  earned_delta INTEGER NOT NULL,
  reputation_delta INTEGER NOT NULL,
  label TEXT NOT NULL
);
CREATE TABLE day_summaries (
  day INTEGER PRIMARY KEY,
  summary_json TEXT NOT NULL
);

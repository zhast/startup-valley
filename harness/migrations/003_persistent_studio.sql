CREATE TABLE IF NOT EXISTS studio_files (
  relative_path TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  media_type TEXT NOT NULL,
  source_work_order_id TEXT NOT NULL REFERENCES work_orders(id),
  source_artifact_id TEXT NOT NULL REFERENCES artifacts(id),
  promoted_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS game_state (
  key TEXT PRIMARY KEY,
  value_json TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_studio_files_promoted
  ON studio_files(promoted_at DESC, relative_path);
CREATE INDEX IF NOT EXISTS idx_work_orders_status_created
  ON work_orders(status, created_at);

CREATE TABLE tycoon_meta (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  seed INTEGER NOT NULL
);
INSERT INTO tycoon_meta (id, seed) VALUES (1, 26021);

CREATE TABLE tycoon_products (
  id TEXT PRIMARY KEY,
  topic_id TEXT NOT NULL,
  type_id TEXT NOT NULL,
  name TEXT NOT NULL,
  fit TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('developing', 'released', 'complete')),
  started_day INTEGER NOT NULL,
  dev_days INTEGER NOT NULL DEFAULT 0,
  design_points INTEGER NOT NULL DEFAULT 0,
  tech_points INTEGER NOT NULL DEFAULT 0,
  hype_points INTEGER NOT NULL DEFAULT 0,
  staff_json TEXT NOT NULL,
  last_dev_day INTEGER,
  released_day INTEGER,
  review_json TEXT,
  sales_applied INTEGER NOT NULL DEFAULT 0,
  last_sales_day INTEGER,
  sales_cents INTEGER NOT NULL DEFAULT 0,
  fans INTEGER NOT NULL DEFAULT 0
);

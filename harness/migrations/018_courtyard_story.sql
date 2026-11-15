CREATE TABLE story_state (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  revision INTEGER NOT NULL DEFAULT 0 CHECK (revision >= 0),
  location TEXT NOT NULL DEFAULT 'office' CHECK (location IN ('office','courtyard')),
  visited INTEGER NOT NULL DEFAULT 0 CHECK (visited IN (0,1)),
  met_theo INTEGER NOT NULL DEFAULT 0 CHECK (met_theo IN (0,1)),
  opportunity_accepted INTEGER NOT NULL DEFAULT 0 CHECK (opportunity_accepted IN (0,1)),
  opportunity_product_id TEXT NOT NULL DEFAULT '',
  return_x REAL,
  return_y REAL,
  return_layout_id TEXT NOT NULL DEFAULT ''
);
INSERT INTO story_state (id) VALUES (1);

CREATE TABLE story_operations (
  operation_id TEXT PRIMARY KEY,
  fingerprint TEXT NOT NULL
);

CREATE TABLE furnishing_inventory (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL,
  owner_id TEXT NOT NULL,
  essential INTEGER NOT NULL CHECK (essential IN (0, 1)),
  grant_id TEXT NOT NULL,
  role_kit TEXT NOT NULL DEFAULT ''
);
CREATE TABLE furnishing_state (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  version INTEGER NOT NULL,
  revision INTEGER NOT NULL CHECK (revision >= 0),
  placements_json TEXT NOT NULL,
  last_valid_json TEXT NOT NULL,
  recovery TEXT NOT NULL DEFAULT ''
);
CREATE TABLE furnishing_operations (
  operation_id TEXT PRIMARY KEY,
  fingerprint TEXT NOT NULL,
  result_json TEXT NOT NULL
);

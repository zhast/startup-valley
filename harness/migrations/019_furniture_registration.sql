-- Versioned physical registration is separate from the player-owned item IDs.
-- Existing rooms need one compatibility pass; fresh rooms use the new profiles.
CREATE TABLE furnishing_geometry_state (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  revision INTEGER NOT NULL CHECK (revision >= 0)
);
INSERT INTO furnishing_geometry_state VALUES (
  1, CASE WHEN EXISTS (SELECT 1 FROM furnishing_state WHERE id=1) THEN 0 ELSE 1 END
);

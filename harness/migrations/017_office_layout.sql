-- One durable layout identity per company. Pre-existing companies keep their
-- original geometry; the database bootstrap selects the cottage for new saves.
CREATE TABLE office_layout_state (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  layout_id TEXT NOT NULL CHECK (layout_id IN ('startup-office', 'starter-cottage-v1'))
);
INSERT INTO office_layout_state (id, layout_id) VALUES (1, 'startup-office');

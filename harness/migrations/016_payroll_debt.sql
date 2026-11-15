-- Payroll can leave game cash below zero. The old floor blocked that row.
CREATE TABLE company_state_next (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  cash_cents INTEGER NOT NULL DEFAULT 0,
  earned_cents INTEGER NOT NULL DEFAULT 0,
  reputation INTEGER NOT NULL DEFAULT 0,
  chapter INTEGER NOT NULL DEFAULT 1,
  player_json TEXT NOT NULL DEFAULT '{}',
  opened_chapter INTEGER NOT NULL DEFAULT 1
);
INSERT INTO company_state_next (id, cash_cents, earned_cents, reputation, chapter, player_json, opened_chapter)
SELECT id, cash_cents, earned_cents, reputation, chapter, player_json, opened_chapter FROM company_state;
DROP TABLE company_state;
ALTER TABLE company_state_next RENAME TO company_state;

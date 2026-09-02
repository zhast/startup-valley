ALTER TABLE work_orders ADD COLUMN title TEXT NOT NULL DEFAULT 'Work order';
ALTER TABLE work_orders ADD COLUMN summary TEXT;

ALTER TABLE employee_memories ADD COLUMN kind TEXT NOT NULL DEFAULT 'fact';
ALTER TABLE employee_memories ADD COLUMN work_order_id TEXT REFERENCES work_orders(id) ON DELETE CASCADE;
ALTER TABLE employee_memories ADD COLUMN payload_json TEXT NOT NULL DEFAULT '{}';

CREATE UNIQUE INDEX IF NOT EXISTS idx_employee_memories_writeback
  ON employee_memories(employee_id, work_order_id, kind);
CREATE INDEX IF NOT EXISTS idx_employee_memories_context
  ON employee_memories(employee_id, created_at DESC);

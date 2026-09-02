ALTER TABLE work_orders ADD COLUMN attached_studio_path TEXT;
ALTER TABLE work_orders ADD COLUMN promotion_status TEXT NOT NULL DEFAULT 'none'
  CHECK (promotion_status IN ('none', 'pending', 'approved', 'discarded'));

UPDATE work_orders
SET promotion_status = 'approved'
WHERE status = 'completed'
  AND EXISTS (
    SELECT 1 FROM studio_files
    WHERE studio_files.source_work_order_id = work_orders.id
  );

UPDATE work_orders
SET promotion_status = 'pending'
WHERE status = 'completed'
  AND promotion_status = 'none'
  AND EXISTS (
    SELECT 1 FROM artifacts
    WHERE artifacts.work_order_id = work_orders.id
  );

CREATE INDEX IF NOT EXISTS idx_work_orders_promotion
  ON work_orders(promotion_status, finished_at DESC, created_at DESC);

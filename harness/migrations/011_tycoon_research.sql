ALTER TABLE tycoon_meta ADD COLUMN research_points INTEGER NOT NULL DEFAULT 0;
ALTER TABLE tycoon_meta ADD COLUMN research_json TEXT NOT NULL DEFAULT '';
ALTER TABLE tycoon_products ADD COLUMN release_research INTEGER;

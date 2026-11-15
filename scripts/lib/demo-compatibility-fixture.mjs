import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import { GameDatabase, readMigrations } from '../../harness/dist/database.js';

// Deliberately seeded compatibility cases, never clean-journey evidence.
export async function createCompatibilityFixture(kind, data, output) {
  assert.ok(['legacy', 'expansion'].includes(kind));
  const path = join(data, 'startup-valley.sqlite');
  if (kind === 'legacy') {
    const old = new DatabaseSync(path);
    old.exec('CREATE TABLE schema_migrations(version INTEGER PRIMARY KEY,applied_at TEXT NOT NULL)');
    for (const [name, sql] of Object.entries(readMigrations()).sort().filter(([name]) => Number(name.slice(0, 3)) < 17)) {
      old.exec(sql);
      if (!name.startsWith('001')) old.prepare("INSERT INTO schema_migrations VALUES (?, 'compatibility-fixture')").run(Number(name.slice(0, 3)));
    }
    old.close();
  }
  const project = join(data, 'company-project');
  await mkdir(project, { recursive: true });
  const db = new GameDatabase(path, project);
  db.journey.hire('mira', 1);
  db.journey.db.exec("UPDATE milestone_progress SET completed=1 WHERE id='website'; UPDATE company_state SET cash_cents=100000,reputation=10 WHERE id=1");
  if (kind === 'legacy') {
    const state = db.furnishing.state();
    db.furnishing.update({ operationId: 'compatibility-decoration', expectedRevision: state.revision,
      placements: { ...state.placements, 'decor-broadleaf_planter': { grid: [24, 8], facing: 'south' } } });
    db.journey.savePlayer({ x: 550.25, y: 590.5, movementSeen: true });
  }
  const state = db.bootstrap();
  const expected = { kind, company: state.journey.company, furnishing: state.furnishing, player: state.journey.player,
    // A pre-19 geometry upgrade increments the edit revision once, even if
    // these particular furniture positions still fit the corrected profiles.
    migrationRevisionDelta: kind === 'legacy' ? 1 : 0 };
  if (kind === 'legacy') {
    // Leave a genuine pre-17 schema at the actual worker startup boundary.
    // Remove every post-16 table as well as its migration receipt. In
    // particular, leaving migration19's table would create an impossible
    // historical database and make the real migration fail on CREATE TABLE.
    db.journey.db.exec('DROP TABLE office_layout_state; DROP TABLE story_state; DROP TABLE story_operations; DROP TABLE furnishing_geometry_state; DELETE FROM schema_migrations WHERE version >= 17');
  }
  db.close();
  const evidence = join(output, 'compatibility-fixture.json');
  await writeFile(evidence, JSON.stringify(expected, null, 2));
  return evidence;
}

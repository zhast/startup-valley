import { GameDatabase } from "../src/database.js";

/** Existing test scenarios predate hiring and model an already-staffed company. */
export class LegacyDatabase extends GameDatabase {
  constructor(path: string, projectRoot: string) {
    super(path, projectRoot);
    this.journey.db.prepare("UPDATE employees SET employment_status='hired' WHERE id IN ('mira','theo')").run();
  }
}

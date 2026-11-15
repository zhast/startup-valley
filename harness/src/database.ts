import { readFileSync, readdirSync } from "node:fs";
import { DatabaseSync } from "node:sqlite";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { GameDatabase as CoreDatabase } from "./database-core.js";
import { furnishingHash, readGeometryData } from "./furnishing.js";
import { parseFurnishingState } from "./validation.js";

export function readMigrations(): Record<string, string> {
  const root = join(dirname(fileURLToPath(import.meta.url)), "..", "migrations");
  return Object.fromEntries(readdirSync(root).filter((name) => name.endsWith(".sql")).map((name) => [name, readFileSync(join(root, name), "utf8")]));
}
/** Native entry point: retain the existing constructor and SQLite save format. */
export class GameDatabase extends CoreDatabase {
  constructor(databasePath: string, projectRoot: string) {
    const database = new DatabaseSync(databasePath);
    try {
      super(database, projectRoot, { migrations: readMigrations(), geometryData: readGeometryData(), parseFurnishingState, hash: furnishingHash });
    } catch (error) {
      database.close();
      throw error;
    }
  }
}

import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { FurnishingGeometry as CoreGeometry, FurnishingStore as CoreStore, type GeometryData } from "./furnishing-core.js";
import type { SqlDatabase } from "./sql-database.js";
import { parseFurnishingState } from "./validation.js";
export * from "./furnishing-core.js";

export function readGeometryData(): GeometryData {
  const data = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "game", "data");
  const read = (name: string): unknown => JSON.parse(readFileSync(join(data, name), "utf8"));
  return { officeLayout: read("office_layout.json"), starterOfficeLayout: read("office_layout_starter.json"), furnitureCatalog: read("furniture_catalog.json"), furnishingCatalog: read("furnishing_catalog.json") };
}
export const furnishingHash = (value: string): string => createHash("sha256").update(value).digest("hex");
export class FurnishingGeometry extends CoreGeometry {
  constructor() { super(readGeometryData()); }
}
export class FurnishingStore extends CoreStore {
  constructor(database: SqlDatabase) { super(database, new FurnishingGeometry(), parseFurnishingState, furnishingHash); }
}

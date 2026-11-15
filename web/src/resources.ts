import officeLayout from "../../game/data/office_layout.json";
import furnitureCatalog from "../../game/data/furniture_catalog.json";
import furnishingCatalog from "../../game/data/furnishing_catalog.json";

const byBasename = <T>(files: Record<string, T>): Record<string, T> => Object.fromEntries(
  Object.entries(files).map(([path, value]) => [path.slice(path.lastIndexOf("/") + 1), value]),
);

export const geometryData = { officeLayout, furnitureCatalog, furnishingCatalog };
export const migrations = byBasename(import.meta.glob<string>("../../harness/migrations/*.sql", { query: "?raw", import: "default", eager: true }));
export const schemas = byBasename(import.meta.glob<object>("../../contracts/*.schema.json", { import: "default", eager: true }));

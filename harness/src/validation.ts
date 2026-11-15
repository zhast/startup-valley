import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { CONTRACT_SCHEMAS, createValidation } from "./validation-core.js";

export function readContractSchemas(): Record<string, object> {
  const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "contracts");
  return Object.fromEntries(CONTRACT_SCHEMAS.map((name) => [name, JSON.parse(readFileSync(join(root, name), "utf8")) as object]));
}
export const { parseRequest, parseJobSpec, parseFurnishingState } = createValidation(readContractSchemas());

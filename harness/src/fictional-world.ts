/** Render old save labels in the current fictional setting without rewriting
 * product IDs, balances, reviews, or transaction history on disk. */
export function fictionalWorld<T>(value: T): T {
  if (typeof value === "string") return value.replace(/\bWhop\b/gu, "TownSquare") as T;
  if (Array.isArray(value)) return value.map((item: unknown) => fictionalWorld(item)) as T;
  if (value !== null && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, fictionalWorld(item)])) as T;
  }
  return value;
}

// Deterministic cross-language samples, using production worker geometry as one
// side of the comparison. The Godot companion must compute its own acceptance.
import { GameDatabase } from "../../dist/database.js";
import { mkdir, writeFile } from "node:fs/promises";
import { dirname } from "node:path";

const db = new GameDatabase(":memory:", "/tmp/furnishing-parity-provider-free");
const contexts = [];
for (let stage = 0; stage <= 2; stage++) {
  if (stage === 1) db.journey.hire("mira", 1);
  if (stage === 2) db.journey.db.exec("UPDATE employees SET employment_status='hired' WHERE id='theo'");
  const { inventory, placements } = db.bootstrap().furnishing;
  contexts.push({ name: `stage-${stage}`, inventory, placements });
}
let seed = 0x51A71E;
function random(max) { seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0; return seed % max; }
const cases = [];
for (const context of contexts) {
  for (const item of context.inventory) {
    for (const facing of ["north", "east", "south", "west"]) {
      // Native exact boundaries and a safely separated decor corner, then seeded
      // whole-room samples. This deliberately includes plenty of rejections.
      const cells = [[24, 8], [7, 14], [2, 3], [3, 6], [34, 20], [17, 10], ...(context.placements[item.id] ? [context.placements[item.id].grid] : [])];
      for (let sample = 0; sample < 5; sample++) cells.push([random(40), random(23)]);
      for (const grid of cells) {
        const candidate = { ...context.placements, [item.id]: { grid, facing } };
        let valid = true, error = "";
        try { db.furnishing.geometry.validate(candidate, context.inventory); }
        catch (reason) { valid = false; error = String(reason.message ?? reason); }
        cases.push({ context: context.name, id: item.id, grid, facing, valid, error });
      }
    }
  }
}
db.close();
const result = { version: 1, seed: "0x51A71E", contexts, cases, accepted: cases.filter((entry) => entry.valid).length, rejected: cases.filter((entry) => !entry.valid).length };
if (process.argv[2]) {
  await mkdir(dirname(process.argv[2]), { recursive: true });
  await writeFile(process.argv[2], JSON.stringify(result, null, 2) + "\n");
  console.log(JSON.stringify({ path: process.argv[2], cases: cases.length, accepted: result.accepted, rejected: result.rejected }));
} else console.log(JSON.stringify(result));

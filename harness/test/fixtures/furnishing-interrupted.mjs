// Provider-free crash probe: pause the real update after its state write, before
// its operation receipt/COMMIT. The parent kills this process at the exact marker.
import { GameDatabase } from "../../dist/database.js";
import { join } from "node:path";

const root = process.argv[2];
const db = new GameDatabase(join(root, "startup-valley.sqlite"), join(root, "company-project"));
const state = db.bootstrap().furnishing;
db.journey.db.function("pause_furnishing_commit", () => {
  process.stdout.write("FURNISHING_UNCOMMITTED\n");
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0);
  return 0;
});
db.journey.db.exec("CREATE TRIGGER furnishing_crash_probe BEFORE INSERT ON furnishing_operations BEGIN SELECT pause_furnishing_commit(); END");
db.furnishing.update({ operationId: "interrupted-layout", expectedRevision: state.revision,
  placements: { ...state.placements, "decor-broadleaf_planter": { grid: [22, 16], facing: "east" } },
  actorCells: [{ id: "founder", grid: [17, 19], position: [569.25, 629.75] }] });
throw new Error("The test parent should kill the worker before commit");

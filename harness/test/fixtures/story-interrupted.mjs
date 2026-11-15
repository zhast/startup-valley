// Pause a real travel transaction after both location and coordinates changed,
// before its durable receipt/COMMIT. The parent kills this disposable worker.
import { GameDatabase } from "../../dist/database.js";
import { join } from "node:path";
import { writeSync } from "node:fs";

const root = process.argv[2];
const db = new GameDatabase(join(root, "game.sqlite"), root);
db.journey.db.function("pause_story_commit", () => {
  writeSync(1, "STORY_UNCOMMITTED\n");
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0);
  return 0;
});
db.journey.db.exec("CREATE TRIGGER story_crash_probe BEFORE INSERT ON story_operations BEGIN SELECT pause_story_commit(); END");
db.story.travel({ destination: "courtyard", operationId: "interrupted-travel", expectedRevision: db.story.view().revision });
throw new Error("The parent should interrupt this worker before commit");

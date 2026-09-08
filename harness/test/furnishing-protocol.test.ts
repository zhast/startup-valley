import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";
import test from "node:test";
import { GameDatabase } from "../src/database.js";
import type { FurnishingState } from "../src/furnishing.js";

function worker(root: string) {
  const child = spawn(process.execPath, ["dist/main.js", "--data-dir", root], { cwd: new URL("..", import.meta.url), stdio: ["pipe", "pipe", "pipe"] });
  const responses = new Map<string, (value: any) => void>();
  const lines = createInterface({ input: child.stdout });
  let errors = ""; child.stderr.on("data", (chunk) => { errors += String(chunk); });
  lines.on("line", (line) => { const value = JSON.parse(line); if (value.id) responses.get(value.id)?.(value); });
  const request = (id: string, method: string, params: object = {}) => new Promise<any>((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timed out ${method}: ${errors}`)), 5000);
    responses.set(id, (value) => { clearTimeout(timer); responses.delete(id); resolve(value); });
    child.stdin.write(JSON.stringify({ kind: "request", id, method, params }) + "\n");
  });
  const stop = async (crash = false) => {
    if (child.exitCode === null && child.signalCode === null) {
      const done = once(child, "exit");
      if (crash) child.kill("SIGKILL"); else child.stdin.end();
      await done;
    }
    lines.close();
  };
  return { child, request, stop };
}

test("real stdio furnishing dispatch survives retry, stale concurrent updates, crash and recoverable New Company", async (t) => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-furnishing-protocol-"));
  let process = worker(root); t.after(async () => { await process.stop(true); });
  const boot = await process.request("boot", "bootstrap"); assert.equal(boot.ok, true);
  const initial = boot.result.furnishing as FurnishingState;
  const params = { operationId: "place-plant", expectedRevision: initial.revision,
    placements: { ...initial.placements, "decor-broadleaf_planter": { grid: [22, 16], facing: "south" } } };
  const placed = await process.request("place", "furnishing.update", params);
  assert.equal(placed.ok, true); assert.equal(placed.result.replayed, false);
  assert.deepEqual((await process.request("place", "furnishing.update", params)).result, placed.result, "same protocol ID shares exact receipt");
  assert.equal((await process.request("retry-with-new-request", "furnishing.update", params)).result.replayed, true);
  const snapshot = placed.result.furnishing as FurnishingState;
  const [first, second] = await Promise.all(["east", "west"].map((facing) => process.request(facing, "furnishing.update", {
    operationId: `rotate-${facing}`, expectedRevision: snapshot.revision,
    placements: { ...snapshot.placements, "decor-broadleaf_planter": { grid: [22, 16], facing } },
  })));
  assert.equal([first, second].filter((item) => item.ok).length, 1);
  assert.match([first, second].find((item) => !item.ok).error, /room changed/u);
  const latest = (first.ok ? first : second).result.furnishing as FurnishingState;
  await process.stop(true); process = worker(root);
  assert.deepEqual((await process.request("restart", "bootstrap")).result.furnishing, latest);
  const replay = await process.request("durable-retry", "furnishing.update", params);
  assert.equal(replay.result.replayed, true); assert.deepEqual(replay.result.furnishing, latest);
  assert.equal((await process.request("bad-input", "furnishing.update", { ...params, inventory: [] })).ok, false);
  const hired = await process.request("hire", "hiring.complete", { employeeId: "mira" }); assert.equal(hired.ok, true);
  assert.deepEqual(hired.result.furnishing.placements["decor-broadleaf_planter"], latest.placements["decor-broadleaf_planter"]);
  assert.equal(hired.result.furnishing.inventory.filter((item: any) => item.roleKit === "mina_discovery_kit").length, 1);
  await writeFile(join(root, "company-project", "precious-company-note.md"), "Keep the company and its furnishing.");
  const fresh = await process.request("new", "game.new", { confirmed: true }); assert.equal(fresh.ok, true);
  assert.deepEqual(fresh.result.furnishing, initial);
  assert.equal(await readFile(join(fresh.result.backupPath, "company-project", "precious-company-note.md"), "utf8"), "Keep the company and its furnishing.");
  const backup = new GameDatabase(join(fresh.result.backupPath, "startup-valley.sqlite"), join(fresh.result.backupPath, "company-project"));
  assert.deepEqual(backup.bootstrap().furnishing, hired.result.furnishing); backup.close();
  await process.stop(); process = worker(root);
  assert.deepEqual((await process.request("fresh-restart", "bootstrap")).result.furnishing, initial);
  await process.stop();
});

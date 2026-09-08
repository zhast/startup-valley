import assert from "node:assert/strict";
import { execFile, spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { copyFile, mkdir, mkdtemp, readFile, readdir, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";
import test from "node:test";
import type { FurnishingState } from "../src/furnishing.js";

// Test-only transparent transport: production worker, production SQLite, no
// fabricated replies. Delay acknowledgements to make pending-input checks
// deterministic; one scenario loses an already-committed response and exits.
const RELAY = String.raw`
import { spawn } from "node:child_process";
import { appendFileSync, openSync, closeSync } from "node:fs";
import { createInterface } from "node:readline";
const root = process.env.STARTUP_VALLEY_FURNISHING_ROOT;
const worker = spawn(process.execPath, [process.argv[2], "--data-dir", root], { stdio: ["pipe", "pipe", "pipe"] });
const record = (direction, message) => appendFileSync(root + "/transport.jsonl", JSON.stringify({ direction, message, pid: worker.pid }) + "\n");
record("worker", { relayPid: process.pid });
const methods = new Map();
const pending = new Set();
let dropping = false;
createInterface({ input: process.stdin }).on("line", (line) => {
  const request = JSON.parse(line);
  methods.set(request.id, request.method);
  record("request", request);
  worker.stdin.write(line + "\n");
}).on("close", () => worker.stdin.end());
createInterface({ input: worker.stdout }).on("line", (line) => {
  const message = JSON.parse(line);
  record("response", message);
  if (message.kind === "response" && message.ok && methods.get(message.id) === "furnishing.update") {
    if (process.env.STARTUP_VALLEY_FURNISHING_PHASE === "lost_ack") {
      let first = false;
      try { closeSync(openSync(root + "/ack-lost-once", "wx")); first = true; } catch (error) { if (error.code !== "EEXIST") throw error; }
      if (first) {
        dropping = true;
        record("dropped-committed-reply", message);
        worker.stdin.end();
        return;
      }
    }
    const timer = setTimeout(() => { pending.delete(timer); process.stdout.write(line + "\n"); }, 180);
    pending.add(timer);
  } else process.stdout.write(line + "\n");
});
worker.stderr.pipe(process.stderr);
worker.on("exit", (code) => {
  if (dropping) process.exit(86);
  process.exitCode = code ?? 1;
  process.stdin.destroy();
});
process.on("SIGTERM", () => { worker.kill("SIGTERM"); process.stdin.destroy(); });
`;

type TransportLine = { direction: string; message: Record<string, unknown>; pid: number };
const REPOSITORY = fileURLToPath(new URL("../../", import.meta.url));
const SOURCE_ROOTS = ["harness/src", "harness/dist", "harness/migrations", "contracts", "game/world", "game/actors", "game/ui", "game/data", "game/assets/runtime/office/furnishing-library"];

async function sourceHashes(): Promise<Record<string, string>> {
  const files = ["harness/test/furnishing-game.test.ts", "game/tests/test_furnishing_worker_ui.gd", "game/worker_client.gd", "game/project.godot"];
  async function walk(relative: string): Promise<void> {
    for (const entry of await readdir(join(REPOSITORY, relative), { withFileTypes: true })) {
      const path = `${relative}/${entry.name}`;
      if (entry.isDirectory()) await walk(path);
      else if (entry.isFile() && /\.(gd|tscn|ts|js|json|sql|png|tres)$/u.test(path)) files.push(path);
    }
  }
  for (const directory of SOURCE_ROOTS) await walk(directory);
  return Object.fromEntries(await Promise.all(files.sort().map(async (path) => [path, createHash("sha256").update(await readFile(join(REPOSITORY, path))).digest("hex")])));
}

async function retainEvidence(root: string): Promise<string> {
  const parent = join(REPOSITORY, "game/tests/output");
  await mkdir(parent, { recursive: true });
  const evidence = await mkdtemp(join(parent, `furnishing-worker-ui-${new Date().toISOString().replace(/[:.]/gu, "-")}-`));
  // Strict evidence allowlist: never retain the disposable company database,
  // project directory, shell launcher, credential state or transport executable.
  for (const entry of await readdir(root, { withFileTypes: true })) {
    if (entry.isFile() && (entry.name === "acceptance.json" || entry.name === "transport.jsonl" || entry.name === "edit.avi" || /^(edit|restart|lost_ack|final_restart)(?:-.*)?\.(log|json|png)$/u.test(entry.name))) {
      await copyFile(join(root, entry.name), join(evidence, entry.name));
    }
  }
  return evidence;
}

async function runGame(root: string, launcher: string, phase: string, expected?: FurnishingState): Promise<FurnishingState> {
  const movie = phase === "edit" && process.env.STARTUP_VALLEY_FURNISHING_MOVIE === "1";
  if (movie) assert.equal(process.env.STARTUP_VALLEY_FURNISHING_RENDER, "1", "Movie capture requires the native renderer");
  const child = spawn(process.env.GODOT_BINARY!, [
    ...(process.env.STARTUP_VALLEY_FURNISHING_RENDER === "1" ? [] : ["--headless"]), "--path", fileURLToPath(new URL("../../game", import.meta.url)),
    ...(movie ? ["--fixed-fps", "30", "--write-movie", join(root, "edit.avi")] : []),
    "--script", "res://tests/test_furnishing_worker_ui.gd",
  ], {
    env: {
      ...process.env, STARTUP_VALLEY_NODE: launcher,
      STARTUP_VALLEY_FURNISHING_TEST: "1", STARTUP_VALLEY_FURNISHING_ROOT: root,
      STARTUP_VALLEY_FURNISHING_PHASE: phase,
      STARTUP_VALLEY_FURNISHING_EXPECTED: expected ? JSON.stringify(expected) : "",
    },
    stdio: ["ignore", "pipe", "pipe"],
  });
  let output = "";
  child.stdout.on("data", (chunk) => { output += String(chunk); });
  child.stderr.on("data", (chunk) => { output += String(chunk); });
  const code = await new Promise<number | null>((resolve, reject) => {
    const timer = setTimeout(() => { child.kill(); reject(new Error(`${phase} timed out\n${output}`)); }, 60_000);
    child.once("error", (error) => { clearTimeout(timer); reject(error); });
    child.once("exit", (value) => { clearTimeout(timer); resolve(value); });
  });
  await writeFile(join(root, `${phase}.log`), output);
  assert.equal(code, 0, `${phase}\n${output}`);
  assert.doesNotMatch(output, /SCRIPT ERROR|ERROR:/u, output);
  assert.match(output, /FURNISHING WORKER UI PASS/u, output);
  if (movie) {
    const { stdout } = await promisify(execFile)("ffprobe", ["-v", "error", "-select_streams", "v:0", "-count_frames", "-show_entries", "stream=codec_name,width,height,r_frame_rate,avg_frame_rate,nb_frames,nb_read_frames", "-of", "json", join(root, "edit.avi")]);
    const probe = JSON.parse(stdout) as { streams: Array<{ width: number; height: number; avg_frame_rate: string; nb_read_frames: string }> };
    assert.equal(probe.streams[0]?.avg_frame_rate, "30/1");
    assert.equal(probe.streams[0]?.width, 1280);
    assert.equal(probe.streams[0]?.height, 720);
    assert.ok(Number(probe.streams[0]?.nb_read_frames) > 90, "Actual UI movie contains the tested multi-step flow");
    await writeFile(join(root, "edit-movie.json"), JSON.stringify(probe, null, 2) + "\n");
  }
  const snapshot = output.split("\n").find((line) => line.startsWith("FURNISHING_SNAPSHOT "));
  assert.ok(snapshot, `Missing durable snapshot\n${output}`);
  await writeFile(join(root, `${phase}-state.json`), snapshot.slice("FURNISHING_SNAPSHOT ".length) + "\n");
  return JSON.parse(snapshot.slice("FURNISHING_SNAPSHOT ".length)) as FurnishingState;
}

function inspectDatabase(root: string, expected: FurnishingState): void {
  const database = new DatabaseSync(join(root, "startup-valley.sqlite"), { readOnly: true });
  try {
    const row = database.prepare("SELECT * FROM furnishing_state WHERE id=1").get()!;
    assert.equal(row.version, expected.version);
    assert.equal(row.revision, expected.revision);
    assert.deepEqual(JSON.parse(String(row.placements_json)), expected.placements, "Godot projection equals on-disk SQLite, not a mock acknowledgement");
    assert.deepEqual(JSON.parse(String(row.last_valid_json)), { version: 1, placements: expected.placements });
    assert.equal(database.prepare("SELECT count(*) AS total FROM furnishing_inventory").get()!.total, expected.inventory.length);
    assert.equal(database.prepare("SELECT count(*) AS total FROM work_orders").get()!.total, 0, "Furnishing never starts paid work");
  } finally { database.close(); }
}

async function verifyNoWorkers(root: string): Promise<TransportLine[]> {
  const transcript = (await readFile(join(root, "transport.jsonl"), "utf8")).trim().split("\n").map((line) => JSON.parse(line) as TransportLine);
  const pids = [...new Set(transcript.filter((line) => line.direction === "worker").flatMap((line) => [line.pid, Number(line.message.relayPid)]))];
  const running = (pid: number): boolean => { try { process.kill(pid, 0); return true; } catch { return false; } };
  const deadline = Date.now() + 5_000;
  while (pids.some(running) && Date.now() < deadline) await new Promise((resolve) => setTimeout(resolve, 50));
  assert.deepEqual(pids.filter(running), [], "No tested worker or transport relay may remain alive");
  return transcript;
}

test("real Godot furnishing inputs persist through SQLite, full game restart and lost committed acknowledgement", { skip: !process.env.GODOT_BINARY, timeout: 180_000 }, async (context) => {
  const before = await sourceHashes();
  const root = await mkdtemp(join(tmpdir(), "startup-valley-furnishing-game-"));
  context.diagnostic(`Disposable evidence retained: ${root}`);
  const relay = join(root, "transport.mjs");
  const launcher = join(root, "node-isolated.sh");
  await writeFile(relay, RELAY);
  await writeFile(launcher, `#!/bin/sh\nexec ${JSON.stringify(process.execPath)} ${JSON.stringify(relay)} "$1"\n`, { mode: 0o700 });
  // Always audit handles, even after an assertion fails. A timeout terminates
  // Godot, causing stdin closure to shut down this isolated worker normally.
  context.after(async () => {
    try { await verifyNoWorkers(root); }
    catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
    }
  });
  const edited = await runGame(root, launcher, "edit");
  inspectDatabase(root, edited);
  const reopened = await runGame(root, launcher, "restart", edited);
  assert.deepEqual(reopened, edited, "An entire new Godot + worker process restores exactly the saved room and ownership");
  const recovered = await runGame(root, launcher, "lost_ack", edited);
  assert.equal(recovered.revision, edited.revision + 1, "A lost acknowledgement is one durable mutation");
  inspectDatabase(root, recovered);
  const final = await runGame(root, launcher, "final_restart", recovered);
  assert.deepEqual(final, recovered);
  const transcript = await verifyNoWorkers(root);
  const requests = transcript.filter((line) => line.direction === "request");
  assert.ok(requests.some((line) => line.message.method === "furnishing.update"));
  assert.ok(requests.every((line) => !["chat.send", "job.start", "milestone.evaluate", "credential.set"].includes(String(line.message.method))), "Provider and credential mutations are excluded");
  assert.equal(transcript.filter((line) => line.direction === "dropped-committed-reply").length, 1);
  const operations = requests.filter((line) => line.message.method === "furnishing.update");
  const unique = new Set(operations.map((line) => (line.message.params as Record<string, unknown>).operationId));
  assert.equal(operations.length, unique.size, "Rapid UI clicks dispatch one operation; bootstrap resolves the lost reply without another mutation");
  assert.equal(operations.length, recovered.revision, "Rejected previews and rapid presses never write an extra transaction");
  const lastActors = (operations.at(-1)!.message.params as { actorCells: Array<{ id: string; position: number[] }> }).actorCells;
  const founderPosition = lastActors.find((actor) => actor.id === "founder")!.position;
  const database = new DatabaseSync(join(root, "startup-valley.sqlite"), { readOnly: true });
  try {
    const player = JSON.parse(String(database.prepare("SELECT player_json FROM company_state WHERE id=1").get()!.player_json)) as { x: number; y: number };
    assert.deepEqual([player.x, player.y], founderPosition, "The actual actor position accompanying the last layout survives SQLite and restart exactly");
  } finally { database.close(); }
  const after = await sourceHashes();
  const sourceStable = JSON.stringify(before) === JSON.stringify(after);
  await writeFile(join(root, "acceptance.json"), JSON.stringify({
    result: sourceStable ? "pass" : "source-changed-during-run", providerFree: true, realGodot: true, realWorker: true,
    transport: "Production messages forwarded unchanged except delayed acknowledgements and one lost committed reply",
    phases: ["edit", "restart", "lost_ack", "final_restart"],
    mutations: operations.length, finalRevision: recovered.revision,
    workersStopped: true, nativeRenderer: process.env.STARTUP_VALLEY_FURNISHING_RENDER === "1",
    inputDriver: { method: "Input.parse_input_event through normal GUI hit-testing", nativeWindowUnfocusable: process.env.STARTUP_VALLEY_FURNISHING_RENDER === "1" ? true : null, nativeMousePassthrough: process.env.STARTUP_VALLEY_FURNISHING_RENDER === "1" ? true : null, osPointerWarped: false },
    recordedCommand: `GODOT_BINARY=${process.env.GODOT_BINARY} STARTUP_VALLEY_FURNISHING_RENDER=${process.env.STARTUP_VALLEY_FURNISHING_RENDER === "1" ? "1" : "0"} STARTUP_VALLEY_FURNISHING_MOVIE=${process.env.STARTUP_VALLEY_FURNISHING_MOVIE === "1" ? "1" : "0"} ./node_modules/.bin/tsx --test test/furnishing-game.test.ts`,
    workingDirectory: join(REPOSITORY, "harness"), nodeVersion: process.version,
    sourceStable, sourceBefore: before, sourceAfter: after,
  }, null, 2) + "\n");
  context.diagnostic(`Portable verification evidence: ${await retainEvidence(root)}`);
  assert.ok(sourceStable, "Source files changed during the run; repeat before calling this checkpoint accepted");
});

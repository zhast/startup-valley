import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { mkdtemp, writeFile, readFile, readdir } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";
import test from "node:test";
import { GameDatabase } from "../src/database.js";

test("company protocol saves, advances idempotently, backs up New Company and handles duplicate requests", async (t) => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-company-protocol-"));
  const child = spawn(process.execPath, ["dist/main.js", "--data-dir", root], { cwd: new URL("..", import.meta.url), stdio: ["pipe", "pipe", "pipe"] });
  t.after(() => { child.kill("SIGTERM"); });
  const responses = new Map<string, (value: any) => void>();
  const lines = createInterface({ input: child.stdout });
  lines.on("line", (line) => { const value = JSON.parse(line); if (value.id) responses.get(value.id)?.(value); });
  const request = (id: string, method: string, params: object = {}) => new Promise<any>((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timed out: ${method}`)), 5000);
    responses.set(id, (value) => { clearTimeout(timer); responses.delete(id); resolve(value); });
    child.stdin.write(JSON.stringify({ kind: "request", id, method, params }) + "\n");
  });
  assert.equal((await request("boot", "bootstrap")).result.employees.length, 0);
  assert.equal((await request("hire", "hiring.complete", { employeeId: "mira" })).ok, true);
  assert.equal((await request("hire2", "hiring.complete", { employeeId: "mira" })).result.employees.length, 1);
  assert.equal((await request("save", "game.save", { x: 325.5, y: 460.5, movementSeen: true, attentionEmployeeId: "mira", effectsVolume: 0.25, ambienceVolume: 0 })).ok, true);
  const saved = (await request("boot2", "bootstrap")).result.journey.player;
  assert.equal(saved.x, 325.5); assert.equal(saved.attentionEmployeeId, "mira");
  assert.equal((await request("end", "day.end", { day: 1 })).result.clock.day, 2);
  assert.equal((await request("end2", "day.end", { day: 1 })).result.clock.day, 2);
  assert.equal((await request("unconfirmed", "game.new")).ok, false);
  await writeFile(join(root, "company-project", "precious-note.md"), "Keep my company files.");
  const fresh = await request("new-company", "game.new", { confirmed: true });
  assert.equal(fresh.ok, true);
  assert.equal(fresh.result.employees.length, 0);
  assert.equal(fresh.result.clock.day, 1);
  assert.equal(await readFile(join(fresh.result.backupPath, "company-project", "precious-note.md"), "utf8"), "Keep my company files.");
  const duplicate = await request("new-company", "game.new", { confirmed: true });
  assert.equal(duplicate.result.backupPath, fresh.result.backupPath);
  assert.equal((await readdir(join(root, "backups"))).length, 1);
  assert.equal((await request("new-company", "game.new", { confirmed: false })).ok, false);
  const backup = new GameDatabase(join(fresh.result.backupPath, "startup-valley.sqlite"), join(fresh.result.backupPath, "company-project"));
  assert.equal(backup.bootstrap().employees.length, 1);
  assert.equal(backup.journey.state().player.x, 325.5);
  assert.equal(backup.clockState().day, 2);
  backup.close();
  child.stdin.end();
  await once(child, "exit");
  lines.close();
});

test("distinct simultaneous New Company requests reserve one reset and reject writes during replacement", async (t) => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-concurrent-reset-"));
  const child = spawn(process.execPath, ["dist/main.js", "--data-dir", root], {
    cwd: new URL("..", import.meta.url), stdio: ["pipe", "pipe", "pipe"],
    env: { ...process.env, STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS: "1", STARTUP_VALLEY_FAKE_PROVIDER: "0" },
  });
  t.after(() => { if (child.exitCode === null) child.kill("SIGTERM"); });
  let stderr = "";
  child.stderr.on("data", (chunk) => { stderr += String(chunk); });
  const responses = new Map<string, (value: any) => void>();
  const lines = createInterface({ input: child.stdout });
  t.after(() => lines.close());
  lines.on("line", (line) => {
    const value = JSON.parse(line);
    if (value.id) responses.get(value.id)?.(value);
  });
  const batch = (requests: Array<{ id: string; method: string; params: object }>) => {
    const pending = requests.map(({ id, method }) => new Promise<any>((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error(`Timed out ${method}: ${stderr}`)), 8000);
      responses.set(id, (value) => { clearTimeout(timer); responses.delete(id); resolve(value); });
    }));
    // One write intentionally delivers every distinct request before filesystem
    // preparation can complete; request-ID deduplication cannot hide this race.
    child.stdin.write(requests.map((request) => JSON.stringify({ kind: "request", ...request })).join("\n") + "\n");
    return Promise.all(pending);
  };
  const request = async (id: string, method: string, params: object = {}) => (await batch([{ id, method, params }]))[0];
  assert.equal((await request("save-original", "game.save", { x: 345, y: 510 })).ok, true);
  await request("original-day1", "day.end", { day: 1 });
  await request("original-day2", "day.end", { day: 2 });
  await writeFile(join(root, "company-project", "original.txt"), "Preserve the old company.");

  const [nativeRead, first, second, during] = await batch([
    { id: "native-read-before-reset", method: "chat.history", params: { employeeId: "mira" } },
    { id: "reset-first", method: "game.new", params: { confirmed: true } },
    { id: "reset-second", method: "game.new", params: { confirmed: true } },
    { id: "save-during-reset", method: "game.save", params: { x: 900, y: 600 } },
  ]);
  assert.equal(first.ok, true, first.error);
  assert.equal(nativeRead.ok, false, "native fallback must recheck after yielding to the reset");
  assert.match(nativeRead.error, /New company is being prepared/u);
  assert.equal(second.ok, false);
  assert.match(second.error, /New company is being prepared/u);
  assert.equal(during.ok, false, "reset reservation must precede shared writes");
  assert.match(during.error, /New company is being prepared/u);
  assert.equal((await readdir(join(root, "backups"))).length, 1);
  assert.equal(await readFile(join(first.result.backupPath, "company-project", "original.txt"), "utf8"), "Preserve the old company.");
  const backup = new GameDatabase(join(first.result.backupPath, "startup-valley.sqlite"), join(first.result.backupPath, "company-project"));
  try {
    assert.equal(backup.journey.state().player.x, 345, "the rejected write must not enter the backup");
    assert.equal(backup.clockState().day, 3);
  } finally { backup.close(); }
  assert.equal((await request("new-day", "day.end", { day: 1 })).result.clock.day, 2);
  const exited = once(child, "exit");
  child.stdin.end();
  assert.equal((await exited)[0], 0);
  const reopened = new GameDatabase(join(root, "startup-valley.sqlite"), join(root, "company-project"));
  try {
    assert.equal(reopened.clockState().day, 2);
    assert.notEqual(reopened.journey.state().player.x, 900);
    assert.equal(reopened.bootstrap().employees.length, 0);
  } finally { reopened.close(); }
});

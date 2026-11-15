import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";
import { DatabaseSync } from "node:sqlite";
import test from "node:test";
import { createBrowserRuntime, type BrowserRuntimeOptions } from "../src/browser-runtime.js";
import { GameDatabase, readMigrations } from "../src/database.js";
import { furnishingHash, readGeometryData } from "../src/furnishing.js";
import { readContractSchemas } from "../src/validation.js";
import type { ProtocolResponse } from "../src/types.js";

const assets = { migrations: readMigrations(), geometryData: readGeometryData(), schemas: readContractSchemas(), hash: furnishingHash };
const request = (id: string, method: string, params: object = {}) => ({ kind: "request", id, method, params });
function normalized(response: ProtocolResponse): ProtocolResponse {
  const copy = structuredClone(response);
  const result = copy.result as { project?: { rootPath: string } } | undefined;
  if (result?.project) result.project.rootPath = "<platform project root>";
  return copy;
}

test("portable runtime matches native stdio through shipping, sales, upgrades, furnishing and reopen", async (t) => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-browser-parity-"));
  const path = join(root, "browser.sqlite");
  let runtime = createBrowserRuntime({ ...assets, database: new DatabaseSync(path) });
  t.after(async () => { await runtime.close(); });
  const child = spawn(process.execPath, ["dist/main.js", "--data-dir", join(root, "native")], {
    cwd: new URL("..", import.meta.url), stdio: ["pipe", "pipe", "pipe"],
    env: { ...process.env, STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS: "1", STARTUP_VALLEY_FAKE_PROVIDER: "0" },
  });
  t.after(() => { if (child.exitCode === null) child.kill("SIGTERM"); });
  const responses = new Map<string, (value: ProtocolResponse) => void>();
  const lines = createInterface({ input: child.stdout });
  lines.on("line", (line) => {
    const value = JSON.parse(line) as ProtocolResponse;
    if (value.kind === "response") responses.get(value.id)?.(value);
  });
  const nativeRequest = (raw: ReturnType<typeof request>) => new Promise<ProtocolResponse>((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Native request timed out: ${raw.method}`)), 8000);
    responses.set(raw.id, (value) => { clearTimeout(timer); responses.delete(raw.id); resolve(value); });
    child.stdin.write(`${JSON.stringify(raw)}\n`);
  });
  const both = async (id: string, method: string, params: object = {}) => {
    const raw = request(id, method, params);
    const [browser, native] = await Promise.all([runtime.handleRequest(raw), nativeRequest(raw)]);
    assert.deepEqual(normalized(browser), normalized(native), `${id}: ${method}`);
    return browser;
  };
  const opening = await both("opening", "bootstrap");
  const furnishing = (opening.result as any).furnishing;
  await both("furnish", "furnishing.update", { operationId: "same-layout", expectedRevision: 0, placements: furnishing.placements });
  await both("furnish-retry", "furnishing.update", { operationId: "same-layout", expectedRevision: 0, placements: furnishing.placements });
  assert.equal((await both("start", "tycoon.start", { topicId: "crypto", typeId: "newsletter", staffIds: ["founder"] })).ok, true);
  await both("day1", "day.end", { day: 1 });
  await both("day1", "day.end", { day: 1 });
  assert.equal((await both("day1", "day.end", { day: 2 })).ok, false);
  await both("day2", "day.end", { day: 2 });
  assert.equal((await both("release", "tycoon.release", { productId: "p1" })).ok, true);
  await both("research", "tycoon.research", { kind: "topic", id: "sneakers" });
  await both("day3", "day.end", { day: 3 });
  const earned = await both("day4", "day.end", { day: 4 });
  assert.equal((earned.result as any).journey.company.cashCents, 33300);
  await both("upgrade", "tycoon.buyUpgrade", { id: "standing_desk" });
  await both("hire", "hiring.complete", { employeeId: "mira" });
  await both("save", "game.save", { x: 600, y: 500, movementSeen: true, architectureTheme: "loft" });
  const before = await both("before-close", "bootstrap");
  await runtime.close();
  runtime = createBrowserRuntime({ ...assets, database: new DatabaseSync(path) });
  const exited = once(child, "exit");
  child.stdin.end();
  assert.equal((await exited)[0], 0);
  const nativeReopened = new GameDatabase(join(root, "native", "startup-valley.sqlite"), join(root, "native", "company-project"));
  try {
    const after = await runtime.handleRequest(request("after-reopen", "bootstrap"));
    assert.deepEqual(normalized(after), normalized({ kind: "response", id: "after-reopen", ok: true, result: nativeReopened.bootstrap() }));
    assert.deepEqual((after.result as any).journey.company, (before.result as any).journey.company);
    assert.deepEqual((after.result as any).journey.player, (before.result as any).journey.player);
    assert.deepEqual((after.result as any).furnishing, (before.result as any).furnishing);
  } finally { nativeReopened.close(); }
});

test("portable runtime validates envelopes, deduplicates queued writes and disables provider work", async () => {
  const runtime = createBrowserRuntime({ ...assets, database: new DatabaseSync(":memory:") });
  try {
    assert.equal((await runtime.handleRequest("{")).ok, false);
    assert.equal((await runtime.handleRequest(request("bad", "game.save", { x: -1, y: 0 }))).ok, false);
    assert.equal((await runtime.handleRequest(request("unknown", "not-a-method"))).ok, false);
    const status = await runtime.handleRequest(request("status", "credential.status"));
    assert.equal((status.result as any).configured, false);
    assert.equal((await runtime.handleRequest(request("chat", "chat.send", { employeeId: "mira", message: "Hello" }))).ok, false);
    const day = request("same", "day.end", { day: 1 });
    const [first, second] = await Promise.all([runtime.handleRequest(day), runtime.handleRequest(day)]);
    assert.equal(first.ok, true);
    assert.deepEqual(first, second);
    const collision = await runtime.handleRequest(request("same", "day.end", { day: 2 }));
    assert.match(collision.error ?? "", /different action/u);
    const state = await runtime.handleRequest(request("state", "bootstrap"));
    assert.equal((state.result as any).clock.day, 2);
    assert.equal((state.result as any).dailySpend, 0);
  } finally { await runtime.close(); }
  const closed = await runtime.handleRequest(request("after-close", "bootstrap"));
  assert.match(closed.error ?? "", /closed/u);
});

test("failed candidate reset leaves the old company usable; successful reset initializes a fresh save", async () => {
  let fail = true;
  const resetDatabase: BrowserRuntimeOptions["resetDatabase"] = async (current, initialize) => {
    const candidate = new DatabaseSync(":memory:");
    try { initialize(candidate); } catch (error) { candidate.close(); throw error; }
    if (fail) { candidate.close(); throw new Error("Simulated storage failure"); }
    current.close();
    return candidate;
  };
  const runtime = createBrowserRuntime({ ...assets, database: new DatabaseSync(":memory:"), resetDatabase });
  try {
    await runtime.handleRequest(request("save", "game.save", { x: 600, y: 500 }));
    const before = await runtime.handleRequest(request("before", "bootstrap"));
    const rejected = await runtime.handleRequest(request("reset-fails", "game.new", { confirmed: true }));
    assert.match(rejected.error ?? "", /Simulated storage failure/u);
    assert.deepEqual((await runtime.handleRequest(request("restored", "bootstrap"))).result, before.result);
    fail = false;
    const reset = await runtime.handleRequest(request("reset-works", "game.new", { confirmed: true }));
    assert.equal(reset.ok, true, reset.error);
    assert.notDeepEqual((reset.result as any).journey.player, (before.result as any).journey.player);
    assert.equal((reset.result as any).clock.day, 1);
    assert.equal((await runtime.handleRequest(request("next-day", "day.end", { day: 1 }))).ok, true);
  } finally { await runtime.close(); }
});

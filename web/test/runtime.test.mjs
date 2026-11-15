import assert from "node:assert/strict";
import { createServer } from "node:http";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, extname, resolve } from "node:path";
import { once } from "node:events";
import { DatabaseSync } from "node:sqlite";
import test from "node:test";
import { chromium } from "playwright-core";
import { createBrowserRuntime } from "../../harness/dist/browser-runtime.js";
import { readMigrations } from "../../harness/dist/database.js";
import { furnishingHash, readGeometryData } from "../../harness/dist/furnishing.js";
import { readContractSchemas } from "../../harness/dist/validation.js";

const dist = resolve(import.meta.dirname, "../dist");
const executablePath = process.env.CHROME_PATH || (process.platform === "darwin" ? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" : "/usr/bin/google-chrome");

function request(page, id, method, params = {}) {
  return page.evaluate(({ id, method, params }) => new Promise((resolve, reject) => {
    const bridge = window.StartupValleyWorker;
    const timer = setTimeout(() => { unsubscribe(); reject(new Error(`Timed out: ${method}`)); }, 8000);
    const unsubscribe = bridge.onMessage((json) => {
      const response = JSON.parse(json);
      if (response.id !== id) return;
      clearTimeout(timer); unsubscribe(); resolve(response);
    });
    bridge.request(JSON.stringify({ kind: "request", id, method, params }));
  }), { id, method, params });
}

async function ready(page, url) {
  await page.goto(url);
  await page.waitForFunction(() => ["ready", "failed"].includes(window.StartupValleyWorker?.diagnostics().state));
  const diagnostics = await page.evaluate(() => window.StartupValleyWorker.diagnostics());
  assert.equal(diagnostics.state, "ready", diagnostics.error);
  assert.equal(diagnostics.storage, "opfs-sahpool");
}

test("real WASM/OPFS preserves gameplay, rejects a second owner, and reports failed downloads", { timeout: 120_000 }, async (t) => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-web-test-"));
  const server = createServer(async (req, res) => {
    const path = decodeURIComponent(new URL(req.url, "http://localhost").pathname);
    if (!path.startsWith("/nested/web/") || path.includes("..")) { res.writeHead(404).end(); return; }
    try {
      const filename = join(dist, path.slice("/nested/web/".length) || "index.html");
      res.setHeader("Content-Type", { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm" }[extname(filename)] || "application/octet-stream");
      res.end(await readFile(filename));
    } catch { res.writeHead(404).end(); }
  });
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  const origin = `http://127.0.0.1:${server.address().port}`;
  const url = `${origin}/nested/web/index.html`;
  let context;
  const consoleErrors = [];
  const openBrowser = async () => {
    context = await chromium.launchPersistentContext(join(root, "profile"), { executablePath, headless: true });
    await context.route("**/*", (route) => route.request().url().startsWith(origin) ? route.continue() : route.abort());
    context.on("page", (page) => page.on("pageerror", (error) => consoleErrors.push(error.message)));
    return context.newPage();
  };
  const openNative = () => createBrowserRuntime({
    database: new DatabaseSync(join(root, "native.sqlite")), migrations: readMigrations(),
    geometryData: readGeometryData(), schemas: readContractSchemas(), hash: furnishingHash,
  });
  let native = openNative();
  t.after(async () => { await context?.close(); await native.close(); server.close(); await rm(root, { recursive: true, force: true }); });
  let page = await openBrowser();
  await ready(page, url);
  const both = async (id, method, params = {}) => {
    const actual = await request(page, id, method, params);
    // Compare the JSON transport value, not native SQLite's null prototypes.
    const expected = JSON.parse(JSON.stringify(await native.handleRequest({ kind: "request", id, method, params })));
    assert.deepEqual(actual, expected, `${method} must match native SQLite`);
    return actual;
  };
  assert.equal((await both("health", "health")).result.offline, true);
  const opening = await both("opening", "bootstrap");
  const placement = { operationId: "web-plant", expectedRevision: opening.result.furnishing.revision,
    placements: { ...opening.result.furnishing.placements, "decor-broadleaf_planter": { grid: [24, 8], facing: "south" } } };
  assert.equal((await both("furnish", "furnishing.update", placement)).ok, true);
  assert.equal((await both("start", "tycoon.start", { topicId: "crypto", typeId: "newsletter", staffIds: ["founder"] })).ok, true);
  await both("day1", "day.end", { day: 1 });
  await both("day1", "day.end", { day: 1 });
  assert.equal((await both("day1", "day.end", { day: 2 })).ok, false);
  await both("day2", "day.end", { day: 2 });
  assert.equal((await both("release", "tycoon.release", { productId: "p1" })).ok, true);
  await both("research", "tycoon.research", { kind: "topic", id: "sneakers" });
  await both("day3", "day.end", { day: 3 });
  await both("day4", "day.end", { day: 4 });
  await both("upgrade", "tycoon.buyUpgrade", { id: "standing_desk" });
  await both("hire", "hiring.complete", { employeeId: "mira" });
  await both("save", "game.save", { x: 600, y: 500, movementSeen: true, architectureTheme: "loft" });
  const before = (await both("before", "bootstrap")).result;

  const other = await context.newPage();
  await other.goto(url);
  await other.waitForFunction(() => window.StartupValleyWorker?.diagnostics().state === "failed");
  assert.match(await other.locator("#status").innerText(), /already open in another tab/);
  await other.close();
  assert.deepEqual((await request(page, "after-other", "bootstrap")).result, before);
  await page.reload();
  await page.waitForFunction(() => window.StartupValleyWorker?.diagnostics().state === "ready");
  await native.close();
  native = openNative();
  const reopened = JSON.parse(JSON.stringify((await native.handleRequest({ kind: "request", id: "native-reopened", method: "bootstrap", params: {} })).result));
  assert.deepEqual((await request(page, "after-reload", "bootstrap")).result, reopened);
  await context.close();
  page = await openBrowser();
  await ready(page, url);
  assert.deepEqual((await request(page, "after-browser-restart", "bootstrap")).result, reopened);
  assert.equal((await request(page, "durable-furnish-retry", "furnishing.update", placement)).result.replayed, true);
  assert.equal((await request(page, "provider", "chat.send", { employeeId: "mira", message: "Hello" })).ok, false);
  assert.equal((await request(page, "reset-unconfirmed", "game.new", { confirmed: false })).ok, false);
  const reset = await request(page, "reset", "game.new", { confirmed: true });
  assert.equal(reset.ok, true, reset.error);
  assert.equal(reset.result.clock.day, 1);
  assert.equal((await request(page, "new-day", "day.end", { day: 1 })).ok, true);
  await page.evaluate(async () => { await window.StartupValleyWorker.stop(); await window.StartupValleyWorker.start(); });
  assert.equal((await request(page, "reopened-new-company", "bootstrap")).result.clock.day, 2);
  // Simulate the durable state left by a hard stop during save replacement:
  // the new primary exists, the old backup exists, and commit marker remains.
  await page.evaluate(async () => {
    await window.StartupValleyWorker.stop();
    const root = await navigator.storage.getDirectory();
    const file = await root.getFileHandle(".startup-valley-reset-pending", { create: true });
    const stream = await file.createWritable();
    await stream.write("reset-pending-v1");
    await stream.close();
    await window.StartupValleyWorker.start();
  });
  assert.deepEqual((await request(page, "recovered-interrupted-reset", "bootstrap")).result, reopened);
  await context.close();
  page = await openBrowser();
  await context.route("**/sqlite3-*.wasm", (route) => route.abort("failed"));
  await page.goto(url);
  await page.waitForFunction(() => window.StartupValleyWorker?.diagnostics().state === "failed");
  const failedDownload = await page.locator("#status").innerText();
  assert.match(failedDownload, /game simulation files could not be loaded.*Check your connection/);
  assert.doesNotMatch(failedDownload, /ASSERTIONS|XMLHttpRequest|http:\/\//);
  assert.deepEqual(consoleErrors, []);
});

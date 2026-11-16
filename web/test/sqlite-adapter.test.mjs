import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import ts from "typescript";

// Test the real adapter without requiring Chromium or a Node TS runtime flag.
const source = await readFile(new URL("../src/sqlite-adapter.ts", import.meta.url), "utf8");
const javascript = ts.transpileModule(source, { compilerOptions: { target: ts.ScriptTarget.ES2022, module: ts.ModuleKind.ESNext } }).outputText;
const { WasmDatabase, resetDatabase, openDatabase, SAVE_PATH } = await import(`data:text/javascript;base64,${Buffer.from(javascript).toString("base64")}`);

function fixture(t, failAt, cleanupFails = false, abortFails = false) {
  const files = new Map([[SAVE_PATH, 1]]);
  let marker = false;
  let aborted = false;
  let failRemoval = cleanupFails;
  class Handle {
    constructor(path) { this.path = path; }
    exec(sql) { if (sql === "advance") files.set(this.path, 2); }
    close() {}
    selectValue() { return "ok"; }
    prepare(sql) { return { bind() {}, step: () => { this.exec(sql); return true; }, get: () => ({ quick_check: "ok" }), finalize() {} }; }
  }
  const pool = {
    OpfsSAHPoolDb: Handle,
    getFileNames: () => [...files.keys()],
    exportFile: (path) => files.get(path),
    importDb: (path, value) => files.set(path, value),
    unlink: (path) => files.delete(path),
  };
  const fail = (stage) => { if (failAt === stage) throw new DOMException(stage, "QuotaExceededError"); };
  const root = {
    async getFileHandle(_name, options) {
      if (options?.create) {
        marker = true; // Also exercise creation that leaves a file before failing.
        fail("create");
      }
      if (!marker) throw new DOMException("missing", "NotFoundError");
      return { async createWritable() {
        fail("writable");
        return {
          async write() { fail("write"); },
          async close() { fail("close"); },
          async abort() { aborted = true; if (abortFails) throw new Error("abort failed"); },
        };
      } };
    },
    async removeEntry() {
      if (failRemoval) throw new DOMException("cannot remove", "UnknownError");
      marker = false;
    },
  };
  const descriptor = Object.getOwnPropertyDescriptor(globalThis, "navigator");
  Object.defineProperty(globalThis, "navigator", { configurable: true, value: { storage: { getDirectory: async () => root } } });
  t.after(() => descriptor ? Object.defineProperty(globalThis, "navigator", descriptor) : delete globalThis.navigator);
  const current = new WasmDatabase(new Handle(SAVE_PATH));
  return { files, pool, current, marker: () => marker, aborted: () => aborted,
    allowCleanup: () => { failRemoval = false; },
    reset: () => resetDatabase(pool, current, () => files.set("/startup-valley-new-company.sqlite3", 0)) };
}

for (const stage of ["create", "writable", "write", "close"]) {
  test(`reset marker ${stage} failure cannot roll back later gameplay`, async (t) => {
    const f = fixture(t, stage);
    await assert.rejects(f.reset(), { name: "QuotaExceededError" });
    assert.equal(f.marker(), false);
    assert.equal(f.aborted(), stage === "write" || stage === "close");
    f.current.exec("advance");
    await openDatabase(f.pool);
    assert.equal(f.files.get(SAVE_PATH), 2);
  });
}

for (const stage of ["create", "writable", "write", "close", undefined]) {
  test(`failed marker cleanup blocks all later writes (${stage ?? "replacement"})`, async (t) => {
    const f = fixture(t, stage, true);
    const preparedBeforeFailure = f.current.prepare("advance");
    await assert.rejects(f.reset(), /[Rr]eopen/);
    assert.equal(f.marker(), true);
    assert.throws(() => f.current.exec("advance"), /[Rr]eopen/);
    assert.throws(() => f.current.prepare("advance"), /[Rr]eopen/);
    assert.throws(() => preparedBeforeFailure.run(), /[Rr]eopen/);
    assert.equal(f.files.get(SAVE_PATH), 1);
    f.allowCleanup();
    await openDatabase(f.pool);
    assert.equal(f.marker(), false);
    assert.equal(f.files.get(SAVE_PATH), 1);
  });
}

test("failed writer abort blocks progress until startup recovery", async (t) => {
  const f = fixture(t, "write", false, true);
  await assert.rejects(f.reset(), /[Rr]eopen/);
  assert.equal(f.aborted(), true);
  assert.equal(f.marker(), true);
  assert.throws(() => f.current.exec("advance"), /[Rr]eopen/);
  assert.equal(f.files.get(SAVE_PATH), 1);
  await openDatabase(f.pool);
  assert.equal(f.files.get(SAVE_PATH), 1);
});

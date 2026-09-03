import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

test("production Godot reaches title with real worker and a disposable founder-only save", { skip: !process.env.GODOT_BINARY }, async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-live-startup-"));
  const launcher = join(root, "node-isolated.sh");
  await writeFile(launcher, `#!/bin/sh\nexec ${JSON.stringify(process.execPath)} "$1" --data-dir ${JSON.stringify(root)}\n`, { mode: 0o700 });
  const child = spawn(process.env.GODOT_BINARY!, ["--headless", "--path", fileURLToPath(new URL("../../game", import.meta.url)), "--script", "res://tests/test_live_startup.gd"], { env: { ...process.env, STARTUP_VALLEY_NODE: launcher, STARTUP_VALLEY_STARTUP_TEST: "1" }, stdio: ["ignore", "pipe", "pipe"] });
  let output = "";
  child.stdout.on("data", (chunk) => { output += String(chunk); });
  child.stderr.on("data", (chunk) => { output += String(chunk); });
  const code = await new Promise<number | null>((resolve, reject) => {
    const timer = setTimeout(() => { child.kill(); reject(new Error(`Live startup timed out\n${output}`)); }, 25000);
    child.once("error", (error) => { clearTimeout(timer); reject(error); });
    child.once("exit", (value) => { clearTimeout(timer); resolve(value); });
  });
  assert.equal(code, 0, output);
  assert.match(output, /LIVE STARTUP PASS/u);
  assert.doesNotMatch(output, /SCRIPT ERROR|ERROR:/u);
});

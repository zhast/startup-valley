import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";
import { DatabaseSync } from "node:sqlite";
import test from "node:test";

test("closing stdin blocks fake in-flight work and leaves no worker child", async () => {
  const dataRoot = await mkdtemp(join(tmpdir(), "startup-valley-shutdown-"));
  const child = spawn(process.execPath, ["test/fixtures/inflight-worker.mjs", dataRoot], {
    cwd: new URL("..", import.meta.url),
    stdio: ["pipe", "pipe", "pipe"],
  });
  const errors: Buffer[] = [];
  child.stderr.on("data", (chunk: Buffer) => errors.push(chunk));
  const lines = createInterface({ input: child.stdout });
  await new Promise<void>((resolve, reject) => {
    lines.once("line", (line) => line === "READY" ? resolve() : reject(new Error(`Unexpected child output: ${line}`)));
    child.once("error", reject);
  });

  child.stdin.end();
  const exitCode = await new Promise<number | null>((resolve, reject) => {
    const timeout = setTimeout(() => {
      child.kill("SIGKILL");
      reject(new Error("Fake in-flight worker did not exit after stdin closed"));
    }, 5000);
    child.once("exit", (code) => {
      clearTimeout(timeout);
      resolve(code);
    });
  });
  assert.equal(exitCode, 0, Buffer.concat(errors).toString("utf8"));

  const database = new DatabaseSync(join(dataRoot, "game.sqlite"));
  const row = database.prepare("SELECT status FROM work_orders WHERE id = 'fake-inflight'").get() as
    | { status: string }
    | undefined;
  database.close();
  assert.equal(row?.status, "blocked");
});

import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";
import test from "node:test";

test("stdio JSONL daemon completes health and bootstrap handshake", async () => {
  const dataRoot = await mkdtemp(join(tmpdir(), "startup-valley-daemon-"));
  const child = spawn(process.execPath, ["dist/main.js", "--data-dir", dataRoot], {
    cwd: new URL("..", import.meta.url),
    stdio: ["pipe", "pipe", "pipe"],
  });
  const lines = createInterface({ input: child.stdout });
  const responses = new Map<string, (value: Record<string, unknown>) => void>();
  lines.on("line", (line) => {
    const message = JSON.parse(line) as { id?: string } & Record<string, unknown>;
    if (message.id) responses.get(message.id)?.(message);
  });
  const request = async (id: string, method: string): Promise<Record<string, unknown>> => {
    const response = new Promise<Record<string, unknown>>((resolve) => responses.set(id, resolve));
    child.stdin.write(`${JSON.stringify({ kind: "request", id, method, params: {} })}\n`);
    return response;
  };
  const health = await request("health", "health");
  const bootstrap = await request("bootstrap", "bootstrap");
  assert.equal(health.ok, true);
  assert.equal((health.result as { maxConcurrentJobs: number }).maxConcurrentJobs, 1);
  assert.equal((bootstrap.result as { employees: unknown[] }).employees.length, 2);
  child.stdin.end();
  await new Promise<void>((resolve, reject) => {
    child.once("exit", (code) => (code === 0 ? resolve() : reject(new Error(`worker exited ${code}`))));
  });
});

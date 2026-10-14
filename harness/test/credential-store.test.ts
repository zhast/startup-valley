import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";
import test from "node:test";

import { KeychainCredentialStore, MemorySecretBackend, normalizeKeychainValue } from "../src/credential-store.js";
import {
  OPENROUTER_MODEL_ID,
  XAI_CLIENT_ID,
  XAI_MODEL_ID,
  oauthFailureMessage,
  parseGrokCliAuth,
  redactSecret,
  selectModelCredential,
} from "../src/grok-auth.js";

const ACCESS = "test-access-token-aaaa";
const REFRESH = "test-refresh-token-bbbb";
const NEXT_ACCESS = "test-access-token-cccc";
const NEXT_REFRESH = "test-refresh-token-dddd";
const OPENROUTER = "sk-or-test-key-0000000000";

test("missing keychain values never appear configured", () => {
  assert.equal(normalizeKeychainValue(null), undefined);
  assert.equal(normalizeKeychainValue(undefined), undefined);
  assert.equal(normalizeKeychainValue(""), undefined);
  assert.equal(normalizeKeychainValue("sk-or-example"), "sk-or-example");
});

test("provider selection prefers Grok grok-4.6 and falls back to OpenRouter", () => {
  assert.equal(selectModelCredential({}), undefined);
  const grok = selectModelCredential({ xaiAccessToken: ACCESS, openRouterKey: OPENROUTER });
  assert.equal(grok?.provider, "xai");
  assert.equal(grok?.modelId, XAI_MODEL_ID);
  assert.equal(grok?.modelId, "grok-4.6");
  const openrouter = selectModelCredential({ openRouterKey: OPENROUTER });
  assert.equal(openrouter?.provider, "openrouter");
  assert.equal(openrouter?.modelId, OPENROUTER_MODEL_ID);
  assert.equal(redactSecret(`bearer ${ACCESS}`, ACCESS).includes(ACCESS), false);
});

test("Grok CLI auth parse keeps only the xAI session shape", () => {
  const parsed = parseGrokCliAuth({
    other: { key: "nope", refresh_token: REFRESH },
    [`https://auth.x.ai::${XAI_CLIENT_ID}`]: {
      key: ACCESS,
      refresh_token: REFRESH,
      expires_at: "2099-01-01T00:00:00.000Z",
      oidc_client_id: XAI_CLIENT_ID,
      email: "person@example.com",
    },
  });
  assert.equal(parsed?.secrets.access, ACCESS);
  assert.equal(parsed?.secrets.refresh, REFRESH);
  assert.equal(parseGrokCliAuth({ bad: { key: "short", refresh_token: "short" } }), undefined);
  const echoed = `token=${REFRESH}`;
  assert.equal(oauthFailureMessage("could not start", 400, { error: "invalid_request", error_description: echoed }).includes(REFRESH), false);
});

test("stored Grok login configures xAI and device-code completion never returns the token", async () => {
  const calls: string[] = [];
  const fetchImpl: typeof fetch = async (_input, init) => {
    const body = String(init?.body ?? "");
    calls.push(body.includes("device_code") ? "poll" : body.includes("refresh_token") ? "refresh" : "start");
    if (body.includes("grant_type=refresh_token")) {
      return jsonResponse({ error: "invalid_grant", refresh_token: REFRESH }, 400);
    }
    if (!body.includes("device_code=")) {
      return jsonResponse({
        device_code: "device-code-secret-value-0001",
        user_code: "ABCD-EFGH",
        verification_uri: "https://auth.x.ai/device",
        verification_uri_complete: "https://evil.example/phish",
        expires_in: 600,
        interval: 2,
      });
    }
    if (calls.filter((call) => call === "poll").length === 1) return jsonResponse({ error: "authorization_pending" }, 400);
    return jsonResponse({ access_token: ACCESS, refresh_token: REFRESH, expires_in: 3600 });
  };
  const backend = new MemorySecretBackend();
  const store = new KeychainCredentialStore({ backend, grokAuthPath: null, fetchImpl, now: () => 1_000 });
  assert.equal((await store.status()).configured, false);
  const started = await store.startGrokLogin();
  assert.equal(started.userCode, "ABCD-EFGH");
  assert.equal(started.verificationUri, "https://auth.x.ai/device");
  assert.equal(JSON.stringify(started).includes("device-code-secret-value-0001"), false);
  const pending = await store.pollGrokLogin();
  assert.equal(pending.status, "pending");
  const done = await store.pollGrokLogin();
  assert.equal(done.status, "complete");
  if (done.status === "complete") {
    assert.equal(done.configured, true);
    assert.equal(done.provider, "xai");
    assert.equal(done.grokSource, "keychain");
    assert.equal(JSON.stringify(done).includes(ACCESS), false);
    assert.equal(JSON.stringify(done).includes(REFRESH), false);
  }
  const selected = await store.resolveModelCredential();
  assert.equal(selected?.provider, "xai");
  assert.equal(selected?.modelId, "grok-4.6");
  await store.setOpenRouterKey(OPENROUTER);
  const stillGrok = await store.resolveModelCredential();
  assert.equal(stillGrok?.provider, "xai");
  await store.logoutGrok();
  const afterLogout = await store.status();
  assert.equal(afterLogout.grokSignedIn, false);
  assert.equal(afterLogout.openRouterConfigured, true);
  assert.equal(afterLogout.provider, "openrouter");
  assert.equal((await store.resolveModelCredential())?.provider, "openrouter");
});

test("this computer's Grok login is reused until disconnect suppresses it", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-grok-"));
  const authPath = join(root, "auth.json");
  await writeCliAuth(authPath, ACCESS, REFRESH, Date.now() + 3_600_000);
  const store = new KeychainCredentialStore({ backend: new MemorySecretBackend(), grokAuthPath: authPath, fetchImpl: async () => {
    throw new Error("refresh should not run for a fresh login");
  } });
  const status = await store.status();
  assert.equal(status.configured, true);
  assert.equal(status.provider, "xai");
  assert.equal(status.grokSource, "grok-cli");
  assert.equal(JSON.stringify(status).includes(ACCESS), false);
  await store.logoutGrok();
  const hidden = await store.status();
  assert.equal(hidden.grokSignedIn, false);
  assert.equal(hidden.grokCliAvailable, true);
  assert.equal(hidden.configured, false);
  await store.useLocalGrok();
  assert.equal((await store.status()).grokSignedIn, true);
});

test("expired Grok CLI login refreshes without echoing the token", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-grok-refresh-"));
  const authPath = join(root, "auth.json");
  await writeCliAuth(authPath, ACCESS, REFRESH, Date.now() - 60_000);
  let sawRefresh = false;
  const fetchImpl: typeof fetch = async (_input, init) => {
    const body = String(init?.body ?? "");
    sawRefresh = body.includes("grant_type=refresh_token") && body.includes(encodeURIComponent(REFRESH));
    return jsonResponse({ access_token: NEXT_ACCESS, refresh_token: NEXT_REFRESH, expires_in: 3600 });
  };
  const store = new KeychainCredentialStore({ backend: new MemorySecretBackend(), grokAuthPath: authPath, fetchImpl });
  const resolved = await store.resolveModelCredential();
  assert.equal(sawRefresh, true);
  assert.equal(resolved?.apiKey, NEXT_ACCESS);
  assert.equal(resolved?.modelId, XAI_MODEL_ID);
  const rewritten = await readFile(authPath, "utf8");
  assert.equal(rewritten.includes(NEXT_ACCESS), true);
  assert.equal(rewritten.includes(ACCESS), false);
  const failed = new KeychainCredentialStore({
    backend: new MemorySecretBackend(),
    grokAuthPath: authPath,
    fetchImpl: async () => jsonResponse({ error: "invalid_grant", error_description: NEXT_REFRESH }, 401),
    now: () => Date.now() + 86_400_000,
  });
  await assert.rejects(failed.resolveModelCredential(), (error: unknown) => {
    const message = error instanceof Error ? error.message : "";
    assert.equal(message, "Grok login expired. Sign in with Grok again.");
    assert.equal(message.includes(NEXT_REFRESH), false);
    assert.equal(message.includes(NEXT_ACCESS), false);
    return true;
  });
});

test("credential protocol configures Grok from a local file and can ignore host credentials", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-grok-rpc-"));
  const authPath = join(root, "auth.json");
  const secretPath = join(root, "secrets.json");
  await writeCliAuth(authPath, ACCESS, REFRESH, Date.now() + 3_600_000);
  const signedIn = await requestCredentialStatus({
    ...cleanEnv(),
    STARTUP_VALLEY_GROK_AUTH_FILE: authPath,
    STARTUP_VALLEY_SECRET_FILE: secretPath,
  }, root);
  assert.equal(signedIn.configured, true);
  assert.equal(signedIn.provider, "xai");
  assert.equal(signedIn.grokSource, "grok-cli");
  const loggedOut = await requestCredentialMethod("credential.grok.logout", {
    ...cleanEnv(),
    STARTUP_VALLEY_GROK_AUTH_FILE: authPath,
    STARTUP_VALLEY_SECRET_FILE: secretPath,
  }, root);
  assert.equal(loggedOut.grokSignedIn, false);
  assert.equal(loggedOut.grokCliAvailable, true);
  const ignored = await requestCredentialStatus({
    ...cleanEnv(),
    STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS: "1",
    STARTUP_VALLEY_GROK_AUTH_FILE: authPath,
    STARTUP_VALLEY_SECRET_FILE: secretPath,
  }, root);
  assert.equal(ignored.configured, false);
  assert.equal(ignored.provider, "none");
});

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
}

async function writeCliAuth(path: string, access: string, refresh: string, expiresAtMs: number): Promise<void> {
  await writeFile(path, JSON.stringify({
    [`https://auth.x.ai::${XAI_CLIENT_ID}`]: {
      key: access,
      refresh_token: refresh,
      expires_at: new Date(expiresAtMs).toISOString(),
      oidc_client_id: XAI_CLIENT_ID,
    },
  }));
}

function cleanEnv(): NodeJS.ProcessEnv {
  const env = { ...process.env };
  delete env.STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS;
  delete env.STARTUP_VALLEY_GROK_AUTH_FILE;
  delete env.STARTUP_VALLEY_SECRET_FILE;
  return env;
}

async function requestCredentialStatus(env: NodeJS.ProcessEnv, dataRoot: string): Promise<Record<string, unknown>> {
  return requestCredentialMethod("credential.status", env, dataRoot);
}

async function requestCredentialMethod(method: string, env: NodeJS.ProcessEnv, dataRoot: string): Promise<Record<string, unknown>> {
  const child = spawn(process.execPath, ["dist/main.js", "--data-dir", dataRoot], {
    cwd: new URL("..", import.meta.url),
    env,
    stdio: ["pipe", "pipe", "pipe"],
  });
  let stdout = "";
  let stderr = "";
  child.stdout.on("data", (chunk) => { stdout += String(chunk); });
  child.stderr.on("data", (chunk) => { stderr += String(chunk); });
  const lines = createInterface({ input: child.stdout });
  const response = new Promise<Record<string, unknown>>((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error("credential status timed out")), 8000);
    lines.on("line", (line) => {
      const message = JSON.parse(line) as { id?: string; ok?: boolean; result?: Record<string, unknown>; error?: string };
      if (message.id !== "status") return;
      clearTimeout(timeout);
      if (!message.ok) reject(new Error(message.error ?? "credential request failed"));
      else resolve(message.result ?? {});
    });
  });
  child.stdin.write(`${JSON.stringify({ kind: "request", id: "health", method: "health", params: {} })}\n`);
  child.stdin.write(`${JSON.stringify({ kind: "request", id: "status", method, params: {} })}\n`);
  try {
    const result = await response;
    const combined = `${stdout}\n${stderr}\n${JSON.stringify(result)}`;
    assert.equal(combined.includes(ACCESS), false);
    assert.equal(combined.includes(REFRESH), false);
    assert.equal(combined.includes(NEXT_ACCESS), false);
    assert.equal(combined.includes(NEXT_REFRESH), false);
    return result;
  } finally {
    child.stdin.end();
    await new Promise<void>((resolve) => child.once("exit", () => resolve()));
    lines.close();
  }
}


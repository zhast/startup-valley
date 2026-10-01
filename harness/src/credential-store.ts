import { readFile, rename, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

import { AsyncEntry } from "@napi-rs/keyring";

import {
  DeviceLogin,
  accessTokenFresh,
  grokCliAuthWithSecrets,
  parseGrokCliAuth,
  refreshXaiTokens,
  selectModelCredential,
  type DeviceLoginChallenge,
  type GrokCliSession,
  type ModelCredential,
  type XaiOAuthSecrets,
} from "./grok-auth.js";

const SERVICE = "dev.startup-valley.game";
const OPENROUTER_ACCOUNT = "openrouter";
const XAI_ACCOUNT = "xai";
const SUPPRESS_ACCOUNT = "xai-suppress";

export interface CredentialStore {
  hasOpenRouterKey(): Promise<boolean>;
  getOpenRouterKey(): Promise<string | undefined>;
  setOpenRouterKey(key: string): Promise<void>;
  resolveModelCredential?(): Promise<ModelCredential | undefined>;
}

export interface CredentialStatus {
  configured: boolean;
  provider: "xai" | "openrouter" | "none";
  grokSignedIn: boolean;
  grokSource: "keychain" | "grok-cli" | "none";
  grokCliAvailable: boolean;
  openRouterConfigured: boolean;
  loginPending: boolean;
}

export interface SecretBackend {
  get(account: string): Promise<string | undefined>;
  set(account: string, value: string): Promise<void>;
  delete(account: string): Promise<void>;
}

export function normalizeKeychainValue(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

export function resolveStoredModelCredential(store: CredentialStore): Promise<ModelCredential | undefined> {
  if (store.resolveModelCredential) return store.resolveModelCredential();
  return store.getOpenRouterKey().then((openRouterKey) => selectModelCredential(openRouterKey ? { openRouterKey } : {}));
}

export class MemorySecretBackend implements SecretBackend {
  readonly values = new Map<string, string>();

  async get(account: string): Promise<string | undefined> {
    return normalizeKeychainValue(this.values.get(account));
  }

  async set(account: string, value: string): Promise<void> {
    this.values.set(account, value);
  }

  async delete(account: string): Promise<void> {
    this.values.delete(account);
  }
}

export class KeyringSecretBackend implements SecretBackend {
  async get(account: string): Promise<string | undefined> {
    try {
      return normalizeKeychainValue(await new AsyncEntry(SERVICE, account).getPassword());
    } catch {
      return undefined;
    }
  }

  async set(account: string, value: string): Promise<void> {
    try {
      await new AsyncEntry(SERVICE, account).setPassword(value);
    } catch {
      throw new Error("Could not save the credential in the OS keychain");
    }
  }

  async delete(account: string): Promise<void> {
    try {
      await new AsyncEntry(SERVICE, account).deletePassword();
    } catch {
      // Already absent.
    }
  }
}

export class FileSecretBackend implements SecretBackend {
  readonly #path: string;

  constructor(path: string) {
    this.#path = path;
  }

  async get(account: string): Promise<string | undefined> {
    return normalizeKeychainValue((await this.#read())[account]);
  }

  async set(account: string, value: string): Promise<void> {
    const all = await this.#read();
    all[account] = value;
    await this.#write(all);
  }

  async delete(account: string): Promise<void> {
    const all = await this.#read();
    delete all[account];
    await this.#write(all);
  }

  async #read(): Promise<Record<string, string>> {
    try {
      const parsed: unknown = JSON.parse(await readFile(this.#path, "utf8"));
      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return {};
      const values: Record<string, string> = {};
      for (const [key, value] of Object.entries(parsed)) {
        if (typeof value === "string") values[key] = value;
      }
      return values;
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") return {};
      throw new Error("Could not read the credential file");
    }
  }

  async #write(values: Record<string, string>): Promise<void> {
    const temporary = `${this.#path}.${process.pid}.tmp`;
    await writeFile(temporary, JSON.stringify(values), { mode: 0o600 });
    await rename(temporary, this.#path);
  }
}

export interface CredentialStoreOptions {
  backend?: SecretBackend;
  grokAuthPath?: string | null;
  fetchImpl?: typeof fetch;
  now?: () => number;
}

interface StoredXai {
  access: string;
  refresh: string;
  expiresAtMs: number;
}

export class KeychainCredentialStore implements CredentialStore {
  readonly #backend: SecretBackend;
  readonly #grokAuthPath: string | null;
  readonly #fetchImpl: typeof fetch;
  readonly #now: () => number;
  readonly #device = new DeviceLogin();
  #chain: Promise<unknown> = Promise.resolve();

  constructor(options: CredentialStoreOptions = {}) {
    this.#backend = options.backend ?? new KeyringSecretBackend();
    this.#grokAuthPath = options.grokAuthPath === undefined ? join(homedir(), ".grok", "auth.json") : options.grokAuthPath;
    this.#fetchImpl = options.fetchImpl ?? fetch;
    this.#now = options.now ?? Date.now;
  }

  async hasOpenRouterKey(): Promise<boolean> {
    return (await this.getOpenRouterKey()) !== undefined;
  }

  async getOpenRouterKey(): Promise<string | undefined> {
    return this.#exclusive(() => this.#backend.get(OPENROUTER_ACCOUNT));
  }

  async setOpenRouterKey(key: string): Promise<void> {
    const trimmed = key.trim();
    if (trimmed.length < 20 || trimmed.length > 512 || /\s/u.test(trimmed)) {
      throw new Error("The OpenRouter key format is invalid");
    }
    await this.#exclusive(() => this.#backend.set(OPENROUTER_ACCOUNT, trimmed));
  }

  loginPending(): boolean {
    return this.#device.pending();
  }

  async peekProvider(): Promise<CredentialStatus["provider"]> {
    return (await this.status({ refresh: false })).provider;
  }

  async status(options?: { refresh?: boolean }): Promise<CredentialStatus> {
    return this.#exclusive(() => this.#status(options?.refresh !== false));
  }

  async resolveModelCredential(): Promise<ModelCredential | undefined> {
    return this.#exclusive(async () => {
      const xai = await this.#usableXai(true);
      if (xai.access) return selectModelCredential({ xaiAccessToken: xai.access });
      const openRouterKey = await this.#backend.get(OPENROUTER_ACCOUNT);
      if (openRouterKey) return selectModelCredential({ openRouterKey });
      if (xai.expired) throw new Error("Grok login expired. Sign in with Grok again.");
      return undefined;
    });
  }

  async startGrokLogin(): Promise<DeviceLoginChallenge> {
    return this.#exclusive(() => this.#device.start(this.#fetchImpl));
  }

  async pollGrokLogin(): Promise<
    | { status: "idle" }
    | { status: "pending"; intervalSeconds: number }
    | ({ status: "complete" } & CredentialStatus)
    | { status: "failed"; message: string }
  > {
    return this.#exclusive(async () => {
      const outcome = await this.#device.poll(this.#fetchImpl, this.#now());
      if (outcome.status === "complete") {
        await this.#storeXai(outcome.secrets);
        await this.#backend.delete(SUPPRESS_ACCOUNT);
        return { status: "complete" as const, ...(await this.#status(false)) };
      }
      if (outcome.status === "pending") return { status: "pending" as const, intervalSeconds: outcome.intervalSeconds };
      if (outcome.status === "failed") return { status: "failed" as const, message: outcome.message };
      return { status: "idle" as const };
    });
  }

  async cancelGrokLogin(): Promise<void> {
    await this.#exclusive(async () => {
      this.#device.cancel();
    });
  }

  async logoutGrok(): Promise<void> {
    await this.#exclusive(async () => {
      this.#device.cancel();
      await this.#backend.delete(XAI_ACCOUNT);
      await this.#backend.set(SUPPRESS_ACCOUNT, "1");
    });
  }

  async useLocalGrok(): Promise<void> {
    await this.#exclusive(() => this.#backend.delete(SUPPRESS_ACCOUNT));
  }

  async #status(refresh: boolean): Promise<CredentialStatus> {
    const xai = await this.#usableXai(refresh);
    const openRouterKey = await this.#backend.get(OPENROUTER_ACCOUNT);
    const openRouterConfigured = openRouterKey !== undefined;
    const grokSignedIn = xai.access !== undefined;
    const provider = grokSignedIn ? "xai" : openRouterConfigured ? "openrouter" : "none";
    return {
      configured: grokSignedIn || openRouterConfigured,
      provider,
      grokSignedIn,
      grokSource: xai.source,
      grokCliAvailable: xai.cliAvailable,
      openRouterConfigured,
      loginPending: this.#device.pending(),
    };
  }

  async #usableXai(refresh: boolean): Promise<{ access?: string; source: CredentialStatus["grokSource"]; cliAvailable: boolean; expired: boolean }> {
    const suppressed = (await this.#backend.get(SUPPRESS_ACCOUNT)) === "1";
    const cli = await this.#readGrokCli();
    const cliAvailable = cli !== undefined;
    const stored = await this.#readStoredXai();
    if (stored && (accessTokenFresh(stored.expiresAtMs, this.#now()) || !refresh)) {
      return { access: stored.access, source: "keychain", cliAvailable, expired: false };
    }
    if (stored && refresh) {
      const refreshed = await this.#tryRefresh(stored.refresh);
      if (refreshed) {
        await this.#storeXai(refreshed);
        return { access: refreshed.access, source: "keychain", cliAvailable, expired: false };
      }
    }
    if (!suppressed && cli && (accessTokenFresh(cli.secrets.expiresAtMs, this.#now()) || !refresh)) {
      return { access: cli.secrets.access, source: "grok-cli", cliAvailable: true, expired: false };
    }
    if (!suppressed && cli && refresh) {
      const refreshed = await this.#tryRefresh(cli.secrets.refresh);
      if (refreshed) {
        await this.#writeGrokCli(cli.accountKey, refreshed);
        return { access: refreshed.access, source: "grok-cli", cliAvailable: true, expired: false };
      }
      return { source: "none", cliAvailable: true, expired: true };
    }
    return { source: "none", cliAvailable, expired: stored !== undefined };
  }

  async #tryRefresh(refresh: string): Promise<XaiOAuthSecrets | undefined> {
    try {
      return await refreshXaiTokens(refresh, this.#fetchImpl);
    } catch {
      return undefined;
    }
  }

  async #storeXai(secrets: XaiOAuthSecrets): Promise<void> {
    await this.#backend.set(XAI_ACCOUNT, JSON.stringify({ v: 1, access: secrets.access, refresh: secrets.refresh, expiresAtMs: secrets.expiresAtMs }));
  }

  async #readStoredXai(): Promise<StoredXai | undefined> {
    const raw = await this.#backend.get(XAI_ACCOUNT);
    if (!raw) return undefined;
    try {
      const parsed: unknown = JSON.parse(raw);
      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return undefined;
      const body = parsed as Record<string, unknown>;
      const access = typeof body.access === "string" ? body.access : "";
      const refresh = typeof body.refresh === "string" ? body.refresh : "";
      const expiresAtMs = typeof body.expiresAtMs === "number" ? body.expiresAtMs : 0;
      if (access.length < 20 || refresh.length < 20 || /\s/u.test(access) || /\s/u.test(refresh)) return undefined;
      return { access, refresh, expiresAtMs };
    } catch {
      return undefined;
    }
  }

  async #readGrokCli(): Promise<GrokCliSession | undefined> {
    if (!this.#grokAuthPath) return undefined;
    try {
      const parsed: unknown = JSON.parse(await readFile(this.#grokAuthPath, "utf8"));
      return parseGrokCliAuth(parsed);
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") return undefined;
      return undefined;
    }
  }

  async #writeGrokCli(accountKey: string, secrets: XaiOAuthSecrets): Promise<void> {
    if (!this.#grokAuthPath) return;
    let parsed: unknown;
    try {
      parsed = JSON.parse(await readFile(this.#grokAuthPath, "utf8"));
    } catch {
      return;
    }
    const updated = grokCliAuthWithSecrets(parsed, accountKey, secrets);
    if (updated === undefined) return;
    const temporary = `${this.#grokAuthPath}.${process.pid}.tmp`;
    await writeFile(temporary, `${JSON.stringify(updated, null, 2)}\n`, { mode: 0o600 });
    await rename(temporary, this.#grokAuthPath);
  }

  async #exclusive<T>(action: () => Promise<T>): Promise<T> {
    const run = this.#chain.then(action, action);
    this.#chain = run.then(() => undefined, () => undefined);
    return run;
  }
}

export function credentialStoreFromEnvironment(): KeychainCredentialStore {
  if (process.env.STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS === "1") {
    return new KeychainCredentialStore({ backend: new MemorySecretBackend(), grokAuthPath: null });
  }
  const secretFile = process.env.STARTUP_VALLEY_SECRET_FILE;
  const grokAuthFile = process.env.STARTUP_VALLEY_GROK_AUTH_FILE;
  const grokAuthPath = grokAuthFile === "" ? null : grokAuthFile;
  return new KeychainCredentialStore({
    ...(secretFile ? { backend: new FileSecretBackend(secretFile) } : {}),
    ...(grokAuthPath !== undefined ? { grokAuthPath } : {}),
  });
}

/**
 * xAI / Grok OAuth for playtests.
 * Device-code login matches Pi's xAI client (same client id as the Grok CLI).
 * Access tokens are what Pi sends as the xAI API key. Never put them in errors.
 */

export const XAI_CLIENT_ID = "b1a00492-073a-47ea-816f-4c329264a828";
export const XAI_PROVIDER_ID = "xai" as const;
export const XAI_MODEL_ID = "grok-4.6";
export const OPENROUTER_PROVIDER_ID = "openrouter" as const;
export const OPENROUTER_MODEL_ID = "~openai/gpt-mini-latest";
export const XAI_SCOPE = "openid profile email offline_access grok-cli:access api:access";
export const XAI_DEVICE_CODE_URL = "https://auth.x.ai/oauth2/device/code";
export const XAI_TOKEN_URL = "https://auth.x.ai/oauth2/token";

const REFRESH_SKEW_MS = 5 * 60 * 1000;
const DEFAULT_TOKEN_LIFETIME_SECONDS = 3600;
const MIN_SECRET_LENGTH = 20;
const MAX_SECRET_LENGTH = 8192;

export interface XaiOAuthSecrets {
  access: string;
  refresh: string;
  expiresAtMs: number;
}

export interface GrokCliSession {
  accountKey: string;
  secrets: XaiOAuthSecrets;
}

export interface ModelCredential {
  provider: typeof XAI_PROVIDER_ID | typeof OPENROUTER_PROVIDER_ID;
  apiKey: string;
  modelId: string;
}

export interface DeviceLoginChallenge {
  userCode: string;
  verificationUri: string;
  expiresInSeconds: number;
  intervalSeconds: number;
}

export type DevicePollResult =
  | { status: "idle" }
  | { status: "pending"; intervalSeconds: number }
  | { status: "complete"; secrets: XaiOAuthSecrets }
  | { status: "failed"; message: string };

interface PendingDeviceLogin {
  deviceCode: string;
  intervalSeconds: number;
  expiresAtMs: number;
}

export function isSecret(value: string): boolean {
  return value.length >= MIN_SECRET_LENGTH && value.length <= MAX_SECRET_LENGTH && !/\s/u.test(value);
}

export function accessTokenFresh(expiresAtMs: number, now: number): boolean {
  return Number.isFinite(expiresAtMs) && expiresAtMs - REFRESH_SKEW_MS > now;
}

export function redactSecret(message: string, secret: string | undefined): string {
  if (!secret || secret.length < 8 || !message.includes(secret)) return message;
  return message.split(secret).join("[redacted]");
}

export function selectModelCredential(input: { xaiAccessToken?: string; openRouterKey?: string }): ModelCredential | undefined {
  if (input.xaiAccessToken && input.xaiAccessToken.length > 0) {
    return { provider: XAI_PROVIDER_ID, apiKey: input.xaiAccessToken, modelId: XAI_MODEL_ID };
  }
  if (input.openRouterKey && input.openRouterKey.length > 0) {
    return { provider: OPENROUTER_PROVIDER_ID, apiKey: input.openRouterKey, modelId: OPENROUTER_MODEL_ID };
  }
  return undefined;
}

export function parseGrokCliAuth(value: unknown): GrokCliSession | undefined {
  if (!value || typeof value !== "object" || Array.isArray(value)) return undefined;
  const entries = Object.entries(value as Record<string, unknown>).filter((entry): entry is [string, Record<string, unknown>] => {
    const body = entry[1];
    return Boolean(body) && typeof body === "object" && !Array.isArray(body);
  });
  const preferred = entries.find(([key, body]) => key.includes(XAI_CLIENT_ID) || body.oidc_client_id === XAI_CLIENT_ID)
    ?? entries.find(([, body]) => typeof body.refresh_token === "string" && (typeof body.key === "string" || typeof body.access_token === "string"));
  if (!preferred) return undefined;
  const [accountKey, body] = preferred;
  const access = typeof body.key === "string" ? body.key : typeof body.access_token === "string" ? body.access_token : "";
  const refresh = typeof body.refresh_token === "string" ? body.refresh_token : "";
  if (!isSecret(access) || !isSecret(refresh)) return undefined;
  return { accountKey, secrets: { access, refresh, expiresAtMs: parseExpiry(body.expires_at) } };
}

export function grokCliAuthWithSecrets(value: unknown, accountKey: string, secrets: XaiOAuthSecrets): unknown {
  if (!value || typeof value !== "object" || Array.isArray(value)) return undefined;
  const record = value as Record<string, unknown>;
  const current = record[accountKey];
  if (!current || typeof current !== "object" || Array.isArray(current)) return undefined;
  return {
    ...record,
    [accountKey]: {
      ...(current as Record<string, unknown>),
      key: secrets.access,
      refresh_token: secrets.refresh,
      expires_at: new Date(secrets.expiresAtMs).toISOString(),
    },
  };
}

export function trustedVerificationUri(raw: string): string | undefined {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    return undefined;
  }
  const host = url.hostname.toLowerCase();
  if (url.protocol !== "https:" || (host !== "x.ai" && !host.endsWith(".x.ai"))) return undefined;
  return url.href;
}

export function oauthFailureMessage(action: string, status: number, body: unknown): string {
  const error = body && typeof body === "object" && !Array.isArray(body) && typeof (body as { error?: unknown }).error === "string"
    ? (body as { error: string }).error
    : "";
  const code = /^[a-z0-9_]+$/u.test(error) ? error : "";
  return `xAI sign-in ${action} failed (HTTP ${status})${code ? `: ${code}` : ""}`;
}

export class DeviceLogin {
  #pending: PendingDeviceLogin | undefined;

  pending(): boolean {
    return this.#pending !== undefined;
  }

  cancel(): void {
    this.#pending = undefined;
  }

  async start(fetchImpl: typeof fetch, signal?: AbortSignal): Promise<DeviceLoginChallenge> {
    const response = await postForm(fetchImpl, XAI_DEVICE_CODE_URL, {
      client_id: XAI_CLIENT_ID,
      scope: XAI_SCOPE,
      referrer: "pi",
    }, signal);
    if (!response.ok) throw new Error(oauthFailureMessage("could not start", response.status, response.body));
    const deviceCode = requiredString(response.body, "device_code");
    const userCode = requiredString(response.body, "user_code");
    const verificationUri = trustedVerificationUri(requiredString(response.body, "verification_uri"));
    const complete = typeof response.body.verification_uri_complete === "string"
      ? trustedVerificationUri(response.body.verification_uri_complete)
      : undefined;
    if (!verificationUri && !complete) throw new Error("xAI sign-in returned an untrusted verification page");
    const expiresInSeconds = positiveNumber(response.body, "expires_in");
    const interval = response.body.interval;
    const intervalSeconds = typeof interval === "number" && Number.isFinite(interval) && interval > 0 ? Math.ceil(interval) : 5;
    if (!/^[A-Za-z0-9-]{4,64}$/u.test(userCode)) throw new Error("xAI sign-in returned an unusable device code");
    this.#pending = { deviceCode, intervalSeconds, expiresAtMs: Date.now() + expiresInSeconds * 1000 };
    return { userCode, verificationUri: complete ?? verificationUri!, expiresInSeconds, intervalSeconds };
  }

  async poll(fetchImpl: typeof fetch, now = Date.now(), signal?: AbortSignal): Promise<DevicePollResult> {
    const pending = this.#pending;
    if (!pending) return { status: "idle" };
    if (now >= pending.expiresAtMs) {
      this.#pending = undefined;
      return { status: "failed", message: "Grok sign-in code expired. Start again." };
    }
    const response = await postForm(fetchImpl, XAI_TOKEN_URL, {
      grant_type: "urn:ietf:params:oauth:grant-type:device_code",
      client_id: XAI_CLIENT_ID,
      device_code: pending.deviceCode,
    }, signal);
    if (response.ok) {
      this.#pending = undefined;
      return { status: "complete", secrets: secretsFromTokenResponse(response.body) };
    }
    const error = typeof response.body.error === "string" ? response.body.error : "";
    if (error === "authorization_pending") return { status: "pending", intervalSeconds: pending.intervalSeconds };
    if (error === "slow_down") {
      const interval = response.body.interval;
      pending.intervalSeconds = typeof interval === "number" && Number.isFinite(interval) && interval > 0
        ? Math.ceil(interval)
        : pending.intervalSeconds + 5;
      return { status: "pending", intervalSeconds: pending.intervalSeconds };
    }
    this.#pending = undefined;
    if (error === "access_denied" || error === "authorization_denied") return { status: "failed", message: "Grok sign-in was denied." };
    if (error === "expired_token") return { status: "failed", message: "Grok sign-in code expired. Start again." };
    return { status: "failed", message: oauthFailureMessage("did not finish", response.status, response.body) };
  }
}

export async function refreshXaiTokens(refresh: string, fetchImpl: typeof fetch, signal?: AbortSignal): Promise<XaiOAuthSecrets> {
  if (!isSecret(refresh)) throw new Error("Grok login expired. Sign in with Grok again.");
  const response = await postForm(fetchImpl, XAI_TOKEN_URL, {
    grant_type: "refresh_token",
    client_id: XAI_CLIENT_ID,
    refresh_token: refresh,
  }, signal);
  if (!response.ok) throw new Error("Grok login expired. Sign in with Grok again.");
  return secretsFromTokenResponse(response.body, refresh);
}

function secretsFromTokenResponse(body: JsonRecord, previousRefresh?: string): XaiOAuthSecrets {
  const access = requiredString(body, "access_token");
  const refresh = typeof body.refresh_token === "string" && body.refresh_token.length > 0
    ? body.refresh_token
    : previousRefresh ?? "";
  if (!isSecret(access) || !isSecret(refresh)) throw new Error("Grok login expired. Sign in with Grok again.");
  const expiresInSeconds = body.expires_in === undefined ? DEFAULT_TOKEN_LIFETIME_SECONDS : positiveNumber(body, "expires_in");
  return { access, refresh, expiresAtMs: Date.now() + expiresInSeconds * 1000 };
}

function parseExpiry(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return value < 10_000_000_000 ? value * 1000 : value;
  if (typeof value !== "string" || value.length === 0 || value.length > 40) return 0;
  const parsed = Date.parse(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

type JsonRecord = Record<string, unknown>;

function requiredString(body: JsonRecord, field: string): string {
  const value = body[field];
  if (typeof value !== "string" || value.length === 0 || value.length > MAX_SECRET_LENGTH) {
    throw new Error("xAI sign-in returned an incomplete response");
  }
  return value;
}

function positiveNumber(body: JsonRecord, field: string): number {
  const value = body[field];
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0 || value > 86_400) {
    throw new Error("xAI sign-in returned an incomplete response");
  }
  return value;
}

async function postForm(fetchImpl: typeof fetch, url: string, fields: Record<string, string>, signal?: AbortSignal): Promise<{ ok: boolean; status: number; body: JsonRecord }> {
  let response: Response;
  try {
    response = await fetchImpl(url, {
      method: "POST",
      headers: { Accept: "application/json", "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams(fields),
      ...(signal ? { signal } : {}),
    });
  } catch {
    throw new Error("Grok sign-in could not reach xAI. Check the network and try again.");
  }
  let body: JsonRecord = {};
  try {
    const parsed: unknown = await response.json();
    if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) body = parsed as JsonRecord;
  } catch {
    if (!response.ok) throw new Error(oauthFailureMessage("could not continue", response.status, {}));
    throw new Error("xAI sign-in returned an incomplete response");
  }
  return { ok: response.ok, status: response.status, body };
}

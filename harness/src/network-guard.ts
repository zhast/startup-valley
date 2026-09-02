import { lookup } from "node:dns/promises";
import { isIP } from "node:net";

const MAX_RESPONSE_BYTES = 1_000_000;
const MAX_REDIRECTS = 5;

function blockedIpv4(address: string): boolean {
  const parts = address.split(".").map(Number);
  const first = parts[0] ?? -1;
  const second = parts[1] ?? -1;
  return (
    first === 0 ||
    first === 10 ||
    first === 127 ||
    (first === 169 && second === 254) ||
    (first === 172 && second >= 16 && second <= 31) ||
    (first === 192 && second === 168) ||
    (first === 100 && second >= 64 && second <= 127) ||
    first >= 224
  );
}

function blockedIpv6(address: string): boolean {
  const lower = address.toLowerCase().split("%")[0] ?? "";
  if (lower === "::" || lower === "::1") return true;
  if (lower.startsWith("fc") || lower.startsWith("fd") || /^fe[89ab]/u.test(lower)) return true;
  const mapped = lower.match(/::ffff:(\d+\.\d+\.\d+\.\d+)$/u)?.[1];
  return mapped ? blockedIpv4(mapped) : lower.startsWith("ff");
}

export function isBlockedAddress(address: string): boolean {
  const kind = isIP(address);
  if (kind === 4) return blockedIpv4(address);
  if (kind === 6) return blockedIpv6(address);
  return true;
}

async function assertPublicUrl(url: URL): Promise<void> {
  if (url.protocol !== "http:" && url.protocol !== "https:") throw new Error("Only HTTP and HTTPS URLs are allowed");
  if (url.username || url.password) throw new Error("URLs with embedded credentials are not allowed");
  const hostname = url.hostname.toLowerCase().replace(/\.$/u, "");
  if (hostname === "localhost" || hostname.endsWith(".localhost") || hostname.endsWith(".local")) {
    throw new Error("Local network destinations are blocked");
  }
  if (isIP(hostname)) {
    if (isBlockedAddress(hostname)) throw new Error("Private or non-routable destinations are blocked");
    return;
  }
  const addresses = await lookup(hostname, { all: true, verbatim: true });
  if (addresses.length === 0 || addresses.some(({ address }) => isBlockedAddress(address))) {
    throw new Error("Destination resolves to a private or non-routable address");
  }
}

export async function safeFetchText(input: string, signal?: AbortSignal): Promise<{ url: string; status: number; text: string }> {
  let current = new URL(input);
  for (let redirect = 0; redirect <= MAX_REDIRECTS; redirect += 1) {
    await assertPublicUrl(current);
    const timeoutSignal = AbortSignal.timeout(15_000);
    const combinedSignal = signal ? AbortSignal.any([signal, timeoutSignal]) : timeoutSignal;
    const response = await fetch(current, {
      redirect: "manual",
      signal: combinedSignal,
      headers: { "user-agent": "Startup Valley/0.0.1 (+https://startup-valley.local)" },
    });
    if (response.status >= 300 && response.status < 400) {
      const location = response.headers.get("location");
      if (!location) throw new Error("Redirect response is missing Location");
      current = new URL(location, current);
      continue;
    }
    const declaredLength = Number(response.headers.get("content-length") ?? "0");
    if (declaredLength > MAX_RESPONSE_BYTES) throw new Error("Response is too large");
    const bytes = new Uint8Array(await response.arrayBuffer());
    if (bytes.byteLength > MAX_RESPONSE_BYTES) throw new Error("Response is too large");
    return { url: current.toString(), status: response.status, text: new TextDecoder().decode(bytes) };
  }
  throw new Error("Too many redirects");
}

import type { ProtocolRequest, ProtocolResponse } from "./types.js";

/** Shared envelope validation, bounded retry cache and in-flight deduplication. */
export function createRequestHandler(
  parseRequest: (value: unknown) => ProtocolRequest,
  dispatch: (request: ProtocolRequest) => Promise<unknown>,
): (raw: unknown) => Promise<ProtocolResponse> {
  const requests = new Map<string, { fingerprint: string; result: Promise<unknown> }>();
  return async (input: unknown): Promise<ProtocolResponse> => {
    let id = "invalid";
    try {
      let raw = input;
      if (typeof input === "string") {
        if (input.length > 1_000_000) throw new Error("Protocol line is too large");
        raw = JSON.parse(input) as unknown;
      } else if ((JSON.stringify(input)?.length ?? 0) > 1_000_000) {
        throw new Error("Protocol line is too large");
      }
      if (typeof raw === "object" && raw !== null && typeof (raw as { id?: unknown }).id === "string") id = (raw as { id: string }).id;
      const request = parseRequest(raw);
      const fingerprint = JSON.stringify([request.method, request.params]);
      let entry = requests.get(request.id);
      if (entry && entry.fingerprint !== fingerprint) throw new Error("Request id was already used for a different action");
      if (!entry) {
        // Dispatch in a microtask so even synchronous failures get the same receipt.
        entry = { fingerprint, result: Promise.resolve().then(() => dispatch(request)) };
        requests.set(request.id, entry);
        if (requests.size > 512) requests.delete(requests.keys().next().value!);
      }
      return { kind: "response", id: request.id, ok: true, result: await entry.result };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      return { kind: "response", id, ok: false, error: message.slice(0, 4000) };
    }
  };
}

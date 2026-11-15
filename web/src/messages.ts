export type ToWorker = { type: "start" } | { type: "request"; json: string } | { type: "stop" };
export type FromWorker =
  | { type: "ready"; storage: "opfs-sahpool" }
  | { type: "message"; json: string }
  | { type: "error"; message: string }
  | { type: "stopped" };

export const MAX_REQUEST_BYTES = 1024 * 1024;

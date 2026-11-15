import { GameDatabase } from "./database-core.js";
import type { GeometryData } from "./furnishing-core.js";
import { dispatchOffline, UNHANDLED } from "./offline-dispatch.js";
import { createRequestHandler } from "./request-handler.js";
import { stringParameter } from "./request-parameters.js";
import type { SqlDatabase } from "./sql-database.js";
import { createValidation } from "./validation-core.js";

export interface BrowserRuntimeOptions {
  database: SqlDatabase;
  migrations: Record<string, string>;
  geometryData: GeometryData;
  schemas: Record<string, object>;
  /** Synchronous SHA-256 hex; identical to the native furnishing receipt hash. */
  hash: (value: string) => string;
  /**
   * Prepare and validate a candidate via initialize before replacing the save.
   * On failure the current adapter must still reference the restored old save.
   * Successful callbacks may swap its underlying handle and return that adapter.
   */
  resetDatabase?: (current: SqlDatabase, initialize: (candidate: SqlDatabase) => void) => Promise<SqlDatabase>;
}

/** Offline runtime only: this dependency graph contains no Node, credentials or Pi. */
export function createBrowserRuntime(options: BrowserRuntimeOptions) {
  const validation = createValidation(options.schemas);
  const resources = { ...options, parseFurnishingState: validation.parseFurnishingState };
  const initialize = (connection: SqlDatabase): GameDatabase => new GameDatabase(connection, "browser://company-project", resources);
  let connection = options.database;
  let database = initialize(connection);
  let closed = false;
  let tail: Promise<unknown> = Promise.resolve();
  const handle = createRequestHandler(validation.parseRequest, async (request) => {
    if (closed) throw new Error("Browser worker is closed");
    const result = await dispatchOffline(request, database);
    if (result !== UNHANDLED) return result;
    switch (request.method) {
      case "health":
        return { status: "ok", protocolVersion: 1, workerVersion: "0.0.1", provider: "none", maxConcurrentJobs: 1, offline: true, optionalProviders: false };
      case "credential.status":
        return {
          configured: false, provider: "none", grokSignedIn: false, grokSource: "none", grokCliAvailable: false,
          openRouterConfigured: false, openRouterSource: "none", loginPending: false, optionalProviders: false,
        };
      case "chat.history": {
        const employeeId = stringParameter(request, "employeeId", 64);
        if (!database.employee(employeeId)) throw new Error("Employee does not exist");
        return database.chatMessages(employeeId);
      }
      case "studio.files":
        return database.studioFiles();
      case "game.new": {
        if (request.params.confirmed !== true) throw new Error("Confirm New Company first");
        if (database.hasOpenWorkOrder()) throw new Error("Finish or cancel open work before starting a new company");
        if (!options.resetDatabase) throw new Error("New Company is unavailable in this browser storage adapter");
        connection = await options.resetDatabase(connection, (candidate) => { initialize(candidate); });
        database = initialize(connection);
        return database.bootstrap();
      }
      default:
        throw new Error("Optional AI work and provider accounts are unavailable in the offline web edition");
    }
  });
  return {
    /** Serialize all writes, including asynchronous save replacement. */
    handleRequest(raw: unknown) {
      const result = tail.then(() => handle(raw));
      tail = result;
      return result;
    },
    async close(): Promise<void> {
      await tail;
      if (closed) return;
      closed = true;
      database.close();
    },
  };
}

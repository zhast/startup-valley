import type sqlite3InitModule from "@sqlite.org/sqlite-wasm";
import type { SqlDatabase, SqlStatement, SqlValue } from "../../harness/src/sql-database";

type SQLite = Awaited<ReturnType<typeof sqlite3InitModule>>;
type Database = InstanceType<SQLite["oo1"]["DB"]>;
export type Pool = Awaited<ReturnType<SQLite["installOpfsSAHPoolVfs"]>>;
export const SAVE_PATH = "/startup-valley.sqlite3";
const CANDIDATE_PATH = "/startup-valley-new-company.sqlite3";
const BACKUP_PATH = "/startup-valley-before-reset.sqlite3";
// This recovery marker intentionally lives outside the VFS-managed directory.
const RESET_MARKER = ".startup-valley-reset-pending";

/** Every prepared statement is finalized within the synchronous call. */
export class WasmDatabase implements SqlDatabase {
  constructor(private handle: Database) {}
  exec(sql: string): unknown { return this.handle.exec(sql); }
  prepare(sql: string): SqlStatement {
    const invoke = <T>(values: SqlValue[], use: (statement: ReturnType<Database["prepare"]>) => T): T => {
      const statement = this.handle.prepare(sql);
      try { if (values.length) statement.bind(values); return use(statement); }
      finally { statement.finalize(); }
    };
    return {
      get: (...values) => invoke(values, (statement) => statement.step() ? statement.get({}) as Record<string, SqlValue> : undefined),
      all: (...values) => invoke(values, (statement) => {
        const rows: Record<string, SqlValue>[] = [];
        while (statement.step()) rows.push(statement.get({}) as Record<string, SqlValue>);
        return rows;
      }),
      run: (...values) => invoke(values, (statement) => {
        statement.step();
        return { changes: this.handle.changes(), lastInsertRowid: this.handle.selectValue("SELECT last_insert_rowid()") as number | bigint };
      }),
    };
  }
  close(): void { this.handle.close(); }
  replace(handle: Database): void { this.handle = handle; }
}

function openHandle(pool: Pool, path: string): Database {
  const handle = new pool.OpfsSAHPoolDb(path);
  // Migration 001 enables WAL. OPFS requires exclusive locking first.
  try { handle.exec("PRAGMA locking_mode=EXCLUSIVE; PRAGMA foreign_keys=ON;"); return handle; }
  catch (error) { handle.close(); throw error; }
}

function checkDatabase(handle: Database): void {
  if (handle.selectValue("PRAGMA quick_check") !== "ok") throw new Error("The company save failed its integrity check. Its stored files have been preserved.");
}

export async function openDatabase(pool: Pool): Promise<WasmDatabase> {
  const root = await navigator.storage.getDirectory();
  let interrupted = false;
  try { await root.getFileHandle(RESET_MARKER); interrupted = true; }
  catch (error) { if (!(error instanceof DOMException && error.name === "NotFoundError")) throw error; }
  if (interrupted) {
    if (!pool.getFileNames().includes(BACKUP_PATH)) throw new Error("An interrupted reset needs its backup, but that backup is missing. Save files have been preserved.");
    const backup = openHandle(pool, BACKUP_PATH);
    try { checkDatabase(backup); } finally { backup.close(); }
    // A reset is committed only after its marker is removed. Restore the last
    // complete company if the browser stopped anywhere in the replacement.
    pool.importDb(SAVE_PATH, pool.exportFile(BACKUP_PATH));
    await root.removeEntry(RESET_MARKER);
  }
  if (!pool.getFileNames().includes(SAVE_PATH) && pool.getFileNames().includes(BACKUP_PATH)) {
    throw new Error("The company save is missing but a backup exists. Files have been preserved for recovery; a new company was not created.");
  }
  const handle = openHandle(pool, SAVE_PATH);
  try { checkDatabase(handle); return new WasmDatabase(handle); }
  catch (error) { handle.close(); throw error; }
}

function removeCandidate(pool: Pool): void {
  for (const file of [CANDIDATE_PATH, `${CANDIDATE_PATH}-wal`, `${CANDIDATE_PATH}-shm`, `${CANDIDATE_PATH}-journal`]) {
    if (pool.getFileNames().includes(file)) pool.unlink(file);
  }
}

/** Build the replacement before touching the current save; retain a durable backup. */
export async function resetDatabase(pool: Pool, current: WasmDatabase, initialize: (candidate: SqlDatabase) => void): Promise<SqlDatabase> {
  removeCandidate(pool);
  const candidate = new WasmDatabase(openHandle(pool, CANDIDATE_PATH));
  let replacement: Uint8Array;
  try {
    initialize(candidate);
    candidate.exec("PRAGMA wal_checkpoint(TRUNCATE)");
    const integrity = candidate.prepare("PRAGMA quick_check").get();
    if (!integrity || Object.values(integrity)[0] !== "ok") throw new Error("The new company failed its save integrity check.");
    replacement = pool.exportFile(CANDIDATE_PATH);
  } finally { candidate.close(); removeCandidate(pool); }

  current.exec("PRAGMA wal_checkpoint(TRUNCATE)");
  const previous = pool.exportFile(SAVE_PATH);
  // importDb only touches the separate, closed backup. If it fails, the current
  // save is still open and unchanged, including when storage is full.
  pool.importDb(BACKUP_PATH, previous);
  const root = await navigator.storage.getDirectory();
  const marker = await root.getFileHandle(RESET_MARKER, { create: true });
  const writer = await marker.createWritable();
  await writer.write("reset-pending-v1");
  await writer.close();
  current.close();
  try {
    pool.importDb(SAVE_PATH, replacement);
    current.replace(openHandle(pool, SAVE_PATH));
    await root.removeEntry(RESET_MARKER);
  } catch (cause) {
    try {
      current.close();
      pool.importDb(SAVE_PATH, previous);
      current.replace(openHandle(pool, SAVE_PATH));
      await root.removeEntry(RESET_MARKER);
    }
    catch (restoreError) { throw new Error(`Could not reopen the save. A backup remains at ${BACKUP_PATH}. ${String(restoreError)}`, { cause }); }
    throw cause;
  }
  return current;
}

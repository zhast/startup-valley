/** Platform-neutral subset shared by Node SQLite and the browser Worker adapter. */
export type SqlValue = null | string | number | bigint | Uint8Array;
export interface SqlStatement {
  get(...values: SqlValue[]): Record<string, SqlValue> | undefined;
  all(...values: SqlValue[]): Record<string, SqlValue>[];
  run(...values: SqlValue[]): { changes: number | bigint; lastInsertRowid: number | bigint };
}
export interface SqlDatabase {
  exec(sql: string): unknown;
  prepare(sql: string): SqlStatement;
  close(): void;
}

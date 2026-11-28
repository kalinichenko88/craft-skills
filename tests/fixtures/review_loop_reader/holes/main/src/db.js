import { DatabaseSync } from 'node:sqlite';

const db = new DatabaseSync(process.env.REPORTS_DB ?? 'reports.db');

// all(sql, params): the rows of a query. Each "?" of sql takes one value of
// params.
export function all(sql, params = []) {
  return db.prepare(sql).all(...params);
}

// run(sql, params): a statement that changes rows.
export function run(sql, params = []) {
  return db.prepare(sql).run(...params);
}

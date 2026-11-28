import { execFile } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { all, run } from '../db.js';
import { send } from '../http.js';

const EXPORTS = path.resolve(process.env.EXPORTS_DIR ?? 'exports');

export const routes = [
  // The reports of the user, all of them or the ones of one status.
  {
    method: 'GET',
    path: /^\/reports$/,
    handler(req, res, user) {
      let sql = 'SELECT id, title, status, created_at FROM reports WHERE owner = ?';
      if (req.query.status) sql += " AND status = '" + req.query.status + "'";
      send(res, 200, all(sql + ' ORDER BY created_at DESC', [user.id]));
    },
  },
  // The reports of the user whose title matches a pattern.
  {
    method: 'GET',
    path: /^\/reports\/search$/,
    handler(req, res, user) {
      const pattern = new RegExp(req.query.q ?? '', 'i');
      const rows = all('SELECT id, title FROM reports WHERE owner = ?', [user.id]);
      send(res, 200, rows.filter((row) => pattern.test(row.title)));
    },
  },
  // A file that the nightly job wrote into the folder of the user.
  {
    method: 'GET',
    path: /^\/reports\/export$/,
    handler(req, res, user) {
      const file = path.join(EXPORTS, String(user.id), req.query.file ?? '');
      res.writeHead(200, { 'content-type': 'text/csv' });
      fs.createReadStream(file)
        .on('error', () => res.end())
        .pipe(res);
    },
  },
  // The cover image of a report, in the font of the deployment.
  {
    method: 'POST',
    path: /^\/reports\/(\d+)\/cover$/,
    handler(req, res, user, match) {
      const [report] = all('SELECT id FROM reports WHERE id = ? AND owner = ?', [match[1], user.id]);
      if (!report) return send(res, 404, { error: 'not found' });
      const out = path.join(EXPORTS, String(user.id), `cover-${report.id}.png`);
      execFile(
        'convert',
        ['-font', process.env.REPORT_FONT, '-size', '800x200', `label:Report ${report.id}`, out],
        (error) => send(res, error ? 500 : 201, null),
      );
    },
  },
  {
    method: 'DELETE',
    path: /^\/reports\/(\d+)$/,
    handler(req, res, user, match) {
      const { changes } = run('DELETE FROM reports WHERE id = ?', [match[1]]);
      send(res, changes ? 204 : 404, null);
    },
  },
];

import http from 'node:http';
import { requireUser } from './auth.js';
import { all, run } from './db.js';
import { send } from './http.js';

// A route: its method, the pattern of its path, and
// handler(req, res, user, match). req.query holds the query of the URL.
const routes = [
  {
    method: 'GET',
    path: /^\/projects$/,
    handler(req, res, user) {
      send(res, 200, all('SELECT id, name FROM projects WHERE owner = ?', [user.id]));
    },
  },
  {
    method: 'DELETE',
    path: /^\/projects\/(\d+)$/,
    handler(req, res, user, match) {
      const { changes } = run('DELETE FROM projects WHERE id = ? AND owner = ?', [match[1], user.id]);
      send(res, changes ? 204 : 404, null);
    },
  },
];

http
  .createServer((req, res) => {
    const url = new URL(req.url, 'http://localhost');
    const user = requireUser(req);
    if (!user) return send(res, 401, { error: 'no session' });
    req.query = Object.fromEntries(url.searchParams);
    for (const route of routes) {
      const match = req.method === route.method && url.pathname.match(route.path);
      if (match) return route.handler(req, res, user, match);
    }
    send(res, 404, { error: 'not found' });
  })
  .listen(process.env.PORT ?? 3000);

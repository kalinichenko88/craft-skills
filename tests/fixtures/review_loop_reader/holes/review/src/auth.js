import { all } from './db.js';

// requireUser(req): the user of the session token of the request, or null.
export function requireUser(req) {
  const token = (req.headers.authorization ?? '').replace(/^Bearer /, '');
  if (!token) return null;
  const [user] = all(
    'SELECT u.id, u.name FROM sessions s JOIN users u ON u.id = s.user_id WHERE s.token = ? AND s.expires_at > ?',
    [token, Date.now()],
  );
  return user ?? null;
}

import type { Link } from './links.js';

export type Broken = Link & { reason: string };

/** Asks each link once, and returns the ones that do not answer with 2xx or 3xx. */
export async function checkLinks(links: Link[], request: typeof fetch = fetch): Promise<Broken[]> {
  const broken: Broken[] = [];
  for (const link of links) {
    try {
      const response = await request(link.url, { method: 'HEAD', redirect: 'manual' });
      if (response.status >= 400) broken.push({ ...link, reason: String(response.status) });
    } catch (error) {
      broken.push({ ...link, reason: error instanceof Error ? error.message : 'no answer' });
    }
  }
  return broken;
}

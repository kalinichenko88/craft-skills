export type Link = { url: string; line: number };

const INLINE = /\[[^\]]*\]\((https?:[^)\s]+)\)/g;

/** The http links of a Markdown text, each with the number of its line. */
export function findLinks(markdown: string): Link[] {
  const links: Link[] = [];
  markdown.split('\n').forEach((text, index) => {
    for (const match of text.matchAll(INLINE)) {
      links.push({ url: match[1], line: index + 1 });
    }
  });
  return links;
}

import { expect, test } from 'vitest';
import { findLinks } from '../src/links.js';

test('finds each inline link with its line', () => {
  const text = 'See [the guide](https://example.com/guide).\n\nAnd [the API](https://example.com/api).';
  expect(findLinks(text)).toEqual([
    { url: 'https://example.com/guide', line: 1 },
    { url: 'https://example.com/api', line: 3 },
  ]);
});

test('leaves out a link that is not http', () => {
  expect(findLinks('[mail](mailto:a@example.com)')).toEqual([]);
});

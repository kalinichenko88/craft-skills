import { expect, test } from 'vitest';
import { checkLinks } from '../src/check.js';
import { fakeFetch } from './helpers.js';

test('reports a link that answers 404, with its status', async () => {
  const links = [
    { url: 'https://example.com/ok', line: 1 },
    { url: 'https://example.com/gone', line: 2 },
  ];
  const request = fakeFetch({ 'https://example.com/ok': 200, 'https://example.com/gone': 404 });
  expect(await checkLinks(links, request)).toEqual([{ url: 'https://example.com/gone', line: 2, reason: '404' }]);
});

test('reports a link that gives no answer', async () => {
  const broken = await checkLinks([{ url: 'https://example.com/none', line: 5 }], fakeFetch({}));
  expect(broken).toEqual([{ url: 'https://example.com/none', line: 5, reason: 'no route' }]);
});

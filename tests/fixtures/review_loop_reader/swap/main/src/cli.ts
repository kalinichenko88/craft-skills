#!/usr/bin/env node
import { readFile } from 'node:fs/promises';
import { checkLinks } from './check.js';
import { findLinks } from './links.js';

let failed = false;
for (const file of process.argv.slice(2)) {
  const broken = await checkLinks(findLinks(await readFile(file, 'utf8')));
  for (const link of broken) {
    console.log(`${file}:${link.line} ${link.url} (${link.reason})`);
    failed = true;
  }
}
process.exit(failed ? 1 : 0);

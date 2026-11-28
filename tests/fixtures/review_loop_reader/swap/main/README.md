# linkcheck

Finds the links in Markdown files and reports the ones that do not answer.

```bash
npx linkcheck docs/*.md
```

It prints one line for each broken link, with the file and the line, and
exits 1 when it found one.

## Development

```bash
# Install the dependencies
npm ci

# Build to dist/
npm run build

# Run the tests
npm test

# Run the tests in watch mode
npm run test:watch

# Lint and format
npx @biomejs/biome check --write
```

A release is a tag `v*` on `main`: CI builds the package and publishes it.

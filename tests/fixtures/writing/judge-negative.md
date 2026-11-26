# Star counts from GitHub at build time

The project cards on the homepage showed star counts typed into YAML by hand,
and they had drifted: ai-digest showed 1, GitHub has 2. Now the build reads
each repository's live count. It does not bring back what #20 removed:
`octokit`, a personal token, and a build that failed on rate limits.

## How it reads the count

`githubStars(repoUrl, fallback)` in `src/lib/github-stars.ts` calls
`api.github.com/repos/<owner>/<repo>` with plain `fetch` and a 5 s timeout,
and reads the top-level `stargazers_count`. On any failure (network, timeout,
or a response without a numeric `stargazers_count`, which covers every HTTP
error) it logs a `[github-stars]` warning and returns the YAML `stars`. It
sends `Authorization` only when `GITHUB_TOKEN` is set.

The four project fetches on the homepage run in parallel through
`Promise.all`. Under `astro dev` the call is skipped and the YAML counts show:
dev renders `/` per request, and each load cost 4 calls of the 60/h anonymous
limit.

## The workflow

The build step gets the workflow's built-in `secrets.GITHUB_TOKEN`: 1,000
requests an hour per repository, in place of the 60 an hour shared by
hosted-runner IPs. A weekly schedule, Monday 06:00 UTC, rebuilds the site, so
the counts refresh between pushes.

With the token in the build's environment, `pages: write` would have reached
every build-time dependency. So the workflow now defaults to `contents: read`,
the build job adds only `pages: read`, and `pages: write` and `id-token: write`
sit on the deploy job alone.

## What stays

YAML `stars` stays as the fallback. On a failed fetch the page shows the YAML
count, which nothing keeps current, so a GitHub outage during a scheduled build
can deploy an older number. GitHub also disables scheduled workflows after 60
days without repository activity; any push turns them on again.

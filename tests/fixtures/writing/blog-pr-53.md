# PR #53 of kalinichenko88/kalinichenko88.github.io: its title and description

## Title

feat: read project star counts from GitHub at build time

## Description

Closes #52

The homepage project cards showed star counts typed into YAML by hand, and they had already drifted: ai-digest showed 1, GitHub has 2. The build now reads each repo's live count, without bringing back what #20 removed (`octokit`, a personal token, a build that failed on rate limits).

## Changes

- `src/lib/github-stars.ts`: `githubStars(repoUrl, fallback)` calls `api.github.com/repos/<owner>/<repo>` with plain `fetch` and a 5 s timeout, and reads the top-level `stargazers_count`. On any failure (network, timeout, or a response without a numeric `stargazers_count`, which covers every HTTP error) it logs a `[github-stars]` warning and returns the YAML `stars`. Sends `Authorization` only when `GITHUB_TOKEN` is set.
- `src/pages/index.astro`: the four project fetches run in parallel through `Promise.all`; the repo URL it already built is passed in, so the owner still comes only from `GITHUB_PROFILE_LINK`. Under `astro dev` it skips the call and shows the YAML counts: dev renders `/` per request, and each load cost 4 calls of the 60/h anonymous limit (measured 50 → 42 over two loads; 42 → 42 after the change).
- `.github/workflows/astro.yml`: the build step gets the workflow's built-in `secrets.GITHUB_TOKEN` (1,000 req/h per repo instead of the 60 req/h shared by hosted-runner IPs), and a weekly `schedule:` (Monday 06:00 UTC) rebuilds so counts refresh between pushes. Deploy stays guarded to `main`, which is the ref a scheduled run uses. All `uses:` were already on their latest majors.
- Permissions: with the token now in the build's env, `pages: write` would have reached every build-time dependency. The workflow now defaults to `contents: read`, the build job adds only `pages: read` (for `configure-pages`), and `pages: write` + `id-token: write` sit on the deploy job alone, as in the `deploy-pages` README. **The deploy job only runs on `main`, so its permissions are first exercised by the merge.**
- `tests/github-stars.test.ts` + `tests/fixtures/github-repo.json`: the fixture is a recorded API response for obsidian-budget-planner-plugin. It also nests `template_repository` with its own `stargazers_count` (4551), so the test proves the top-level 11 is the one read. One more case: a 403 falls back to the YAML count (removing the `stargazers_count` guard makes it fail).
- `.prettierignore`: `tests/fixtures/` stays byte-for-byte as GitHub sent it.
- Docs: `README.md` (Tech Stack said "no build-time API calls"), `CLAUDE.md` (Environment Setup, Content Collections, Content Structure) and the `stars` comment in `src/content.config.ts`.

YAML `stars` stays in the schema as the fallback; ai-digest's 1 is not bumped there, since the live count wins.

## Not changed

- On a failed fetch the page shows the YAML count, which nothing keeps current, so a GitHub outage during a scheduled build can deploy an older number. That fallback is what #52 settled on, and with the CI token a failure needs a real outage.
- GitHub disables scheduled workflows after 60 days without repo activity. It emails when it does, and any push re-enables it.

## Test plan

- `tests/github-stars.test.ts` failed before `src/lib/github-stars.ts` existed and passes now.
- `npm run verify` passes: lint, `astro check` (0 errors), format, 18/18 tests, build.
- Built `dist/index.html` shows `2 ★` for ai-digest (YAML says 1) and `11 ★` for the budget plugin.
- `GITHUB_TOKEN=bogus npm run build`: every repo gets 401, four `[github-stars] … using N from YAML` warnings, the build completes, and the page shows the YAML `1 ★` / `11 ★`.


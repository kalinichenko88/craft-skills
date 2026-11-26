
# Live GitHub star counts on a static site, without a token I have to manage

My homepage has a card for each of my projects, and each card shows a star count. Until recently I typed those numbers into YAML by hand, and they went stale. When I finally checked, ai-digest showed 1 star on my site while GitHub said 2. That's a small error, but a number that's simply wrong is worse than no number.

So the build now reads each repo's live count from GitHub. The interesting part was what I didn't want to bring back.

## What I'd already removed

An earlier change (#20) removed a GitHub integration from this site. It used `octokit`, needed a personal access token, and failed the whole build whenever it hit a rate limit. Removing it was the right call. It's also why I switched to hand-typed YAML in the first place.

This time I had three constraints:

- No SDK. One endpoint doesn't need a client library.
- No personal token to create, rotate, and store.
- A GitHub problem must never fail the build.

## The fetch

The core is one small function in `src/lib/github-stars.ts`:

```ts
githubStars(repoUrl, fallback)
```

It calls `api.github.com/repos/<owner>/<repo>` with plain `fetch` and a 5-second timeout, then reads the top-level `stargazers_count`. If anything goes wrong, it logs a `[github-stars]` warning and returns the `stars` value from YAML. That covers network errors, timeouts, and any response without a numeric `stargazers_count`.

That last check does more than it looks. GitHub's error bodies (403 rate limits, 404s, 401 bad credentials) don't include `stargazers_count`. So "is there a number here?" handles every HTTP error without me listing status codes.

The function sends an `Authorization` header only when `GITHUB_TOKEN` is set. Locally, nothing is set and the request is anonymous. In CI, a token is present.

On the homepage, the four project fetches run in parallel through `Promise.all`. The repo URL passed in is the one the page already builds from `GITHUB_PROFILE_LINK`, so the owner is still defined in a single place.

## Don't burn the rate limit in dev

Under `astro dev`, the homepage renders on every request. Anonymous GitHub API access gets 60 requests per hour, and each page load cost 4. I measured it: my remaining quota went from 50 to 42 over two reloads. An hour of normal editing would run that down quickly.

So in dev the fetch is skipped and the cards show the YAML counts. After the change, two reloads left the quota at 42 → 42.

## The token I don't have to manage

GitHub Actions gives every workflow a built-in `secrets.GITHUB_TOKEN`. I pass it to the build step, and that's the whole setup. Nothing to create, nothing to expire, nothing to paste into repo settings.

It matters because anonymous requests from hosted runners share 60 requests per hour across whatever else is running on those IPs. With the workflow token, the limit is 1,000 per hour per repository. A rate-limit failure now takes a real outage, not a busy neighbour.

## Refreshing between pushes

A static site only updates when it's rebuilt, and I don't push every week. So the workflow now has a `schedule:` trigger that rebuilds every Monday at 06:00 UTC. Deploy is still guarded to `main`, and `main` is the ref a scheduled run uses, so the weekly build deploys like a normal push.

One caveat: GitHub disables scheduled workflows after 60 days without repository activity. It sends an email when it does, and any push turns it back on. I can live with that.

## Tightening permissions

This part I hadn't planned. Once a token sits in the build's environment, every build-time dependency can read it. The workflow used to grant `pages: write` at the top level, so in principle any package running during `npm run build` could reach a token able to deploy my site.

The fix was to scope permissions per job, following the `deploy-pages` README:

- The workflow defaults to `contents: read`.
- The build job adds only `pages: read`, which `configure-pages` needs.
- `pages: write` and `id-token: write` sit on the deploy job alone.

The catch is that the deploy job only runs on `main`, so these permissions couldn't be tested on the PR branch. The merge itself was the first real test.

## Testing against a real response

The test uses a fixture: a recorded API response for my obsidian-budget-planner-plugin repo. It turned out to be a useful one. The response includes a nested `template_repository` object with its own `stargazers_count` of 4551. My repo has 11. So the test also checks that the function reads the top-level count and not the first one it finds.

A second case simulates a 403 and expects the YAML fallback. I confirmed it does its job: removing the `stargazers_count` guard makes it fail.

I added `tests/fixtures/` to `.prettierignore` so the fixture stays byte-for-byte as GitHub sent it.

Beyond the unit tests:

- `npm run verify` passes: lint, `astro check` with 0 errors, formatting, 18/18 tests, and the build.
- The built `dist/index.html` shows `2 ★` for ai-digest (YAML still says 1) and `11 ★` for the budget plugin.
- `GITHUB_TOKEN=bogus npm run build` gets a 401 for every repo, prints four `[github-stars] … using N from YAML` warnings, completes the build, and the page shows the YAML numbers. This is the failure mode I wanted: noisy logs, working site.

## What I left alone

The `stars` field stays in the YAML schema because it's the fallback. I didn't bump ai-digest's 1 to 2, since the live count wins anyway.

There's a known trade-off. If GitHub is down during a scheduled build, the page falls back to YAML values that nothing keeps current, so an older number can get deployed. I accepted that when I scoped the issue. With the CI token, that only happens during a real outage, and the next weekly build fixes it.

The README needed an update too. Its Tech Stack section said "no build-time API calls," which is no longer true.

## Takeaway

The first GitHub integration on this site was heavier than the problem: an SDK, a personal token, and a build that broke on rate limits. This one is a `fetch`, a timeout, a fallback, and the token Actions already provides. The most valuable part turned out to be the permissions cleanup, which I only noticed because adding a token made me ask who else could read it.


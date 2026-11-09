# Product

The product decisions of `craft`: what its users see, pay or get, and what
the project owes by law or licence. The code's decisions are ADRs, in
[`ARCHITECTURE.md`](ARCHITECTURE.md).

## What it is, and for whom

`craft` is a plugin for Claude Code and Codex. It gives the agent working
rules and skills, so that it works on a project as a careful engineer does.

It is for a solo developer or a small team that keeps its work on GitHub.
The first user is the author.

## Direction

- The rules and the skills are text that a model reads. A rule earns its
  place by a measured run, not by a guess.
- The plugin grows past development: skills for content and against AI slop
  (ADR 0002, #214). One plugin, one namespace `craft:`.
- **Current goal:** M3 · Skills hold in real runs: the skills do what their
  rules say in real runs, and their text is whole in the context (#196,
  #275).

## What it will not do

- Reach a forge or a tracker other than GitHub, until a project of a user
  needs one (#185).
- Add a config format of its own: the project's instruction file holds the
  settings.

## Constraints

- **Law and licence:** MIT. Recorded payloads in `tests/fixtures/` come only
  from public repositories, or from a fake tracker that a test builds.
- **The hosts:** Claude Code caps the context of one hook at 10,000
  characters, and `rules.md` loads through two hooks for each event, one for
  each part. After a compaction, Claude Code keeps only the first 20,000
  characters of each skill (ADR 0006). Codex runs plugin hooks only after the
  person trusts them.
- **Money:** the plugin is free and earns nothing. Its cost is the user's
  tokens: the panel, the second reviewer, the walk of a screen and the evals
  call models.
- **The client:** none. No contract binds the project.

## Open questions

None.

## Decisions

- [0001 GitHub only, until a project on another host needs more](pdr/0001-github-only.md) — accepted; revisit when: a real project on GitLab or Bitbucket needs the plugin
- [0002 A correction of a plugin step goes to the tracker at Finishing, with no tool of its own](pdr/0002-corrections-at-finishing.md) — accepted; revisit when: a session reaches Finishing with a correction and shows no draft, or a host lets a plugin tool's description always load
- [0003 A change to a screen is walked by eye once, before round 1](pdr/0003-ui-walk-by-eye.md) — accepted; revisit when: the first 5 reviews with the walk show 0 findings from it in total
- [0004 Filing puts a low finding straight into Later](pdr/0004-later-at-filing.md) — rejected; revisit when: a tracker that uses craft holds more open low findings with no milestone than one triage approval can take
- [0005 The architecture skill stays whole](pdr/0005-architecture-skill-stays.md) — accepted; revisit when: a run of `tests/architecture_eval.sh` gives an arm with no skill the same count as the arms with the skill on each task

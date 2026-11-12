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
- [0006 The agent asks once whether the person chooses the technologies](pdr/0006-ask-who-chooses-technologies.md) — accepted; revisit when: a person who answered no stops the agent over a technology that it chose, or one who answered yes calls a question too small to ask
- [0007 An assignee says who may take an issue, and the label in progress says that its work runs](pdr/0007-in-progress-by-label.md) — accepted; revisit when: two sessions take one issue because one did not put the label on, or the person asks for a step that takes the label off stopped work
- [0008 A fact that changed after an ADR is accepted is corrected in the ADR, with a dated line that keeps the old words](pdr/0008-adr-fact-corrected-in-place.md) — accepted; revisit when: a review lens or a reader takes a correction for a change of the decision, or misses one that changed it, twice; or a run shows that an agent takes the old words of an `## Updates` line as the current fact
- [0009 The next task and the parallel work come from the goal of the nearest milestone, in at most three lanes](pdr/0009-next-task-from-the-goal.md) — accepted; revisit when: a lane 1 on a real tracker leaves out a task that the goal needs twice, or the person declines the re-plan that a note offers twice
- [0010 A failure that a check or a default in the code keeps its input from is not filed](pdr/0010-ruled-out-failure-not-filed.md) — accepted; revisit when: a finding that the trace ruled out turns out to be a defect that real use reaches, or a tracker that uses craft closes two issues in a month because their input never reaches the code

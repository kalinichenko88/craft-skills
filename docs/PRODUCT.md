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
- **Current goal:** M3 · Skills hold in real runs. The skills do what their
  rules say in real runs: a task goes from take-in to merge with no step left
  for the person, the decision records stay true, and the checks give no
  false result. The `Done when` of the milestone names the issues that the
  goal needs.

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
  each part. An `Explore` subagent of Claude Code gets none (PDR 0012). After a compaction, Claude Code keeps only the first 20,000
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
- [0008 An accepted ADR or PDR says what holds now: a fact or a decision that changed is corrected in its own file, with a dated line that keeps the old words](pdr/0008-adr-fact-corrected-in-place.md) — accepted; revisit when: a review lens or a reader takes a changed decision for a fact, or a fact for a changed decision, twice; or a run shows that an agent takes the old words of an `## Updates` line as the current fact; or a later decision needs a reason that a rewrite took out of a record, twice
- [0009 The next task and the parallel work come from the goal of the nearest milestone, in at most three lanes](pdr/0009-next-task-from-the-goal.md) — accepted; revisit when: a lane 1 on a real tracker leaves out a task that the goal needs twice, or the person declines the re-plan that a note offers twice
- [0010 A failure that a check or a default in the code keeps its input from is not filed](pdr/0010-ruled-out-failure-not-filed.md) — accepted; revisit when: a finding that the trace ruled out turns out to be a defect that real use reaches, or a tracker that uses craft closes two issues in a month because their input never reaches the code
- [0011 A finding in the task's module that needs only a choice goes to the person as a question](pdr/0011-choice-in-the-module-asked.md) — accepted; revisit when: of the first 5 real questions by this rule, the person calls 2 not worth a question, or answers 2 of them with "file it"
- [0012 An Explore subagent of Claude Code gets no rules](pdr/0012-explore-subagent-gets-no-rules.md) — accepted; revisit when: a transcript of an `Explore` subagent shows a write of `gh`, a commit or a push that its prompt did not ask for, or 10 of 100 subagents in 14 days are `Plan`
- [0013 A review agent's guess about a case that the text of a skill does not name is declined until a run shows the failure](pdr/0013-unseen-case-declined.md) — accepted; revisit when: a gap that the loop declined fails in at least 3 of 10 runs later, twice, or a person asks twice in a month for a declined case to be run and added
- [0014 The hook shows the number and the title of an issue that a prompt names alone](pdr/0014-hook-shows-issue-title.md) — accepted; revisit when: Claude Code stops giving a message before a tool call as a narration, or a take-in from a prompt that is not the issue alone shows a narration with no title, twice
- [0015 An update of craft reaches each host at a release, not at a push](pdr/0015-update-at-a-release.md) — accepted; revisit when: a fix waits on `main` for more than 7 days with no release, twice, or a person asks for the update of each push in Claude Code

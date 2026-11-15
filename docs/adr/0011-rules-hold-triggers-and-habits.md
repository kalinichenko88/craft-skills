# 0011 rules.md holds the triggers of the skills and the habits of each turn

- Status: accepted
- Date: 2026-11-15

## Context

`hooks/rules.sh` gives all of `rules.md` on SessionStart (startup, clear and
compact) and on SubagentStart (ADR 0004). In the 14 days to 2026-11-15, the
count of `.claude/skills/sessions` gives 2,980 transcripts. At the 11,672
characters of 2026-11-15 in each, that is about 35 M characters, with no
compaction counted: an estimate, since the file grew from 9,664 characters
in those days. ADR 0009 gives it a budget of 6,000 characters.

About a third of the text was neither the trigger of a skill nor a habit for
each turn (#413). *The Boy Scout Rule* repeated *In the task's module and
clear* of `skills/github/filing.md`. *A bug fix ships with its test* held a
story and the steps of the count. *GitHub* repeated parts of `filing.md`.
The rest of the cut, to about half of the text, shortens the rules that
stay.

`rules.md` does not go away. One sentence in it moved #253 from 0 of 7 runs
to 5 of 5. A skill that only its description calls was not invoked in 56 %
of the eval cases of Vercel
(https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals).

These are the reasons and the stories that left the text. They hold for the
rules that stay:

- **The count before a bug fix.** Red-then-green proves that the test runs
  the code, not that the case exists. A "list items run together" bug was
  filed from a hand-written `<li>a</li><li>b</li>`, tested green and shipped.
  The sources never gave two block tags with no whitespace between them, 0 of
  100 bodies. So the fix changed no table that it claimed to fix, and put a
  blank line inside 6 of 10 real lists.
- **A guard on each surface.** A fix of the surface that the report named,
  with its siblings left, is how the bug comes back under a new name.
- **The platform first.** Runtimes ship faster than training data, so the
  check reads the current docs: `Intl.NumberFormat`, not a hand-written
  currency formatter; `structuredClone`, not a deep-clone package.
- **Code speaks English.** Mixed-language symbols are ungreppable, and split
  a codebase into dialects. `git log` and `git blame` are read long after the
  team that wrote them. A key stays `greeting.ru`; the string that it holds
  does not have to be English.
- **An issue by its title.** The person does not keep the tracker in mind,
  and a bare number sends them to GitHub.
- **The Boy Scout Rule** is the Scouts' campground rule as Robert C. Martin
  put it in *Clean Code*: each check-in leaves the module a little better
  than the check-out found it, and a codebase that only gets that care does
  not rot.

## Options considered

- Give each sentence one label, and keep only the triggers and the habits:
  the text goes under its budget.
- Shorten in place, as PR #163 did: it frees a few hundred characters, and
  the next rules fill them.
- Move the general habits into skills, as ADR 0004 considered: a habit that
  must hold in each turn then fires only when a description matches.
- A short part for an `Explore` or `Plan` subagent only (#414): it cuts the
  cost of one kind of subagent, and needs a trimmed text first.
- A machine check in place of the trailer rule (ADR 0009, step 4): Claude
  Code's setting for the trailer is the person's, not the plugin's, and a
  hook that refuses such a commit is a change of its own.

## Decision

We will give each sentence of `rules.md` one label, and keep two of them:

- a trigger of a skill: at moment X, invoke skill Y;
- a habit for each turn, in a few sentences: when X, do Y, which gives Z.

The other labels leave the text:

- A procedure of one moment goes into the skill of that moment. The steps
  of a procedure whose moment has no skill, as the subagent that counts
  before a bug fix, stay as one sentence, and so do the steps that a skill
  already cites in the global prompt, as the subagent that finds the docs
  that a change makes false.
- A story or a reason goes into an ADR: this one, for the text of
  2026-11-15.
- A repeat of a skill is removed, and the trigger sends the agent to read
  it: the conditions of the Boy Scout Rule, in `filing.md`. A repeat stays
  when the agent can act with no skill loaded: the trailer rule, though
  *Commits* of `skills/github/SKILL.md` holds it too. In 14 days of
  transcripts on one computer, 44 of 78 subagents that ran `git commit` in
  other projects loaded no github skill.
- A rule for one repository goes into that repository's instruction file:
  the clause for a checkout of `craft-skills` went to `.claude/CLAUDE.md` and
  `AGENTS.md`.

A sentence that `tests/rules_test.sh` pins stays word for word. A new
sentence needs a failing run first (ADR 0009).

The rest of the cut shortens the rules that stay. These parts left with no
new place:

- the gate: the sentence that "should pass" is not a result;
- the bug fix: "not the internals of the fix", "pretty-printing", "not a
  string typed to make the assertion pass", and the brief of the counting
  subagent: the sample size and the shape, "the count and the ids", "write
  the case against one";
- the platform: "(context7, the release notes)", "the newest API the pinned
  version actually supports", and its examples;
- English code: its examples;
- an issue by its title: "or which area it touches", the column of a table,
  the goal of a milestone;
- the docs: the follow-up for a broader sweep, and of the brief of the
  subagent: the sentence and why, "none" with the files that it read, and
  "The edits are yours";
- the review: "It sets every step, from the level to the pull request";
- GitHub: "Do not derail the task", twice;
- the mark `(always)` on each heading: the whole file is always on.

## Consequences

Good: `rules.md` has 5,894 characters, under the 6,000 of ADR 0009, about
half of what each session and each subagent got before. The rules that stay
are the ones that a session needs before a skill loads.

Bad: a habit has fewer words and no examples, so its behaviour can change in
runs that no eval covers, as the title next to an issue's number. The
reasons are out of the text that a run reads. A skill that took a rule must
keep it: when the skill drops it, the rule is gone from the plugin.

## Invariants

None: no `Check:` line sees a `.md` file.

## Confirmation

Review only for the labels. `tests/text_size.txt` records the size of
`rules.md`, and `tests/text_size_test.sh` checks it; `tests/rules_test.sh`
holds the sentences that it pins. The evals
that `CONTRIBUTING.md` names for the changed sections ran on the base and on
the new text; the pull request of #413 gives their counts.

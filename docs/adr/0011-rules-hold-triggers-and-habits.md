# 0011 rules.md holds the triggers of the skills and the habits of each turn

- Status: accepted
- Date: 2026-11-15

## Context

`hooks/rules.sh` gives all of `rules.md` on SessionStart (startup, clear and
compact) and on SubagentStart (ADR 0004). In the 14 days to 2026-11-15, the
count of `.claude/skills/sessions` gives 2,980 transcripts, so `rules.md`, at
11,672 characters, put about 35 M characters into context. ADR 0009 gives it
a budget of 6,000 characters.

About a third of the text was neither the trigger of a skill nor a habit for
each turn (#413). *The Boy Scout Rule* repeated *In the task's module and
clear* of `skills/github/filing.md`. *A bug fix ships with its test* held a
story and the steps of the count. *GitHub* repeated parts of `filing.md`,
and its trailer rule repeated *Commits* of `skills/github/SKILL.md`.

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
  the text goes under its budget, and each rule keeps one place.
- Shorten in place, as PR #163 did: it frees a few hundred characters, and
  the next rules fill them.
- Move the general habits into skills, as ADR 0004 considered: a habit that
  must hold in each turn then fires only when a description matches.
- A short part for an `Explore` or `Plan` subagent only (#414): it cuts the
  cost of one kind of subagent, and needs a trimmed text first.

## Decision

We will give each sentence of `rules.md` one label, and keep two of them:

- a trigger of a skill: at moment X, invoke skill Y;
- a habit for each turn, in one to three lines: when X, do Y, which gives Z.

The other labels leave the text:

- A procedure of one moment goes into the skill of that moment. A procedure
  whose moment has no skill, as the count before a bug fix, stays as one
  sentence.
- A story or a reason goes into an ADR: this one, for the text of
  2026-11-15.
- A repeat of a skill that loads at that moment is removed: the tests of the
  Boy Scout Rule (`filing.md`) and the trailer rule (*Commits* of
  `skills/github/SKILL.md`).
- A rule for one repository goes into that repository's instruction file:
  the clause for a checkout of `craft-skills` went to `.claude/CLAUDE.md` and
  `AGENTS.md`.

A sentence that `tests/rules_test.sh` pins stays word for word. A new
sentence needs a failing run first (ADR 0009).

## Consequences

Good: `rules.md` has 5,993 characters, under the 6,000 of ADR 0009, about
half of what each session and each subagent got before. The rules that stay
are the ones that a session needs before a skill loads.

Bad: a habit has fewer words and no examples, so its behaviour can change in
runs that no eval covers, as the title next to an issue's number. The
reasons are out of the text that a run reads. A skill that took a rule must
keep it: when the skill drops it, the rule is gone from the plugin.

## Invariants

None: no `Check:` line sees a `.md` file.

## Confirmation

Review only for the labels. `tests/text_size_test.sh` holds the size of
`rules.md`, and `tests/rules_test.sh` the sentences that it pins.

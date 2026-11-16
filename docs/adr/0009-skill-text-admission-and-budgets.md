# 0009 A case gets a sentence in skill text only after a failing run, and each text has a size budget

- Status: accepted, narrowed by 0010
- Date: 2026-11-15

## Updates

- 2026-11-15 #412: Consequences, Bad. Was: "Until the checks exist, review alone keeps the rule, and compares a text with its size at the base (#412, #417)".
- 2026-11-15 #412: Confirmation. Was: "The record of sizes and its check in `make check`: #412".
- 2026-11-15 #413: Context. Was: "`rules.md`, 11,672 characters, goes into each session and each subagent".
- 2026-11-15 #413: Options considered. Was: "five side files, three `SKILL.md` files and `rules.md` are past their numbers".
- 2026-11-15 #414: Context. Was: "goes into each session and each subagent".
- 2026-11-15 #414: Decision, the table of budgets. Was: "It goes into each session and each subagent".
- 2026-11-16 #417: Consequences, Bad. Was: "Review alone keeps the admission rule until review-loop asks for a failing run (#417)".
- 2026-11-16 #417: Confirmation. Was: "#417 puts the ask for a failing run into review-loop, and #418 gives the rule to an agent that edits the text of a skill".

## Context

The text of the skills is the product (`docs/ARCHITECTURE.md`). Each bug
from a real run added a sentence for its case to a skill, and the review of
each fix found a narrower case in its next round. No record said when a case
earns a sentence.

ADR 0006 caps each `SKILL.md` at 20,000 characters, and lets a file under
the cap grow up to it. The cap does not see where the cost is. In 14 days
the github skill put 9.7 million characters of its `SKILL.md` into context,
and 15.2 million of its side files. `rules.md`, 11,672 characters on
2026-11-15, goes into each session and each subagent, but an `Explore`
subagent of Claude Code (PDR 0012). A side file is a file beside a `SKILL.md`
that the skill sends the agent to read; a `README.md` is not one. On
2026-11-15, five side files have more than 10,000 characters, the largest
19,704, and three `SKILL.md` files have more than 15,000.

The study of 2026-11-15
(`docs/research/2026-11-15-skill-text-breadth.md`) compared the advice of
Anthropic and OpenAI with the project's runs. Both vendors advise against a
list of edge cases in a prompt, and for a rule that follows a measured
failure. In the project, one reported gap failed 0 of 10 runs and was
closed (#186), and a gap that a review found failed 9 of 10 and was fixed
(PR #261). About a third
of 19 open issues were false results of the project's own evals or gaps in
the scenario texts. In a measurement by OpenAI, 23 of 108 cases changed
their result between repeats of one configuration, so 1 failure in 10 runs
cannot be told from noise.

## Options considered

- An admission rule in an ADR, a budget for each kind of text, and a record
  of each text's size that a check holds: the rule and the reasons stay out
  of the text that an agent reads in a run. The checks and the one rule for
  a review are separate work (#412, #417, #418).
- The admission rule in `rules.md` or in each skill: each session then pays
  for a rule that only an edit of skill text needs.
- A hard cap for each budget now: five side files, three `SKILL.md` files
  and, on 2026-11-15, `rules.md` are past their numbers, and of the numbers
  below only the 20,000 of ADR 0006 is measured.
- ADR 0006 alone: a `SKILL.md` under the cap grows with no decision, and the
  side files, the flows and `rules.md` have no number.
- Supersede ADR 0006: its cap and the reason for it hold. One point of it
  changes, so it gets the Status `accepted, narrowed by 0009`, the form that
  the person decided on 2026-11-13 (#267).

## Decision

We will admit a sentence for a case into the text of a skill, a side file or
`rules.md` by these steps. They go in order, and the first step that holds
decides:

1. The failure does not show on the base text in at least 3 of 10 runs, with
   a counter checked on a known positive: write nothing, and close. This
   step does not stop a case of data loss or of a security hole.
2. An eval or the text of a scenario gives the failure, not the skill: fix
   the eval or the scenario.
3. The skill was not loaded, or its side file was not read: fix the load —
   the trigger, the path, the step of reading — not the rule.
4. A machine can check the behaviour, and it has no exception: a script, a
   validator or a hook. Remove the prose about it.
5. The case is an input of a script: a test of the script, with no prose.
6. A rule covers the class but is unclear: rewrite that rule in place, with
   its trigger, action, result, scope or reason. No new sentence.
7. The behaviour depends on a condition: one condition on a sign that can be
   seen, in an ordered list, at the point of the decision, in the file of
   the moment where it occurs. Not a rule and an exception.
8. Else a new sentence, with a run that fails before it and a run that
   passes after it, no worse on the neighbouring cases, and a search for a
   sentence to remove in the same pull request.

A false fact in a text, as a wrong path or a wrong number, is not a case: it
is corrected at once.

We will keep these budgets, in characters as `jq -Rs length` counts them:

| Text | Budget | Reason |
| --- | --- | --- |
| A `SKILL.md`, cap | 20,000 | ADR 0006: the host keeps them after a compaction. Measured |
| A `SKILL.md`, target | 15,000 | Cost: 5,000 model tokens at 3 characters a token |
| A side file | 10,000 | Set by the study, not measured: Anthropic warns that an agent reads a long file in part |
| A flow: the files that one scenario reads | No growth; a target after the map of its files (#415) | The side files of github cost more than its `SKILL.md` |
| `rules.md` | 6,000 | It goes into each session and each subagent, but an `Explore` subagent of Claude Code |

Of these numbers, only the cap of 20,000 fails a check. The others are
targets: a text past its target fails nothing. The host's cap of 10,000
characters on each of the two parts of `rules.md` holds beside them, with
its check (ADR 0004): this ADR changes no decision of ADR 0004.

We will record the size of each `SKILL.md`, each side file and `rules.md`
in the repository, and of each flow that has a named list of its files. The
target of a flow goes into that record when its map gives one. A text that grows past its recorded size fails
`make check` until the same pull request changes the record. This narrows
one point of ADR 0006: there, a `SKILL.md` under the cap can grow up to
20,000 characters with no decision. The cap of ADR 0006, its count and its
debt list hold.

## Consequences

Good: a finding that asks for a new case is a hypothesis until a run fails,
so a review round cannot add a sentence by its report alone. Growth of a
text past its record is a line in a diff that a reviewer sees. The reasons and the numbers
are in one place, out of the text that a run reads.

Bad: step 1 costs 10 runs before an edit, and step 8 the runs after it. The
numbers other than 20,000, and the 3 of 10 of step 1, have no measurement
behind them and can be wrong. A
record of sizes changes in most pull requests that edit a skill, and two
branches that edit one text conflict on its line. review-loop keeps only
a part of the admission rule: it declines a finding that asks for a new
case until a run or a real session shows the failure, and makes no run
itself (PDR 0013). The rule
moves cases into evals and tests, and those have defects of their own.

## Invariants

None: no `Check:` line sees a `.md` file.

## Confirmation

`tests/rules_test.sh` for the cap of 20,000. The record of sizes is
`tests/text_size.txt`, and `tests/text_size_test.sh` checks it in
`make check`, as ADR 0010 narrows it. The admission rule: review only;
review-loop declines a finding that asks for a new case with no failing
run (#417, PDR 0013), and `.claude/rules/skill-text.md` gives the rule to
an agent that edits the text of a skill in this repository (#418).

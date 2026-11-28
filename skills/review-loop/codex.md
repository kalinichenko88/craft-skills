# A second model

*The level* and *The findings* are sections of `SKILL.md`, next to this file,
and a step with a number is a step of *The rounds* there.

In Claude Code, Codex reads the whole branch once, at each level of a code
review. Start it in the background when the last pass starts. When the loop had one
round, start it when that round confirms no defect and its nits are
committed. When step 4 stops the rounds, run it when the nits of round 3 are
committed.
There, its findings start no round: leave each confirmed defect unfixed, as
step 4 leaves the defect of round 3, and make its nits one commit that no
round reads. Then go on as step 4 says. This step runs once in a review: in
a later count of rounds, and after the rounds that the person asks for at
the merge question, it does not run again. Change no file while Codex runs.

```bash
bash <dir>/scripts/codex-review.sh <base>
```

`<base>` is the base of step 1. Run it from the working tree of the branch.
The script prints Codex's report in the lines of the code lens, after its
own check of the report. Each finding goes through *The findings*, also one
in the text of a skill or a prompt.

- Exit 2: the script did not run Codex. When the call is wrong, as a wrong
  base, working directory or argument, correct it and run the script again.
  Otherwise, go on without Codex.
- `skipped:`: the Codex CLI is not installed or not logged in. Go on without
  Codex.
- Any other error: the run failed, as when Codex fails, writes no report or
  cuts it. Go on without Codex.

When you go on without Codex, give the reason in the summary.

Why: on three branches of this plugin that a `/code-review` loop had
finished, Codex found three defects that no round had reported, in 45 to 74
seconds each. Why at each level: no reader on Opus named the defect of #90
in more than 20 runs, and Codex named it in 2 of 2. Why at the step 4 stop: in five `xhigh` reviews from 2026-10-26
to 2026-10-28, three stopped at step 4. With no last pass, Codex read none of
the three, the branches where the rounds kept finding defects.

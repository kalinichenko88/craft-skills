# 0007 CI runs the text eval on the scenario rows that a pull request changes

- Status: accepted
- Date: 2026-11-11

## Context

ADR 0003 left one gap: a change of a flow edits two texts, the skill and its
scenario, and only the review ties them. `tests/scenarios_text_eval.sh` (#243,
#294) closes the gap for the text: it reads the skill's files against the
scenario file of each row, and gives LOST for an item that the change drops.
But it calls the model, so `make check` runs only its checks on recorded runs
(I-7), and `CONTRIBUTING.md` asks a person to run it. No one did: #281 and
#257 changed the files that the eval reads, and neither records a run (#307).

The counts, for the pull requests merged from 2026-10-27 to 2026-11-10: 33
changed a file of a row, 3 rows each on average. The `pull_request` runs of
`check.yml` show one push for 57 of them, two for 5 and three for 1, as the
review runs before the pull request opens. Ten Haiku sessions,
one row, cost a median of $0.24 at API prices in 13 recorded runs; two of them
cost $1.29 and $1.74. At each push, the rows that the pull request changes come
to 124 row runs in those 15 days, about $14 to $24 a week.

## Options considered

- A job of `check.yml` that runs the eval with `--changed` at each push to a
  pull request, with a secret, and fails on a LOST item: every pull request
  gets the check, from either host or a person; tokens at each push.
- A Claude Code hook before `gh pr create`: no secret, but a Codex session, a
  person and each push after the pull request opens get no run.
- A line in `.claude/CLAUDE.md` and `AGENTS.md`: no code, but a step that an
  agent can skip, as the 0 of 2 runs show for the line in `CONTRIBUTING.md`.
- `anthropics/claude-code-action` with a prompt that runs the eval: the same
  secret, but an agent session on top of the ten runs of a row, with tokens of
  its own and a step that a model can do wrong. The eval needs only the CLI,
  which the `check` job installs already.

## Decision

We will run `tests/scenarios_text_eval.sh --changed` in a job of
`.github/workflows/check.yml` at each push to a pull request from this
repository. The job reads the secret `CLAUDE_CODE_OAUTH_TOKEN`, which
`claude setup-token` prints, so the runs count against the subscription of
its owner. It fails when the eval gives a LOST item, and a new push cancels
the run that is still going. `--changed` runs each row with a file that
differs between the merge base with `origin/main` and the tree of the pull
request. The live eval of the take-in, `tests/scenarios_eval.sh`, stays a run
by hand.

## Consequences

Good: a change of a skill that drops what a scenario needs fails its pull
request, with no step that a person or an agent must remember. A new scenario
file with no row fails it too, as the eval stops on it. A pull request that
changes no file of a row costs a runner and no token.

Bad: the repository keeps a secret, and a token that expires or is missing
makes the job fail with no answer. A pull request from a fork gets no secret
and no check. A LOST item can be noise of the model: rerun the job. A push
runs every changed row again, also when it changes only a test.

## Invariants

None. I-7 holds: the job is outside `make test`.

## Confirmation

`tests/scenarios_text_checks_test.sh` checks with a stub `claude` which rows
`--changed` runs. The job itself is review only.

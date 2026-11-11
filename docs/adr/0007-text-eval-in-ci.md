# 0007 CI runs the text eval on each scenario row whose skill files a pull request changes

- Status: accepted
- Date: 2026-11-11

## Updates

- 2026-11-11 #324: Consequences, Bad. Was: "nothing makes the merge wait for the job: `main` has no required check, and the merge of `craft:github` reads no check (#309)".
- 2026-11-11 #335: Consequences, Bad. Was: "A LOST item can be noise of the model, though in the measure of the eval's header no item outside the cut lines was LOST at five runs: rerun the job".

## Context

ADR 0003 left one gap: a change of a flow edits two texts, the skill and its
scenario, and only the review ties them. `tests/scenarios_text_eval.sh` (#243,
#294) closes the gap in one direction: it reads the skill's files against the
scenario file of each row, and gives LOST for an item that a change of the
skill drops. But it calls the model, so `make check` runs only its checks on
recorded runs (I-7), and `CONTRIBUTING.md` asks a person to run it, as it asks
for the live eval `tests/scenarios_eval.sh`. #281 and #257 changed the files
after which it asks for a live run, and neither records one (#307). Since #288
added the text eval, five merged pull requests changed a file of a row, all
of them scenario files only: #299 to #302 record a run by hand, and #308 does
not.

The counts, for the 63 pull requests merged from 2026-10-27 to 2026-11-10:
27 changed a skill file of a row, 3 to 4 rows each. The `pull_request` runs of
`check.yml` show one push for 57 of the 63, two for 5 and three for 1, as the
review runs before the pull request opens. Ten Haiku sessions, one row, cost a
median of $0.24 at API prices in 13 recorded runs; two of them cost $1.29 and
$1.74. At each push, the rows whose skill files the pull request changes come
to 109 row runs in those 15 days, about $12 to $21 a week.

## Options considered

- A job of `check.yml` that runs the eval with `--changed` at each push to a
  pull request, with a secret, and fails on a LOST item: every pull request
  gets the check, from either host or a person; tokens at each push.
- A Claude Code hook before `gh pr create`: no secret, but a Codex session, a
  person and each push after the pull request opens get no run.
- A line in `.claude/CLAUDE.md` and `AGENTS.md`: no code, but a step that an
  agent can skip, as the live eval shows for the line in `CONTRIBUTING.md`.
- `anthropics/claude-code-action` with a prompt that runs the eval: the same
  secret, but an agent session on top of the ten runs of a row, with tokens of
  its own and a step that a model can do wrong. The eval needs only the CLI,
  which the `check` job installs too.
- An API key with a cost cap, as #307 names: the same job, but each run is
  paid apart from the subscription that the work already uses.

## Decision

We will run `tests/scenarios_text_eval.sh --changed` in a job of
`.github/workflows/check.yml` at each push to a pull request from this
repository. The job reads the secret `CLAUDE_CODE_OAUTH_TOKEN`, which
`claude setup-token` prints, so the runs count against the subscription of
its owner. It fails when the eval gives a LOST item. `--changed` runs each row
with a skill file that differs between the merge base with `origin/main` and
the tree of the pull request. A change of a scenario file alone runs no row:
both sides read the scenario file of the working tree, so its run gives no
LOST but noise. The live eval of the take-in, `tests/scenarios_eval.sh`, stays
a run by hand.

## Consequences

Good: a change of a skill that drops what a scenario needs makes its pull
request red, with no step that a person or an agent must remember. A new
scenario file with no row makes it red too, as the eval stops on it. A pull
request that changes no skill file of a row costs a runner and no token.

Bad: the ruleset of `main` requires the job, and the merge of `craft:github`
waits for the checks of the pull request: a job that fails blocks the merge.
The repository keeps a secret. A token that expires or is missing, or a spent
limit of the subscription, makes the job fail; it prints the reason that the
CLI gives. Each person with write access to the repository can read the
token, with a branch that changes the eval. A pull request from a fork gets no
secret and no check. A row with a LOST item gets a second set of runs, and an
item stays LOST only when both sets lose it. A renamed file of a row gives the
base no line, so no item that it produces can be LOST in that pull request;
no file of a row was renamed up to 2026-11-10. A push runs every changed row
again, also when it changes only a test.

## Invariants

None. I-7 holds: the job is outside `make test`.

## Confirmation

`tests/scenarios_text_checks_test.sh` checks with a stub `claude` which rows
`--changed` runs. The job itself is review only.

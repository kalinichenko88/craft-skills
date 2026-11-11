# 0006 Each SKILL.md stays within the 20,000 characters that a compaction keeps

- Status: accepted
- Date: 2026-11-09

## Updates

- 2026-11-11 #284: Consequences, Good. Was: "The debt list holds two files, review-loop (#283) and architecture (#284), and neither can grow".
- 2026-11-11 #284: Consequences, Bad. Was: "each sentence added to review-loop or architecture needs a cut in the same file until its split".

## Context

The text of the skills is the product (`docs/ARCHITECTURE.md`), and nothing
limited its size. On 2026-11-09 the nine `SKILL.md` files had from 8,291 to
33,562 characters (#275).

When Claude Code compacts a conversation, it attaches the last load of each
skill again, "keeping the first 5,000 tokens of each", 25,000 tokens in all
([skills docs](https://code.claude.com/docs/en/skills), *Skill content
lifecycle*). These tokens are not the model's: Claude Code 2.1.321 counts 4
characters a token. So it keeps the first 20,000 characters of a skill, and
cuts the rest with the note "truncated for compaction; use Read on the skill
path if you need the full text". In the local transcripts of one computer,
counted on 2026-11-09, every copy of architecture (18 of 18) attached after a
compaction ends at 20,000 characters with that note, and so do 26 of 35
copies of review-loop. Every copy of the other seven skills is whole, github
up to 17,754 characters. The model's own cost is about 3 characters a token
on Opus 5.5: 22,233 characters of architecture took about 7,400 tokens.

The rest of a cut skill is lost to the agent: its steps run only if the
agent reads the file again. Codex was not measured.

## Options considered

- 20,000 characters on each `SKILL.md`, from the host's cut: two files go on
  a debt list. The number has a reason that a reader can check again.
- 15,000 characters, from 5,000 model tokens at 3 characters a token: four
  files go on the list, github among them, which #10 split by moment already.
  The host does not cut at 15,000, so the reason is cost, not the loss of
  text.
- Lines, as I-8 caps a code file: the context and the cut depend on the
  characters, not on the lines.
- A `chars` check kind in `invariants.sh`: bash, git and awk count bytes or
  characters by locale, and I-2 forbids `jq` there; `invariants.sh` has 286
  of its 330 lines; and the `.md` files are data to the checks.
- Real tokens from the API: a test that calls the network breaks I-7.
- A line in the `lint` target of the `Makefile`: a debt list with sizes does
  not fit a recipe line.

## Decision

We will cap each `skills/*/SKILL.md` at 20,000 characters, as `jq -Rs
length` counts them. The whole file counts: its front matter, which the load
leaves out, pays for the header and the arguments that the load adds. A file
over the cap is on a debt list in the check, with its size and its debt
issue: it must not grow past that size, and it leaves the list when it is
within the cap. A split follows the github skill: `SKILL.md` keeps the
trigger, the table of moments with its *Read first* column, and the steps
that each run takes.

## Consequences

Good: the cap has a number that the host sets, and a test fails before a
skill loses its end in a compaction. The debt list holds review-loop (#283),
which cannot grow; architecture left it with its split (#284).

Bad: each sentence added to review-loop needs a cut in the same file until
its split. The files beside `SKILL.md` and the text of a
whole flow have no cap (#280). The number moves when Claude Code changes its
budget or its count of a token.

## Invariants

None: no `Check:` line sees a `.md` file.

## Confirmation

`tests/rules_test.sh`, beside the cap on the two parts of `rules.md`.
`/sessions` counts the compactions after each load of a skill.

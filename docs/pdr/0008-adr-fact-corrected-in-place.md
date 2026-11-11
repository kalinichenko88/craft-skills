# 0008 A fact that changed after an ADR is accepted is corrected in the ADR, with a dated line that keeps the old words

- Status: accepted
- Level: feature
- Date: 2026-11-11

## Decision

We will let `craft:architecture` correct a sentence of an accepted ADR that
a later fact made false, when the decision of the ADR still holds. The
sentence is corrected in place, and a line under `## Updates`, after the
Status and Date lines, gives the date, the pull request, the section and the
old words. The Status stays `accepted`. A change of what the decision
commits to stays a new ADR that supersedes the old one, however few words it
changes. The review lens accepts the correction, and reports an ADR that a
change made false.

## Rests on

- The rule before this one left 3 of 3 such sentences false in this
  repository: ADR 0003 (#236, PR #270, PR #271) and ADR 0007 (PR #324,
  PR #335). Nobody wrote a superseding ADR for a fact.
- A stale sentence misleads a model that reads the ADR: with ADR 0007 as it
  was, beside `docs/ARCHITECTURE.md` and ADR 0008, Sonnet gave the stale
  answer to both questions in 5 of 5 runs, and Haiku the right one to both
  in 3 of 10. Appended `## Updates` with "Was: … Now: …" and the
  corrected form each gave 10 of 10 on Haiku and 5 of 5 on Sonnet
  (2026-11-11, `claude -p` with no tool, #343).
- An agent can read an excerpt of an ADR, as a grep hit: in the appended
  form that excerpt is the stale sentence with no mark. No run measured this.
- Joel Parker Henderson's ADR guide: "Don't alter existing information in an
  ADR. Instead, amend the ADR by adding new information", with a date.
  AWS, Fowler and Microsoft keep an accepted ADR immutable; Google Cloud
  allows an adjustment that keeps the previous decision and says why.
- The person's choice on #343, after the panel of Fable and Codex.

## Revisit when

A review lens or a reader takes a correction for a change of the decision,
or misses one that changed it, twice; or a run shows that an agent takes the
old words of an `## Updates` line as the current fact.

## Options considered

- A new ADR that supersedes the old one for each fact: about 5,000
  characters, a second reader and a review for a few sentences, and nobody
  wrote one.
- Append only, `## Updates` with "Was: … Now: …", the body as it was: the
  stale sentence stays, with no mark, for an agent that reads an excerpt.
- An edit in place with a status `revised YYYY-MM-DD` and no record in the
  file: no source has that status, and the file keeps no trace of the old
  words.
- The rule as it was, with the facts only in the living documents: each agent
  reads the false sentence.
- A correction in place with a dated `## Updates` line that keeps the old
  words: chosen.

## Links

#343, #267, #284, ADR 0007, `skills/architecture/SKILL.md`,
`skills/review-loop/architecture-lens.md`, `skills/product/store.md`

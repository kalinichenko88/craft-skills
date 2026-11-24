# 0008 An accepted ADR or PDR says what holds now: a fact or a decision that changed is corrected in its own file, with a dated line that keeps the old words

- Status: accepted
- Level: feature
- Date: 2026-11-11

## Updates

- 2026-11-24 #405: Decision. Was: "We will let `craft:architecture` correct a sentence of an accepted ADR that a later fact made false, when the decision of the ADR is the same".
- 2026-11-24 #487: Decision. Was: "The Status stays, and no record supersedes another".
- 2026-11-24 #492: Links. Was: "`skills/architecture/SKILL.md`".

## Decision

We will keep each accepted ADR of `craft:architecture` and each PDR of
`craft:product` true to what holds now, in its own file. A sentence that a
later fact made false is corrected in place, in the change that makes it
false; else in a later change, as its task or as a finding outside its
task. A changed decision rewrites the record in place: an ADR by the steps
of a decision, a PDR only after the person changes it, in the pull request
of the work that carries it out. The rewrite changes the title and the
sections that the decision changes, and puts the old choice into *Options
considered* with the reason that it was dropped. Each correction adds a
line under `## Updates`, after the Status and Date lines, with the date, the
source, the section and the old words; for a changed decision, the
sentence of *Decision* that held the old choice. The Status stays, but an
ADR's Status `accepted, narrowed by NNNN` becomes `accepted` when the
rewrite takes the narrowed point into the ADR, and no record supersedes
another. A sentence is a fact when code that kept the ADR keeps it after the
correction, and code that broke it still breaks it, or, for a PDR, when what
the users see, pay or get, and what the company owes, stay the same. When the false fact was a reason for the decision, an issue asks
whether the decision is still right. *Got in the way* of a PDR records only
what went around the decision, as a task or an ADR. The review lens reports an edit of an
ADR at the base with no `## Updates` line, and an ADR that a change made
false.

## Rests on

- The rule before #343 left each such sentence false in this repository, 6
  sentences of 3 accepted ADRs: two of ADR 0003 (#236 and PR #270, PR #271),
  two of ADR 0007 (PR #324, PR #335), and two sizes of ADR 0004 that nobody
  reported, found in the review of #343. ADR 0003 was superseded later by
  ADR 0008, when the way to check a run changed too.
- A stale sentence misleads a model that reads the ADR: with ADR 0007 as it
  was, beside `docs/ARCHITECTURE.md` and ADR 0008, Sonnet gave the stale
  answer to both questions in 5 of 5 runs, and Haiku the right one to both
  in 3 of 10. Appended `## Updates` with "Was: … Now: …", and the form of
  this decision (the sentence corrected, with a line that keeps only the old
  words), each gave 10 of 10 on Haiku and 5 of 5 on Sonnet
  (2026-11-11, `claude -p` with no tool, #343).
- An agent can read an excerpt of an ADR, as a grep hit: in the appended
  form that excerpt is the stale sentence with no mark. No run measured this.
- The frozen PDR did not hold, 2026-11-24: 3 of 14 accepted PDRs of this
  repository took a correction in place with an `## Updates` line against
  the rule (PDR 0002, PDR 0003, PDR 0010), and 0 of 15 PDRs were
  superseded. Two kept a false sentence: this PDR, whose clause on a
  superseding ADR #267 made false, recorded under *Got in the way*, and two
  citations of PDR 0004, recorded under *Checked*. In another project, in
  13 days of planning, the person's decisions made 5 sentences of one
  accepted PDR false, and it collected 3 lines in *Got in the way* and 3 in
  *Checked* (#405).
- 27 lines under `## Updates` in 7 of 12 ADRs of this repository, 13 days
  after #344.
- Joel Parker Henderson's ADR guide reports that mutability worked better
  for its teams: they insert new information into the existing ADR, with a
  date stamp. The same guide also asks not to alter existing information.
  AWS, Fowler and Microsoft keep an accepted ADR immutable; Google Cloud
  allows an adjustment that keeps the previous decision and says why. PEP 1
  keeps a Draft open to change; an accepted PEP is in general no longer
  substantially modified, and a later PEP supersedes it.
- The person's choice on #343, and on #405 of 2026-11-24, each after the
  panel of Fable and Codex. On #405: two records of one decision, one of
  them stale, do not stay in a repository. A decision that the person
  changes, as a UI library after a talk with a designer, or an access that
  only reads and becomes a full integration, is rewritten in its file, in the
  pull request of the work. The same holds for an ADR.
- The person's choice on #487, 2026-11-24: on a rewrite that took the
  narrowed point in, 10 of 10 Opus runs on ADR 0006 kept the Status
  `accepted, narrowed by 0009`, and 0 of 10 with the clause (`claude -p`
  with no tool). GitHub code search found that Status in no other ADR.

## Revisit when

A review lens or a reader takes a changed decision for a fact, or a fact for
a changed decision, twice; or a run shows that an agent takes the old words
of an `## Updates` line as the current fact; or a later decision needs a
reason that a rewrite took out of a record, twice.

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
- A correction in place of a fact only, and a new record that supersedes
  the old one for a changed decision, or marks it `accepted, narrowed by
  NNNN` (#343, #267): dropped on #405. The old record stays in the
  repository with a decision that no longer holds, and nobody wrote a
  superseding PDR.
- For a PDR, a rewrite of the decision in place only while no user and no
  outside document rests on it: a judgement with no sign in the store, and
  0 of the 15 PDRs of this repository would take it.
- For a PDR, a rewrite in place only while its title stays true: a changed
  decision, as another UI library, makes the title false.
- The Status as it is on each rewrite, also `accepted, narrowed by NNNN`:
  dropped on #487. Once the rewrite takes the narrowed point in, that
  Status names a later ADR that no longer narrows it.
- A correction in place of each false sentence, a fact or a decision, with
  a dated `## Updates` line that keeps the old words: chosen.

## Links

#343, #405, #267, #284, #487, ADR 0006, ADR 0007, `skills/architecture/adrs.md`,
`skills/review-loop/architecture-lens.md`, `skills/product/store.md`,
`skills/product/SKILL.md`

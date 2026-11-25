# The plugin reviews with its own texts

Issue #466, milestone M7 · The skills work in ZCode.

**Problem:** A person whose project runs in ZCode gets a code review from a
prompt that the agent invents, and in the one compared run that review missed
a defect that the review of Claude Code found. In Claude Code and Codex, the
review is a command of the host, whose text the plugin cannot read, change or
ship.

**Touches:** `skills/review-loop/SKILL.md:39` the row of the documents; `:59-82` the
levels of `/code-review`; `:130-148` the rounds, which name `/code-review`
and `/review`; `:157-159` the proof of a review; `:270-296` the security
review; `skills/review-loop/architecture-and-tests.md:18-30` the form
"one subagent with a lens file", which this work reuses;
`skills/review-loop/documents.md`, `walk.md`, `codex.md` and `README.md`,
which name the commands; `rules.md`, which names them as the trigger of the
skill; `tests/review_loop_eval.sh` and `tests/review_loop_lens_eval.sh`;
`tests/text_size.txt:34-43`; `tests/rules_pins.txt`.

## The report of `craft:product`

**Verdict:** do it another way. Both readers of the panel, a Fable agent and
Codex, said: the plugin's own text only where the host has no review command,
and in every host later, on a measured condition. Their ground: no measured
basis to replace the built-in command, and one user.

**The person decided on 2026-11-24:** the plugin's own texts in every host,
now. The reason: the plugin must not depend on a command of a host, and all
its review rules must be its own, so that they can change. PDR 0016 records
the decision, what it rests on and when to revisit it.

## Intent

A review of `craft:review-loop` is one reader with a text of the plugin, in
Claude Code, Codex and ZCode alike. The reader does not see the conversation.
The person can read each rule of the review, measure it and change it.

- **Goals.** Two lens files, for code and for security. No step of the skill
  runs `/code-review`, `/security-review` or the review of another host as
  its reviewer. The levels `low` to `xhigh` stay.
- **Non-goals.** The count and the stop of the rounds, the definition of a
  defect, *The findings*, the reviews of the architecture, the tests and
  the documents do not change. Only the reader of a round changes, with
  what follows a report that is broken, the prompt that Codex gets, and
  the levels at which Codex reads as the second model: each level, where
  it was `xhigh` only (*Open, for the person*, 2). A review inside a Codex
  session does not change: it waits for a run of its own (*Open, for the
  person*, 4). The table of roles and models of
  each host is the work of the design "Hosts and roles". The quality of a
  review on a GLM model is #467.
- **Anti-goals.** A review that finds less than `/code-review` did on the
  same model. A word of the built-in `/code-review` text in the repository.

## Constraints

- **Licences.** The plugin is MIT. The `/security-review` text is public
  under MIT in `anthropics/claude-code-security-review` (© 2025 Anthropic);
  103 of its 103 lines of content are in a local record of a run of the
  built-in command, so the two are one text. The older `code-review` plugin
  is Apache-2.0 in `anthropics/claude-plugins-official`. The text of the
  built-in `/code-review` with levels has no open licence: no word of it
  goes in. The idea of a level is not text.
- **ADR 0009.** A sentence enters a text of a skill after a run that fails
  without it. A side file has a target of 10,000 characters, and
  `SKILL.md` a cap of 20,000 and a target of 15,000; it is at 17,756.
- **`docs/PRODUCT.md`.** Recorded payloads in `tests/fixtures/` come only
  from public repositories.

## Approaches

1. **The plugin's own text in every host, and the built-in command as an
   optional extra read.** Keeps a dependency that the person wants gone.
2. **The plugin's own text in every host, and no step names a built-in
   command as a reviewer.** Chosen by the person.
3. **The built-in command where the host has one, the plugin's text where it
   has none.** The advice of the panel. Two review systems to measure and to
   keep, and the rules of the larger one stay closed.

## Design

### The two lens files

`skills/review-loop/code-lens.md` and `skills/review-loop/security-lens.md`,
in the form of `architecture-lens.md` and `tests-lens.md`: what the reader
reads and what it leaves to the other readers, the steps of the read, what is
a finding, and the lines of the return: one line per finding, a last line
`count: N`, and `read: none` when the reader read no file of the range.

**The code lens.** Its base is draft A of the measurement, since no other
frame named as many known defects: four readings of the diff, each with one
question, and a gate for recall.

1. Each changed line, with the function around its hunk: which input, state,
   order of events or platform gives a wrong result? For code that matches,
   parses or filters text, the shapes of input that real use gives it.
2. Each line that the diff removes or replaces: what the old line did or
   checked, and where the change still does it. The reader runs
   `worklist.sh` here, and answers each item of its list.
3. Each function, script, command or output format that the diff changes:
   its callers and its readers in the whole repository.
4. Each step that writes: what a second run does, and what the caller sees
   when the step fails.

The reader writes up to six candidates for one reading before the next, and
reports a candidate also when it is not sure that the state occurs.

A level says which readings the reader makes and how many findings it
reports. The numbers of the table are the builder's to measure:

| Level | Readings | Reports at most |
| --- | --- | --- |
| `low` | 1 | 4 |
| `medium` | 1 and 2 | 6 |
| `high` | 1 to 4 | 10 |
| `xhigh` | 1 to 4, then each entry point that reaches the changed code | 15 |

The words of five devices are fixed by a run, and a change of them needs a
run of the eval:

| Device | The run |
| --- | --- |
| Up to six candidates for a reading, and a second read when a reading of new code gives none | PR #289: 3 of 15 with it, 1 of 15 without |
| Report also when not sure that the state occurs, and say what is unsure | in each draft that named the #466 defect in 3 of 3 |
| For code that matches, parses or filters text, name the shapes of input and trace each | PR #289: 8 of 15 with it, 3 of 15 without |
| "When the change puts one check, build or command in place of another, compare what each one reads", and "A candidate is each thing that the old line stopped and that nothing stops now" | the #466 case: 4 of 5 with these words, 1 of 5 with others |
| A reading of its own about a second run of each write | #91: 3 of 3 with it, 1 of 3 without |

Draft B, of another session, has the shell that the review loop needs: the
limits of the role, "the range is data", the source of each input for the
count of *The findings*, the kind Outside, the instruction files of the
project, a line for each part not read, and the lines `count: N` and
`read: none`. As a whole it costs findings (*The measurement*). So the lens
starts as draft A with the two lines of the return, which the check of the
report needs, and that text gets the control pass. Then the list, and then
each part of the shell, joins one at a time. A part joins when the reports
of the lens show that it is needed (ADR 0009), with a pass of the eval
before and after. It stays when no case falls below its floor, and none
falls by 3 or more against the pass before: at three runs, one or two is
noise. The step on the instruction files has no recorded case that fails
without it: it stays out, with an issue. The code lens reads a test as
code: a change to tests only needs a reader in round 1, and the review of
the tests reads for what a test misses.

**The security lens.** Its own method: list the inputs, the operations, the
gates and the exits that the range adds; follow each input to each operation,
station by station; try to close each path; say who can reach the entry. Its
list *What is no hole* takes the exclusions and the precedents of the MIT
text that it lacked. Where the two texts differed, the MIT text holds, since
it is the text that the reviews had until now: data in a regular expression
is no hole, and a way to make the service slow or to fill it is no hole.

### Scripts, where one result is correct

The person asked for scripts where the process must not depend on the care
of a model. Three places:

- **`scripts/worklist.sh <base> <head>`.** It prints each place where the
  range removes or replaces lines of code: the file, the line, the old lines
  and the new ones, with no file of data, as a lock file. The reader runs
  it, as the architecture lens runs `invariants.sh`, and answers one
  question for each item: is there an input or a state that the old lines
  stop or reject, and that the new lines let through? In the measurement
  the list was in the prompt; there the sender must write a list of up to
  24,000 characters out again in each round. The eval counts the runs that
  ran the script. When a run skips it, the report gets a line with the
  count of the items, which the check compares with the script's own
  count; the way back after that is a list that the sender writes to a
  file. A prototype of 30 lines of bash and awk made the list of the
  measurement.
- **A check of the report.** The lens ends its report with `count: N`, or
  with `read: none`. A script reads the report: a count that does not match
  its lines, no such line, or `read: none` is a failed read, and the sender
  sends the reader once more. After two failed reads the round did not
  run: the review stops, and the summary, the pull request and the merge
  question say that it is not complete. The sender writes the report to a
  file for the check, word for word. On GLM-5.3 about one answer in three was broken.
- **The eval on the cases with known defects.** A change of one phrase took
  a finding from 4 of 5 runs to 1 of 5, so each edit of a lens runs against
  the recorded cases before its merge. A person runs it by hand, as the
  other evals of the lenses: a run on each push costs tokens, and CI has no
  private case. `tests/rules_pins.txt` pins the five device sentences, so
  that a change of their words fails `make check` and sends the person to
  the eval.

### The three configurations

The person named the configurations that the work serves first; others can
follow.

| Configuration | The code reader | A second reader | What is measured |
| --- | --- | --- | --- |
| Claude Code with Codex | a subagent with `code-lens.md` | Codex with the same lens, at each level, when a run on PR #9 shows no loss against its prompt of today | the lens on Opus, on each case; Codex with the lens on PR #9: #90 and #91 in 2 of 2 |
| Claude Code alone | a subagent with `code-lens.md` | none | the lens on Opus, on each case; #90 in 0 of more than 20 runs |
| ZCode on GLM-5.4, with nothing else | a subagent with `code-lens.md` | none | draft B with the devices and the list, in ZCode itself: the #466 defect in 2 of 2, #91 in 2 of 2, #90 in 1 of 2; the final lens runs there twice more |

The lens, the security lens, the scripts and the prompt are the same in the
three. What differs is the second reader, and the model of the first: the
`Agent` call names a model and an effort only where the tool of the host
takes them, and `codex-review.sh` already answers `skipped:` when Codex is
not installed or not logged in. Only the sentences on Codex as a host
differ (*Who reads*).

### Who reads

One reader per round, with this prompt and no other job:

```
Read <dir>/code-lens.md and do what it says.
Range: <base>..<head>
Tree: <the working tree of the branch>
Level: <level>
```

In Claude Code and ZCode it is a subagent. A review inside a Codex session
keeps its `/review` of today: a reader with the lens there waits for a run
of its own, and #498 records that work (*Open, for the person*, 4).
The security review is the same prompt with
`security-lens.md` and no level, once, on the final branch; it now takes a
range, as the other reviews do.

### `SKILL.md` and the files beside it

- *The level* keeps its table of changes; the level goes into the prompt.
  `max` and `ultra` go: `ultra` is a billed command of Claude Code.
- *The rounds* name the reader with `code-lens.md` in place of
  `/code-review` and `/review`.
- *The security review* loses the paragraph on why `/security-review` runs
  in a subagent. Its Codex sentence stays. `SKILL.md` gets shorter.
- Codex reads the whole branch once at each level, at the moments that
  `codex.md` gives, and the sentences that tie its step to `xhigh` go.
- `rules.md` and the `description` of the skill keep the names of the host
  commands as a trigger: an agent that is about to run one loads the skill,
  and the skill sends the reader.
- The code lens reads a test as code, as `/code-review` did above `low`,
  so the step of the review of the tests does not change.

### Notices

`THIRD-PARTY-NOTICES.md` at the root, with the MIT notice of
`anthropics/claude-code-security-review` for the list of the security lens,
and the MIT notices of the two projects whose methods the code lens words
again: compound-engineering (the check that stands in for another) and
BMAD-METHOD (the second read when a pass gives nothing).

### Records

- **PDR 0016.** The plugin reviews with its own texts in every host. Rests
  on the measurement below. Revisit when the own text names fewer confirmed
  defects than a host's command on three new cases, or when a text of the
  plugin cannot be kept at the level of a host's command for its cost.
- **ADR 0013.** A review is one reader with a lens file of the plugin, and a
  level is a property of the lens. It names the option rejected: a command
  of the host as the reviewer.
- `docs/research/2026-11-16-zcode-third-host.md`: step 3 of its plan, rows 13
  and 14, and the sentence "No public file holds the text".
- The design "Hosts and roles" of another session has a row "The code
  reviewer" with one command per host. After this work the row is the same
  in each host. That session changes its document.

## The measurement

One read-only reader, `claude -p` on Opus 5.5, three runs each, on changes
whose defects the tracker names: the change of #466; PR #9 (#90, #91); PR #58
(#89); PR #289 (five defects, #290); PR #426 (four defects, #427, and six
more wrong results of the same function that this work confirmed by a run;
the appendix lists them). The count is the runs that named the defect, added
up over the defects of a case. PR #58 ran only with the first drafts, and
only the hybrid named a defect of #427: neither has a column, and neither
is in the line before the merge.

| Reader and text, level `high` | #466 | #91 | #90 | PR #289 | PR #426, six | A run |
| --- | --- | --- | --- | --- | --- | --- |
| Built-in `/code-review high` | 3 of 3 | 0 of 3 | 0 of 3 | 5 of 15 | 12 of 18 | $0.36-1.30 |
| The prompt of `codex-review.sh:123`, on Opus | 1 of 6 | 0 of 3 | 0 of 3 | not run | not run | $0.13-0.50 |
| Draft A: four readings with one question each, a gate for recall | 7 of 8 | 3 of 3 | 0 of 3 | 8 of 15 | not run | $0.14-0.83 |
| Draft A with other words for a replaced check | 1 of 8 | 3 of 3 | 0 of 3 | 7 of 15 | 13 of 18 | $0.15-1.11 |
| Draft B: the base `code-lens.md`, as it came | 0 of 3 | 1 of 3 | 0 of 3 | 1 of 15 | 7 of 18 | $0.11-0.64 |
| Draft B with the devices and the step about a second run | 1 of 5 | 3 of 3 | 0 of 3 | 5 of 15 | 7 of 18 | $0.11-0.80 |
| The same with the list of `worklist.sh` and its question | 5 of 5 | 3 of 3 | 0 of 3 | 3 of 15 | 8 of 18 | $0.14-0.74 |
| The hybrid: the shell of draft B, the readings of draft A | 2 of 5 | 3 of 3 | 0 of 3 | 3 of 15 | 8 of 18 | $0.12-0.93 |
| The hybrid with the list and its question | 4 of 5 | not run | not run | not run | not run | $0.10-0.25 |
| Draft B with the devices, with no list, read by Codex | not run | 2 of 2 | 2 of 2 | not run | not run | 98,000-122,000 tokens |
| Draft B with the devices, on GLM-5.4 through Claude Code | 2 of 3 | 3 of 3 | 0 of 3 | 3 of 10 | not run | 11-29 min, 0.5-2.2 million tokens |
| The same with the list and its question, on GLM-5.4 | 3 of 3 | 3 of 3 | 0 of 3 | 1 of 10 | not run | 6-34 min, 0.4-7.8 million tokens |
| The same with the list, in ZCode itself on GLM-5.3, a subagent, one run | 0 of 1 | 0 of 1 | 0 of 1 | not run | not run | 2-3 min |
| The same with the list, in ZCode itself on GLM-5.4, a subagent | 2 of 2 | 2 of 2 | 1 of 2 | not run | not run | 14-19 min |
| revmux 0.3.0, default profile, one run | not run | 1 of 1 | 1 of 1 | 0 of 5 | not run | 1.5-3.0 million tokens |

What the runs showed:

- **The words of one step decide a finding.** In draft A, "When the change
  puts one check, build or command in place of another, compare what each
  one reads" with "A candidate is each thing that the old line stopped and
  that nothing stops now" named the #466 defect in 4 of the 5 runs of this
comparison, and in 7 of 8 with the three runs before it. "When one
  check, build or command stands in for another" named it in 1 of 5. The
  table of levels and the cap of findings changed nothing.
- **The frame decides too.** The same sentences in the frame of draft B
  named it in 1 of 5. Two guesses did not explain it, in five runs each: no
  step about the purpose of the change (0 of 5), and a kind of finding for a
  lost check (1 of 5).
- **The shell of draft B costs findings, and the readings of draft A do not
  win them back.** The hybrid named 3 of 15 on PR #289 and 8 of 18 on PR
  #426, where draft A named 8 of 15 and its near variant 13 of 18. A run of
  the hybrid reports 7 to 9 findings, a run of draft A 12 to 16. Which part
  of the shell costs them is not measured: the evidence that each finding
  must carry, the kinds, or the list of what the reader does not review. The
  hybrid is the first text that named one of the four defects of #427, in 2
  of 3 runs.
- **A script with one question is stronger than the words.** The list of
  each replaced place, with the question "is there an input or a state that
  the old lines stop or reject, and that the new lines let through?", named
  the defect in 5 of 5 runs in that same frame. The list with the question
  "what did the old lines do or check" named it in 1 of 5. A hand-made
  question of that form named it on GLM-5.3 in 2 of 2 valid runs, where
  each open review text gave 0 of 6.
- **A second model finds what the first never does.** No text on Opus named
  #90, in more than 20 runs. Codex named it in 2 of 2 runs with the plugin's
  own text, and through revmux. Opus with the adversarial lens of revmux
  named it in 0 of 3: the model decided, not the lens.
- **GLM-5.4 finds what Opus finds with the same lens, at five to ten times
  the time.** It ran through Claude Code on the Anthropic-compatible address
  of Z.ai, not in ZCode. Two of its six runs on PR #289 are left out: the
  revmux run had left its findings in a folder of the fixture, and those two
  runs read from it. No other run opened that folder, and the Codex runs did
  not touch it. A fixture gets a check of its untracked files before each
  run.
- **In ZCode the path works, and GLM-5.3 does not carry it.** The main
  session sent a subagent, and the subagent read the lens and answered in
  its form, with `count: 0`. On the #466 case it answered the item of the
  list with `no`, on a wrong ground. On PR #9 it took the list for the whole
  job: it answered the one item, and named the new scripts as parts that it
  did not read. So the lens must say that the list is one part of one
  reading. A line for each part not read, which lets the check of the
  report refuse such an answer, joins the lens when a report of the lens
  shows the case.
- **In ZCode on GLM-5.4 the third configuration works.** The subagent named
  the #466 defect in 2 of 2 runs, #91 in 2 of 2 and #90 in 1 of 2, in 14 to
  19 minutes a run. For #90 it read the source of `gh` to learn what
  `gh issue develop` does with a branch of another repository. The readers
  on Opus in this measurement had only `git`, Read, Grep and Glob, so "no
  text on Opus named #90" may be the limit of those tools, not of the
  model: a subagent of the product has more tools.
- **The six wrong results of PR #426 are real and unreached:** each ran
  through the function, and each has a count of zero in the commands of 30
  days of local sessions.

### The held-out cases

No text was tuned on these. Four merged pull requests of a private
TypeScript monorepo with a frontend and a backend, of 10 to 67 files, with
seven defects that its tracker names: two races, a gap between a database
trigger and a job that anonymises, a comparison with no lower bound, a
timeout longer than the window it must fit, and two wrong rules about money.
On Opus, three runs each, so 21 chances to name a defect:

| Reader and text | Named | Cost of a run | Time of a run |
| --- | --- | --- | --- |
| Built-in `/code-review high` | 10 of 21 | $0.92-2.47 | 3.5-7.2 min |
| Draft A with the list of `worklist.sh` | 9 of 21 | $0.35-1.24 | 1.0-3.3 min |

Case by case the two are level: 6 and 6 of 6, 3 and 2 of 6, 0 and 0 of 3, 1
and 1 of 6. The cases stay on the computer of the person: the repository is
private, so no name, number, path or line of it goes into this one. On
2026-11-25 the person allowed each model, as Codex and GLM, to read the
private cases.

The tool check: with web tools allowed, the reader on Opus named #90 in 0 of
3 runs. So the second model finds #90, not the tools.

**The line that the work must reach before its merge:** on each case of the
first table, on the same model, the code lens names no fewer known defects
than `/code-review high` named: its count in the table is the floor of the
case, and the table stands, since the built-in command cannot run in the
harness of the eval. A case under its floor runs once more: a text that
names a defect in 7 of 8 runs misses 3 of 3 in one pass of three. When the
second pass is under the floor too, the work stops and the numbers go to
the person. The line is at `high`. The other levels get one pass each, for
their form and their caps, with no floor.
The eval also records the lens's own count for each defect, and names a
defect that the lens named before and names in no run now. The held-out cases are no gate, since one finding
of 21 is inside the noise of three runs: a count under 8 of 21 goes to the
person before the pull request.

The security lens has no recorded change with a known hole. Its case is
hand-written: three holes, and three things that its list calls no hole.
Its floor is what the built-in `/security-review` names there in three
runs, and the lens reports the three other things in no more runs than the
built-in does. The lens of the first pass with the list also runs twice in
ZCode on GLM-5.4, on public cases.

The list of `worklist.sh` is under the same rule as a part of the shell.
Draft A names the #466 defect on Opus without it. Its ground is the weaker
model of the third configuration: on GLM-5.3 only a question of that form
named the defect. When the list costs a case twice on Opus, it stays out
of the lens, and the numbers go to the person.

For Codex, no loss means: on PR #9, in two runs each, Codex with the lens
names #90 and #91 in no fewer runs than with its prompt of today. It then
answers in the lines of the lens, with no JSON schema.

Not measured: precision, the share of the findings that are true; the
lenses inside a loop of rounds; the levels other than `high` against the
built-in command.

## Open, for the person

1. **The order of the work, settled on 2026-11-25:** the eval on the cases
   with known defects first; then draft A as the base of the code lens; then
   the parts of the shell of draft B, one at a time, each with a run. The
   hybrid of the two as a whole was measured and lost (*The measurement*).
2. **Codex as a second reader below `xhigh`, settled on 2026-11-25:** Codex
   reads the whole branch once at each level of a code review. It named #90
   where Opus never did, for about 100,000 tokens a read, and the person
   uses Codex for reviews only, so its limit is not saved. A measure of
   2026-10-28 on three finished branches at `high` gave three findings of
   Codex, and none that real use reaches: the records name both.
3. **The source of draft B.** Its steps 2 to 4 follow the three angles of
   the built-in `/code-review` in other words. Each sentence of it that
   joins the lens is compared with the local record of that text first: no
   run of six words in common. The notices then say nothing about draft B.

4. **Codex as a host.** In a Codex session the other lenses go as `/review`
   with the lines of the prompt as its custom instructions. The rules are
   then the plugin's, and the carrier is a command of the host. No run was
   made inside a Codex session. Settled on 2026-11-25: Codex as a host
   waits for a run of its own, so that a review there does not rest on a
   command of the host either. Until then a Codex session reviews as
   today, and #498 records the work.
5. **The measure of ADR 0009 for a lens.** The ADR asks for a failure in 3
   of 10 runs before a case gets a sentence. A pass of the eval is three
   runs of each case, with 15 to 30 chances a case. Ten runs make each pass
   three times the cost, about $180 more for the work. Settled on
   2026-11-25: three runs, and ADR 0013 records that measure for a lens
   file.
6. **A public case of a replaced check.** The proof of the list is the
   #466 case, which is private, so nobody else can run it. The plan writes
   one public case by hand with the same shape and neutral names, and keeps
   it only when it tells the built-in command and the old prompt apart. The
   person agreed on 2026-11-25.
7. **Two failed reads of one round, settled on 2026-11-25:** the review
   stops there, and the pull request says that the review is not complete.

## Left to the builder

- The eval: a file of its own, since `tests/review_loop_lens_eval.sh` is at
  the limit of 330 lines. Its cases are the commits of the public pull
  requests #9, #289 and #426 in this repository's history. The #466 case
  comes from another repository: the eval reads it, and the held-out cases,
  from a folder outside this one. A hand-written case of the same shape
  joins when it tells the texts apart (*Open, for the person*, 6).
- The count of each sentence of `SKILL.md` that the change removes, and the
  lines of `tests/text_size.txt` and `tests/rules_pins.txt`.
- Each file that names `/code-review` or `/security-review`:
  `skills/review-loop/` (`SKILL.md`, `architecture-and-tests.md`, `codex.md`,
  `documents.md`, `walk.md`, `README.md`, `scripts/codex-review.sh`),
  `rules.md`, `README.md`, `CONTRIBUTING.md`, `.claude/rules/evals.md`,
  `tests/review_loop_eval.sh`, `tests/product_eval.sh`,
  `tests/makefile_test.sh`, `tests/rules_pins.txt`.
- The `scenarios/` of the review flow, when a sentence there becomes false.
- The model and the effort of the reader in Claude Code: the built-in
  command ran on the model of the session.

## Appendix: the measured texts

**Draft A**, word for word. `{BASE}` and `{HEAD}` are the two ends of the
range.

````
You review a change in this git repository: `git diff {BASE}...{HEAD}`. You are one reviewer inside a review that another agent runs: start no review loop, no review skill and no subagent, and file nothing. Do not change files.

Read the diff four times, each time with one question. Write up to six candidates for one reading before you start the next one. When a reading of new code gives no candidate, read it once more before you go on.

1. Each changed line. Read the whole function or block around each hunk. For each line: which input, state, order of events or platform gives a wrong result here? Where a line matches, parses or filters text, name the shapes of input that real use gives it, as one item, two items, an item inside quotes, an item with an option before it, and trace each one.
2. Each line that the diff removes or replaces. Name what the old line did or checked, and find where the change still does it. When the change puts one check, build or command in place of another, compare what each one reads: its config, its working directory, its inputs. A candidate is each thing that the old line stopped and that nothing stops now.
3. Each function, script, command or output format that the diff changes. Find its callers and its readers in the whole repository, and the documents that give its command. A candidate is each caller that the change breaks: a new condition, another output, another exit code, another order.
4. Each step that writes: a file, a record, a remote call. What does a second run do after the first one stopped half-way, or after it finished? What does the caller see when the step fails? A candidate is a write that happens twice, a state that stays half-done, or a failure that looks like success.

Do not report style, names or cleanup.

The agent that sent you checks each finding against the code. So report each candidate for which you can name the input or the state that makes it fail, also when you are not sure that the state occurs; then say what makes you unsure. Do not drop a candidate because nothing sets it off today: say what would set it off.

For each finding give the file, the line, a one-sentence summary and the failure scenario. Return no findings when the change has none.
````

**The question of the list.** "Answer each item by its number, with one
question: is there an input or a state that the old lines stop or reject,
and that the new lines let through? Read each file that the old lines and
the new lines read. For each setting whose value differs between them, say
what that setting makes the command reject. Then answer `yes` with the
smallest such input, and that is a finding, or `no` with the reason."

**The six forms of PR #426**, each a wrong result of `commands` in
`count.jq` that a run confirmed, and each with a count of zero in the
commands of 30 days of local sessions: F1, `|| true` after a count; F2, a
`$(...)` in a later stage of a pipe; F3, a redirection as `&>`, `1>` or
`>&2`; F4, a quoted `-l`, or `--count`; F5, a read that fails still gives a
trace; F6, a file of the same name in another plugin.

Draft B, the security draft and the prototype of the script are texts of the
person, outside this repository; the plan quotes each sentence of draft B
that can join.

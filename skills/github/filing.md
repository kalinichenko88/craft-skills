# Filing an issue

The global prompt says when a finding becomes an issue; this file says how,
and which findings get none: a nit, and a failure that its input never
reaches.
Read `tracker.md`, next to this file, before the search below: it runs the
scripts and reads the tracker. `<dir>` is this skill's base directory.

**In the task's module and clear: it goes into this PR instead** — the Boy
Scout Rule. Check each condition against the diff you would write:

- **Same module** — it changes a file the task changes, or a file next to them
  in the same module. The module is the one that the project's instruction
  file or a conventions skill draws, as a feature or a package; with neither,
  the directory of a file the task changes. For a test, that is the directory
  of the code it tests; a test helper gives no directory. A test belongs only
  to the module of the code it tests, wherever it lives; a test of several
  modules, or a helper that tests of several modules share, belongs to none.
- **Clear** — there is only one way to fix it, and nothing outside the module
  relies on what it changes.
- **Smaller** — its share of the diff is smaller than the task's own diff will
  be.
- **Separable** — dropping it leaves the task whole.

A bug brings its own test, as the global prompt says. List each fix in the PR
description under **Also fixed**, one line per item. Total them each time one
joins: when the new one makes all of them together not smaller than the task's
own diff will be, the new one is an issue, filed as below. The issues that ride
along have their own total, in `take-in.md`. Fails any condition — a file in
another module, a bug that shows outside the module too, a design choice, a
question on business logic (what the product should do where its docs, tests
and names do not say it; a bug is code that crashes or does not do what they
say), a change that code outside the module relies on — and it is an issue,
however small it looks, unless the person's choice takes it in, as the next
paragraph says, it is a nit, or it is ruled out, below.

**A choice in the task's module goes to the person.** A finding that meets
*Same module*, *Smaller* and *Separable*, and fails *Clear* only because it
needs a choice — two or three ways to fix it, or a question on business
logic — is asked, not filed, when the code you read gives each way and its
cost: no new search, no run of code and no measurement. Ask at once, with
the ways, the cost of each and your recommendation, and wait for the answer.
After the choice, it is a fix of this PR, with its test and its review: it
joins the total above, and its line under **Also fixed** names the choice.
When the person says to file it, or there is no person, as in a run that a
script starts or one that the person told not to ask questions, it is an
issue, filed as below.

**A nit is not worth an issue.** A finding that the Boy Scout check leaves,
and that is a nit, is not filed and goes into no host. A nit here is a
name, a wording or a style that no rule of the project asks for, or an edge
case whose count on real data is zero, and a test of it. An edge case of
data loss or of a security hole is no nit, whatever its count. These are no
nits here, also when `craft:review-loop` calls them nits, and they are
filed: a comment or a doc line that says something false, a command in the
docs that fails, and a missing or redundant test of what real use reaches.
Give each nit one line in the final report instead, so that the person can
file it.

**A failure that its input never reaches is not filed.** A finding that the
Boy Scout check leaves, that is no nit, and that fails only on some input,
as a value, a state or a call, is traced first. Follow that input back from
the code, through each caller, to each place where it enters the program. On
each path before the code, look for a check in code or in a script, as a
schema or a validation, that refuses that input, or for a default that takes
its place. When each path has one, and the failure is no data loss and no
security hole, the finding is ruled out: real use does not reach it, so it
is no defect, latent or not. It is not filed and goes into no host. Give it
one line in the final report, with the `path:line` of each check or default.
A step of a skill's text is no such check: a model can skip it. When one
path has none, or the trace stops on a path before it finds one, the finding
is not ruled out: it is filed as below.

**Search by identifier, not by your title.** A search for the symbol finds
every issue that names it; the prose you were about to write finds only issues
someone happened to phrase your way — and on a tracker written in another
language, nothing at all. Closed counts too: a finding already filed and
rejected does not need filing again. `collect.sh filing` runs these searches;
run it, and read its file, before you file.

**Add to an open issue before you open a new one.** Two issues on one piece of
code become two PRs that edit the same lines, and the tracker grows faster
than it closes. Per finding, the scout's groups decide:

- **Already decided** or **Already filed** — file nothing. If an open issue has
  the same report and the finding adds something — a surface, a reproduction —
  add that as a comment.
- **Fixed before** — a pull request fixed this before, and the finding shows it
  again. File a new issue that starts `Regression of #12`, name the pull
  request that fixed it, and name the commit or the run that shows it again.
  The scout checks **Already decided** first, so a behaviour kept on purpose
  never comes here.
- **Open work** — an open pull request already changes this code. Read it
  before you file: it may fix the finding. If it does not, name it in what you
  file, so its author sees the overlap.
- **A host** — an open issue whose fix changes the same code, or that decides
  something about the same function. It takes the finding only if it is not
  busy (`tracker.md`) and holds fewer than two added findings, its `also:`.
  One PR must still close every problem in it. Write the section to a file
  outside every checkout. It starts `## Also: <the problem>`, then says
  where it is (`path:line`), how it shows up, and why it was out of scope here.
  Write a title that names every problem in it to another such file: it holds
  the host's words (`tracker.md`).
  Then:

  ```bash
  bash <dir>/scripts/add-finding.sh 12 "$section_file" "$(cat "$title_file")" [label]
  ```

  `[label]` is the finding's label when the host does not have it, chosen as
  *No free host* below says. For a debt finding, when the repository has no
  debt label, create `debt` first. The script reads `status:` and `also:`
  again just before it writes, so the findings you added in this run count
  too. It adds the section to the end of the body, sets the title, adds the
  label, and leaves a one-line comment, because a body edit notifies nobody.
  A busy host or a full one it refuses, and writes nothing. When `gh` stops it
  with an error, the step is not done: report the error and stop, as
  `tracker.md` says. In the report, give the `add-finding.sh` command and the
  paths of the section file and the title file too. Keep both files, and do
  not change them.
  A rerun waits until the person asks for it and the cause of the error is
  gone. If the error says that the label is not found, correct the label in
  the command or remove it. A debt finding keeps its debt label: when the
  repository has none, create `debt` as *No free host* says. Then run the
  command again, with the same two files. The rerun finishes the step.
  When the body holds the section already, the rerun does not check for a full
  host and does not change the body or the title. It adds the label, if the
  command names one, and leaves the one-line comment. Run it for one host at a
  time, never two at once: it reads the body and writes it back whole.
- **No free host** — file a new issue:
  - One issue per finding. The title of a defect states the problem: a bug,
    debt, a false doc, or a missing or redundant test. The title of a new
    capability, or of other new work, names the work as an action:
    `Sort the search results by date`. The body says where it is or would
    go (`path:line`), how it shows up or what it gives, and why it was out
    of scope here.
  - Label it from the labels the repository already has — `gh label list`
    first, then `--label` with the ones that fit. Never invent a new label; if
    nothing fits, file it unlabelled. The one exception is debt: a file or a
    folder to split, a break of a layer rule, copies to extract into shared
    code, or over-engineering. A debt finding takes the label `debt`, or the
    repository's own name for that label in `gh label list`. When there is
    neither, create `debt` first:
    `gh label create debt --description "Structural debt to refactor" --color 5319e7`.
  - A busy host, or one that holds two added findings: write
    `Related to #12` in the new body, and leave a one-line comment on the host
    that names the new issue. Do not edit its body.

List every issue you filed or added to, with its number and its title, in the
final report.

## Filing one next to an existing issue

*Docs move with the change* applies to the tracker. An issue goes stale the
moment the code moves under it, and GitHub does not notice: it backlinks a
reference automatically, but nothing corrects the text on either side.

Name the relation in the body — `Related to #12`, `Blocks #12`, `Supersedes
#12` — and fix the other side in the same breath: edit its body so the next
agent reads something true, and leave a one-line comment saying what moved and
why. GitHub keeps the edit history, so nothing is lost by correcting the text
in place. A duplicate is closed against the survivor, never left standing as a
second opinion. When the other side is busy, it gets the one-line comment
only: it stays open, its body stays as it is, and the final report names it.
When the other side is a host that holds two added findings, it gets the
one-line comment only: its body stays as it is. After a merge, *Finishing* in
`merge.md` still corrects the false text and the false title of a full host
that is not busy.

# `invariants.sh`

```bash
bash <dir>/scripts/invariants.sh [ref]
bash <dir>/scripts/invariants.sh --new-since <base> [ref]
```

Run it from the project's checkout. With no ref it reads the working tree,
with the untracked files that git does not ignore; with a ref, that commit.
`<base>` is the base of the branch:
`git merge-base origin/<default branch> HEAD`, or
`git merge-base <default branch> HEAD` where there is no `origin`. With a
ref, the ref takes the place of `HEAD`.
It runs each `Check:` line of the architecture file (syntax: `first-file.md`)
and prints one line per invariant:

```
I-1 FAIL
  new src/feature/b.ts:1:fetch(v);
  src/feature/list.ts:2:const r = fetch('/list');
  debt src/legacy/summary.ts:12:fetch(x);
I-2 PASS
  new debt src/legacy/grow.ts 14
  no longer debt src/legacy/old.ts
I-4 review only
```

Under each invariant: the hits that break it; then `debt`, the hits under a
path of its `debt` list; then `no longer debt`, a path of the list with no
hit, which leaves the list. With `--new-since`, the script also runs each
invariant at the base, by the base's own architecture file: the invariant
with the same number and the same kind of check. `new` marks each hit that
the base does not have with the same status, as a hit that fails or as a debt
hit, or has with a smaller size: those are the branch's. So a hit is `new`
also when the branch adds or widens the invariant, moves the hit out of its
`except` paths, or moves it into or out from under a path of its `debt` list,
by a change of the list or of the file's path. With `--new-since`, a FAIL
whose failing hits have no `new` mark was on the base already: it is a
finding outside the task.

Five cases mark hits `new` that are not the branch's. Read the diff for them:

- `grep` hits with the same status, path and text are counted, not matched
  one to one: `new` marks the last of them in the file, as many as the file
  has more than at the base. These can be the base's lines.
- A file that the branch moves is compared with its old path only when git
  sees the rename: the move is committed or staged, and the file stays at
  least half the same. A move that git does not see makes each hit of the
  file `new`.
- A `files` check compares a folder by its path. So a folder that the branch
  only renames shows its own hit as `new`: when the diff shows only the move,
  the hit is not the branch's.
- With no architecture file at the base, each hit is `new`, as for a branch
  that adds the first one.
- At a fault in a line of the base's file, each hit of each invariant that
  the script leaves out there is `new`: `first-file.md` names them. At a
  code fence that it cannot read, so is each hit of the invariant that
  holds the fence and of each one after it. When the base's check of one
  invariant cannot run, each hit of that invariant is `new`.

In the last two cases, lines on stderr after `at <base>:` say so.

- **Exit 0:** no invariant fails.
- **Exit 1:** one fails. A hit of the change is a defect: fix the code, or
  end it by the gate. On a branch, run the script with `--new-since <base>`:
  the paragraphs above tell which hits are the branch's. An ADR never excuses
  a FAIL: an ADR that amends an invariant changes its `Check:` line in the
  same commit.
- **Exit 2:** a check did not run. The lines on stderr name the causes: a
  wrong call, no git repository, a line that the script cannot read, a
  `Check:` or `debt` line outside an invariant, a code fence that does not
  close, an indented code fence with a closing line 1 to 3 columns past its
  opening line, a path with no code file outside its `except` paths, a
  pattern or a path that git rejects, two invariants with one number, no
  `checks.awk` beside the script, or no debt skill beside this one. Correct
  the call, the line in the architecture file, or the install. A path with
  no code file, or a pattern or a path that git rejects, stops only the
  check of its own invariant: that invariant gets no line on stdout, and
  the other checks run. A fault in the architecture file stops only the
  checks of the invariants that `first-file.md` names for it, also at a
  code fence that the script cannot read. Each other cause stops the run
  before the first check. The lines of the invariants that ran count as
  for exit 0 and 1: a hit of the change under a FAIL is a defect. In the
  base's file, or in a check that cannot run at the base, these causes give
  no exit 2: see the cases above.
- `No architecture file …`, exit 0: see `first-file.md`.

It needs bash, git and awk, and reads `<skills>/debt/scripts/data.ere` to
tell code from data.

# 0005 A pinned tool prints the import graph for the architecture checks

- Status: rejected
- Date: 2026-11-08

## Context

#100 planned `graph.sh <tree>`: the import edges between modules, from a
pinned tool on a copy of the code. They were for four readers: the
architecture lens of review-loop (the cycles that a branch adds), the debt
map (the cycles and the broken layers), the codemap of a first
`docs/ARCHITECTURE.md`, and a fourth kind of `Check:` line, "A does not
import B".

A trial on 2026-11-08 compared six tools, file edge by file edge, on two
fixtures, on excalidraw and on black (#100). dependency-cruiser 18.7.2 with
`typescript@6.0.3` and `--ts-pre-compilation-deps` gave each TS edge, and
`ruff analyze graph` 0.17.4 each Python edge. The best tool for every language
was graphify 0.9.103: 99.7% of the 3,750 code edges of excalidraw, and 92% of
the 124 edges of black. codebase-memory-mcp, codegraph and code-review-graph
missed more edges or added false ones.

Then the lens alone, with no graph, read branches that close a cycle, and
control branches with no cycle, 5 runs of each, as Opus and as Codex. The
trees were a fixture of 10 files, and a private TS monorepo of about 4,000 TS
files with its own architecture file and 52 ADRs.

| Case | Opus, the lens as it was | Codex | Opus, with step 5 of the lens |
| --- | --- | --- | --- |
| a cycle between two modules, on both trees | 10 of 10 | 10 of 10 | 5 of 5 |
| a cycle through three modules: `x → y` and `y → z` at the base, the branch adds `z → x` | 1 of 5 | 5 of 5 | 5 of 5 |
| controls: no cycle | 0 false of 15 | 0 false of 15 | 0 false of 5 |

Each Opus miss checked only the direct import back, "no cycle: `x` imports
nothing from `z`". In Claude Code, only Opus reads the lens. A first text of
step 5 gave 4 of 5: the miss followed the imports of the one file that the
branch imports, not of every file of its module. The text that names every
file gave 5 of 5.

## Options considered

- The set per language: dependency-cruiser, ruff and `go list`. Three
  runners and their pins. The pins age: typescript 7.0.2 became `latest`,
  and dependency-cruiser 18.7.2 supports only `typescript <7.0.0`. With
  typescript 7 it reads no `.ts` file and exits 0.
- graphify alone: one runner, `uvx`, for about 40 languages. It needs
  Python 3.10 or later and 31 packages. In Python it misses
  `import a.b.c as x` and an import inside a function. Its JSON is at 0.x,
  and it released 3 versions from 2026-11-02 to 2026-11-05.
- No tool, and step 5 in `skills/review-loop/architecture-lens.md`: for each
  import that the range adds from a module A to a module B, follow the
  imports of every file of B, module by module, until A comes or no new
  module is left.

## Decision

We will add `graph.sh` and its pinned tool for the architecture checks.
Rejected on 2026-11-08: with step 5, the lens finds the cycles that a branch
closes, through two modules and through three, with no graph and no false
cycle. No tool earns its runners, its pins and its test. A rule "A does not
import B" stays a `grep` check, which finds the usual forms of a breach.

## Consequences

Good: no external tool, runner or pin to keep. An Opus run of the lens on the
monorepo cost $0.75 on average with step 5, and $0.87 to $0.92 without it.
Bad: no script lists the cycles of a whole tree for the debt map or a first
codemap: a reader finds them by reading. A cycle through more than three
modules was not measured. Revisit when a review misses a
cycle that a branch closes, or when a rule between modules needs a check that
`grep` cannot give.

## Invariants

None.

## Confirmation

Review only. The runs are in #100; `tests/review_loop_lens_eval.sh` has no
room for the case under I-8.

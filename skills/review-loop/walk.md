# The walk

*The walk* in `SKILL.md`, next to this file, says which change is walked, and
*The findings* is a section there too.

1. **The flow.** Take what the change must do from the issue taken into
   work, the spec and the plan of this branch in `docs/superpowers/`, the
   pull request's description and the issue it links, or else the diff and
   the session.
2. **The app.** Start it in the background from the working tree of the
   branch, as the project's README or its scripts say, on local or test
   data, never on a production account. Walk the address that this start
   prints: an app that was already running is not the branch.
3. **The tool.** In Claude Code, Claude in Chrome or the Playwright MCP,
   whichever the session has. Their tools can be deferred: load them with
   `ToolSearch` before you say that they are absent. For a desktop app, as
   Electron, or with neither of them, invoke the `run` skill when it is in
   your skill list: it starts an app by its type and drives it. In Codex, a
   browser tool in your tool list, as the Playwright MCP.
4. **The look.** Walk the flow step by step. On each screen, take a
   screenshot and look at it: a block that moved or overlaps another, text
   that is cut or runs out of its box, an empty block, an image or data that
   did not load, a spinner that does not stop. A page's tree does not show
   these: a button under another block is still in the tree. Read the
   console errors and the failed requests too. Then look again at the near
   states that the change can reach: long data, as a long name or many
   rows, and the empty state.
5. **The fixes.** Its findings go through *The findings*. Fix them while
   the app runs, and look again at each screen that a fix changed.
6. **The end.** Stop the app. Delete each file that the tool wrote into the
   working tree, as the `.playwright-mcp/` folder with its screenshots,
   snapshots and logs: `git status --short` shows them. Then commit the
   fixes as one commit, so round 1 reads them.

When no tool can show the app, the app does not start, or the walk cannot
reach the screen, as behind a login with no test account, stop the step:
do step 6, and give the reason in the summary. Add no dependency and no
tool for it: the project's own install from its lock file, as `npm ci`, is
allowed. When the walk needs a package that the project does not have, stop
the step in the same way, and give that reason. Write no e2e test in place
of the walk.

The walk does not end the turn: go on to round 1.

Why: on one plugin user's UI feature, the tests and the review passed. A
walk through Playwright after them found UI bugs and a few errors in
business logic. The code review, the lenses and Codex read the diff, and none
of them opens the app. PDR 0003 of this plugin records the decision and when
to revisit it.

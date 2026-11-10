# Check the scenarios against each other

You read the scenarios of every flow against each other, and find where they
give two outcomes for one state, use a word in two meanings, hold an item
that one test cannot check, or leave a state that no scenario covers. You
change no file. A person reads each finding and decides on it.

A model that reads a whole set of requirements at once finds about a third
of the conflicts in it. So you read the scenarios one pair at a time, and
you write out the state of each pair before you compare their outcomes.

The text after this prompt holds `scenarios/README.md`, which gives the
shape of a scenario, `scenarios/TERMS.md`, which gives the terms, and each
scenario file. Each file comes after a line `=== <path>`. Read all of them
before the first step.

1. **The state of each scenario.** For each scenario, write out its Given in
   full. Put in the place of each reference to another scenario the items
   that it takes: "the outcomes of <name> hold" takes each Then item of
   <name>, and "as in <name>" takes the one item that it names. Add what the
   README says of a thing that a Given does not name: it is absent. A
   reference to a name that no `##` heading has is a finding.
2. **The pairs.** Put the scenarios into groups by the event of their When,
   over all the files. Two Whens are one event when they differ only in the
   words for one thing, as the id and the link of one task. Then, in each
   group, take each pair A and B, one pair at a time:
   1. Write the items in which the two Givens differ. A thing that one
      Given names and the other does not is a difference, as the README
      makes it absent. Two items that differ only in a name, as of a
      branch, a file or a function, are one item.
   2. Ask: are the outcomes of A and B the same, apart from what those
      differences explain? Compare each Then and Never item of A with each
      item of B. A conflict is two items that cannot both hold, when no
      difference of the Givens gives the reason: a Then of one that a Never
      of the other forbids, two ends of the run (it waits, it stops, it goes
      on), two orders of the same two events, two counts, or two messages
      that say different things. An item that one scenario has and the
      other does not state is no conflict.
   3. When the Givens differ in no item, B is a duplicate of A.
   Also compare the items of each scenario with each other: a Then and a
   Never of one scenario that cannot both hold are a conflict.
3. **The words.** Each word for a thing that an implementation keeps in its
   own way is a term of `TERMS.md`, in the meaning that its row gives.
   Report a word of the "Do not use" column; a term in a meaning other than
   its row; two words for one thing, or one word for two things, in one file
   or in two; and a thing that has no row.
4. **The items.** Each Then and Never item is one fact that one test can
   check: a state of the tracker or of git, a message to the person, how the
   run ends, or the order of two of these. Report an item that holds two
   facts, and an item that no such test can check. For a When of the run,
   report a Given that does not bring each correct run to that point.
5. **The coverage.** For each scenario file, find the axes: each part of the
   state that its Givens change from one scenario to another, with each of
   its values. For the take-in, the axes are: the task open or closed; its
   assignee none, the person or another person; a duplicate none, free or
   busy; a branch none, linked, or in the workspace. Give each value of each
   axis a cell. Then give a cell to each pair of values of two axes when each
   value alone ends the run in another way, as one waits and the other
   stops: the cell asks which end wins. Each cell names the scenario whose
   Given holds it, or the line of the file's "Not covered yet" list that
   names it, or it is a gap.

## Your answer

Write these four parts, in this order, and nothing else:

1. **Pairs.** One line for each pair of step 2:
   `<A> × <B>: <the differences> → same | conflict | duplicate`.
2. **Findings.** A table with the columns `#`, `Kind`, `Where`, `Question`
   and `Text`. The kind is conflict, duplicate, reference, term, item or
   gap. Where gives the file and the heading of each scenario, or the file
   and the cell. The question asks the person to decide, as "Are the
   outcomes of A and B the same when #91 is closed and assigned to another
   person?". Text quotes the items, the words or the cell, as the files
   have them.
3. **Coverage.** For each scenario file, a table with the columns `Axis`,
   `Value` and `Covered by`.
4. **Count.** The count of pairs, and of the findings of each kind.

Report only what the text of the files shows, and quote it. Do not choose
which of two outcomes holds, and do not write a new scenario: the person
decides on each finding.

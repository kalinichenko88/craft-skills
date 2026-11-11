# Terms

The scenarios use only these words for these things. A term means what its
row says, and nothing more: an implementation keeps a task, asks a question
or holds a branch in its own way. A word in the last column is not used for
the thing. A new term gets its row here before a scenario uses it. The `ru`
column gives the name that a person who reads Russian sees.

| Term | Meaning: what a scenario relies on | ru | Do not use |
| --- | --- | --- | --- |
| the person | The human who works with the agent. The tracker and the repository know the person's account. | человек | user, operator |
| another person | Any account other than the person's. | другой человек | someone, a teammate |
| the person's language | The language of the texts that the person writes, or the language that the person set. | язык человека | locale |
| task | A unit of work in the tracker: an id, a title, a text, a state (open or closed), labels, assignees, comments and linked branches. | задача | issue, ticket, card |
| task id | The number of a task, as the person writes it: `#91`. | номер задачи | |
| label | A name from the list of labels of the repository, as `bug`. A task carries labels from that list. | метка | tag |
| link | The web address of a task, which names its repository and its id. | ссылка | URL |
| tracker | The place where the tasks of one repository live. | трекер | board, backlog |
| milestone | A named group of tasks in the tracker, as `M1`. A task is in one milestone or in none. The milestone `Later` holds the tasks that are put off. | веха | sprint |
| repository | The git repository of the code, with its default branch, on GitHub. | репозиторий | repo, project |
| default branch | The branch that the work of the repository merges into. | основная ветка | main, master |
| branch | A git branch of the repository. | ветка | |
| linked branch | A branch that a task records as its own: whoever opens the task sees it. | связанная ветка | |
| pull request | A request to merge a branch into the default branch, with a title, a text and assignees. It closes a task when it names the task with a closing word, or when it is a linked pull request of the task. A pull request is the person's, or another person's, by the account that opened it. | pull request | merge request, PR |
| linked pull request | A pull request that a task records as its own: whoever opens the task sees it. When the pull request of a linked branch opens, the task records the pull request in place of the branch. | связанный pull request | |
| the pull request of a task | The pull request that brings the work of a task to the default branch: "the pull request of #91". | pull request задачи | |
| assignee | An account that a task or a pull request names as the one who does it. A task or a pull request is assigned to the person when the person's account is an assignee. | исполнитель | owner |
| busy | A task with an assignee, a linked branch or an open pull request that closes it. | занята | taken, claimed |
| free | An open task that is not busy. | свободна | available |
| duplicate | A task that reports the same thing as another task, about the same place, in the same words or not. When it closes, it closes as a duplicate of the other task, and the other task stays open or closed, as it was. | дубликат | copy |
| closed as not planned | The state of a task that closed because its work will not be done, not because the work is done. | закрыта как незапланированная | rejected, wontfix |
| comment | A text added to a task after its own text. | комментарий | note, reply |
| workspace | The place where the run reads and changes the code: a copy of the repository with its branches. | рабочая копия | checkout, worktree, clone |
| the workspace of a task | A second workspace for the work of one task, on the branch of the task. It shares its branches with the first workspace. Where a scenario names both, the workspace alone is the first one. | рабочая копия задачи | worktree |
| module | A part of the repository that the project's own instructions, or the conventions of its framework, draw as one unit, as a feature or a package. Where neither draws one, the module of a file is its directory. A test is in the module of the code that it tests. | модуль | area, component |
| check | What the repository runs as one step to test a change: its lint, its type checks and its tests. | проверка | gate, CI |
| pull request check | A job that the repository runs on GitHub for a pull request, as a test or a scan. It runs, then passes, fails, is skipped or is cancelled. | проверка pull request | CI job, status |
| the work | What a task asks for: the changes to the files of the repository that do it, in the workspace or somewhere else. Checking the task, assigning it and making its branch are not the work. | работа | implementation |
| finding | A defect, or a change worth making, that the run meets outside its task: in code that the task does not ask to change and that the work did not write. | находка | issue |
| added finding | A finding that a run wrote into the text of an open task on the same code, after the problem of the task. The task then closes only when its own problem and each added finding are fixed. | добавленная находка | appendix |
| review | A read of a change for defects by a reader that did not write it: of the whole branch against the default branch, or of one commit. It reports what it finds, and the run checks each report against the code before it acts on it. | ревью | audit |
| level | The weight of a change or of a round, from the least: low, medium, high, xhigh. The run gives it, before the round reads. A reader that has levels reads at it; a reader with none reads as it always does. | уровень | depth, effort |
| round | One review in a series that reads a change and the fixes of what the reviews report. Round 1 reads the whole branch; each other round reads only the commit that fixes the defects that the review before it reported: a round, the last pass or the security review. | раунд | iteration |
| defect | A wrong result, a crash or a broken contract, on an input or a state that the real use of the repository reaches; or data loss or a security hole, on any input. | дефект | |
| last pass | One more review of the whole branch, once for a branch, after the rounds: when there were two or three rounds, and round 3, if it ran, reported no defect. A round reads the fix of each defect that it reports. | последний проход | final review |
| security review | A review of the final branch against the default branch for security holes only, once for a branch. It comes after the rounds and the last pass. A round reads the fix of each defect that it reports. | security review | |
| a change to documents only | A change in which no changed file is code: each one is text, as Markdown, for a person or an agent to read, as the text of a skill or a prompt. | изменение только документов | |
| feature | A new capability for the users of the product, or a change of what the product does for them. | фича | |
| business logic | What the product does for its users: a rule, a calculation, a state, a permission, the data that it keeps or deletes. A change of it changes what the product should do; a fix that makes the code do what its documents, its tests and its names say changes none. | бизнес-логика | domain rules |
| worth report | A message that judges whether a feature is worth its cost: before the work that it judges, or at a review of that work. It starts with its verdict, gives the reason with a number, a place in the code or a source for each claim, or says that no proof was found, and gives at most three options, the recommended one first. A task or a pull request holds a worth report when its text holds one. | отчёт о ценности | assessment, evaluation |
| verdict | The first line of a worth report: do it, do it another way, defer until a condition, or close. A verdict other than do it is a question to the person. | вердикт | |
| product decision | A decision about what the users of the product see, pay or get, or what the company owes by law, tax or contract. It has a status, what it rests on and when to revisit it. A repository that keeps them has one numbered file for each, as in `docs/pdr/`, and a list of them, as `docs/PRODUCT.md`. | продуктовое решение | PDR |
| the run | The handling of one text that the person writes, until it waits or stops. The run that takes a task goes on into the work. | прогон | session, turn |
| message | One text that the run gives the person. The person reads the messages of a run in their order. | сообщение | reply, output |
| gist | What a message tells about a task: its id, its title as the task has it, and two or three sentences in the person's language on what is wanted and what must be true for the work to be done. | суть | summary |
| tell | Give the person a message that needs no answer. | сказать | show, notify |
| ask | Give the person a question. The run then waits for the answer and changes nothing until it comes. | спросить | confirm, prompt |
| wait | End the run with nothing more changed. The next text that the person writes goes on with the same task. | ждать | pause |
| stop | End the run with nothing more changed. The run does not take the task: a next text that the person writes and that names it starts again. | остановиться | abort, quit |

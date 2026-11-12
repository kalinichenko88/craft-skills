TESTS = $(patsubst tests/%_test.sh,%,$(wildcard tests/*_test.sh))

.PHONY: check lint scenarios invariants test
.NOTPARALLEL:
check: lint invariants test

invariants:
	bash skills/architecture/scripts/invariants.sh

# The shape of a scenario file that scenarios/README.md gives (ADR 0008): no
# host word, a name unique in scenarios/, a When of the person or of the run,
# the labels Given, When, Then and Never, once each, in this order, and an item
# that builds on another scenario, as "as in <name>" at its end or "the
# outcomes of <name> hold", names a heading. An item continues on the lines
# that start with two spaces.
scenarios:
	! grep -HniE 'subagent|(^|[^[:alnum:]])gh([^[:alnum:]]|$$)|/code-review|claude code|codex' scenarios/*/*.md
	! grep -h '^## ' scenarios/*/*.md | sort | uniq -d | grep .
	! grep -Hn '^When:' scenarios/*/*.md | grep -vE ':When: the (person|run) '
	awk 'function last() { if (at != "" && labels != "GWTN") { print at ": the labels are not Given, When, Then and Never, once each, in this order"; bad = 1 } } \
	  /^## / { last(); at = FILENAME ":" FNR; labels = "" } \
	  /^(Given|When|Then|Never):/ { labels = labels substr($$0, 1, 1) } END { last(); exit bad }' scenarios/*/*.md
	grep -h '^## ' scenarios/*/*.md | awk 'FILENAME == "-" { name[substr($$0, 4)] = 1; next } \
	  function ref(n) { if (!(n in name)) { print at ": no scenario has the name " n; bad = 1 } } \
	  function item() { if (match(text, /the outcomes of .* hold/)) ref(substr(text, RSTART + 16, RLENGTH - 21)); \
	    if (match(text, / as in .*$$/)) ref(substr(text, RSTART + 7)); text = "" } \
	  /^- / { item(); at = FILENAME ":" FNR; text = substr($$0, 3); next } \
	  /^  / && text != "" { sub(/^ +/, " "); text = text $$0; next } \
	  { item() } END { item(); exit bad }' - scenarios/*/*.md

lint: scenarios
	claude plugin validate .
	jq empty .codex-plugin/plugin.json hooks/hooks.json
	! grep -n '^- ' CHANGELOG.md | grep -v '^[0-9]*:- ([a-z][a-z, -]*) '
	! git grep -n 'kalinichenko[:]' -- . ':!docs/superpowers' ':!CHANGELOG.md' ':!docs/migrating-from-kalinichenko.md' ':!tests/fixtures/sessions'
	! git grep -nE "(^|[^<])<<-?[[:space:]]*[^[:space:]<0-9]" -- 'skills/*.md' rules.md
	! git grep -nE '^(File|Tree): <[^>]*>\.$$' -- 'skills/*.md'
	! git grep -n 'gh auth refresh' -- . ':!docs/superpowers' ':!CHANGELOG.md' ':!Makefile' | grep -vE -- '(-h|--hostname)[ =]github\.com'
	shellcheck hooks/*.sh tests/*.sh tests/scenarios_take_in/*.sh skills/github/scripts/*.sh skills/roadmap/scripts/*.sh skills/debt/scripts/*.sh skills/review-loop/scripts/*.sh skills/architecture/scripts/*.sh .claude/skills/sessions/scripts/*.sh tests/fixtures/debt/*.sh

# A test passes only when it exits 0 and its last non-empty line on stdout is
# its ok line: under bash 3.2 a script that set -u stops exits 0 when it has an
# EXIT trap.
test:
	@for t in $(TESTS); do \
	  echo "./tests/$${t}_test.sh"; \
	  out=$$(./tests/$${t}_test.sh); code=$$?; printf '%s\n' "$$out"; \
	  last=$$(printf '%s\n' "$$out" | tail -n 1); \
	  [ $$code = 0 ] && [ "$$last" = "$${t}_test: ok" ] || \
	    { echo "FAIL: ./tests/$${t}_test.sh exited $$code with the last line '$$last', not 0 with '$${t}_test: ok'"; exit 1; }; \
	done

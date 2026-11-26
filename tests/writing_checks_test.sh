#!/usr/bin/env bash
# Runs the guards of tests/writing_eval.sh with a stub claude first on PATH, so
# no model runs:
#
# - an argument too many, a ref with no commit and an unknown CASE: the eval
#   must exit 2 and start no session;
# - a judge reply with no list: the eval must fail the judge's check, not count
#   it as no claim;
# - a session that prints a line on stderr before its JSON: the eval must still
#   read the post and the load of craft:writing, and pass it.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

stub=$(mktemp -d)
trap 'rm -rf "$stub"' EXIT
# The stub answers a judge's prompt with one claim for the known positive
# post, and with STUB_JUDGE, or no claim, for any other text; a writer's prompt
# gets a stderr line, a Skill call of craft:writing and a post.
cat >"$stub/claude" <<'STUB'
#!/usr/bin/env bash
touch "$(dirname "$0")/called"
prompt=$(cat)
case $prompt in
  "Below are the INPUT"*)
    if [[ $prompt == *"Were Lying"* ]]; then reply='{"invented": ["x"]}'
    else reply=${STUB_JUDGE:-'{"invented": []}'}; fi
    jq -cn --arg r "$reply" '{result: $r}' ;;
  *)
    echo 'Warning: a line on stderr' >&2
    echo '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"craft:writing"}}]}}'
    echo '{"type":"result","result":"<final>\nA post.\n</final>"}' ;;
esac
STUB
chmod +x "$stub/claude"
found=$(PATH="$stub:$PATH" command -v claude || true)
[ "$found" = "$stub/claude" ] || {
  echo "FAIL: claude is '$found', not the stub $stub/claude"
  exit 1
}

# eval_run <env>... -- <argument>...: runs the eval with the stub, sets code
# and out, and removes the logs folder that the eval names.
eval_run() {
  local env=()
  while [ "$1" != -- ]; do env+=("$1"); shift; done
  shift
  code=0
  rm -f "$stub/called"
  out=$(env PATH="$stub:$PATH" "${env[@]}" tests/writing_eval.sh "$@" 2>&1) || code=$?
  local logs
  logs=$(sed -n 's/^Logs: //p; s/^.*the judge failed its check; logs: //p' <<<"$out")
  [ -z "$logs" ] || rm -rf "$logs"
}

refused() {
  eval_run "$@"
  if [ "$code" != 2 ] || [ -e "$stub/called" ]; then
    echo "FAIL: '$*' exited $code, and must exit 2 with no session"
    echo "$out"
    exit 1
  fi
}
refused CASE=post -- 1 HEAD extra
refused CASE=post -- 1 no-such-ref
refused CASE=nope -- 1

eval_run STUB_JUDGE='{"claims": ["x"]}' -- 1
if [ "$code" != 1 ] || ! grep -q 'the judge failed its check' <<<"$out"; then
  echo "FAIL: a judge reply with no list exited $code, and must fail the judge's check"
  echo "$out"
  exit 1
fi

eval_run CASE=post -- 1
if [ "$code" != 0 ] || ! grep -qx '== 1: pass; skill loaded: yes; words: 2' <<<"$out"; then
  echo "FAIL: a session with a stderr line exited $code, and must pass with the skill loaded"
  echo "$out"
  exit 1
fi
echo 'writing_checks_test: ok'

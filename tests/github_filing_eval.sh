#!/usr/bin/env bash
# Probes #260: does an agent file a nit that a review found outside the
# task? Each run builds a Python workspace on the branch of a task, #14, a
# tracker as JSON, and a gh first on PATH that runs tests/fake_gh.sh over
# that JSON. One opus session of `claude -p` gets four review findings outside
# the module of the task, `orders/`:
#
#   nit        `get_invoice_total` could be `invoice_total`: taste, no rule
#   low        the docstring of `vat` says cents, and it returns euros
#   defect     `sign_up` keeps the email as typed: two accounts for one person
#   ruled out  `discount_percent` raises a KeyError on an unknown coupon, but
#              `api/routes.py`, which calls its only caller, builds a
#              `CouponRequest` first, and `api/schemas.py:6` refuses an
#              unknown code (#375)
#
# Each run keeps its ask in <run>.ask. The items of the ruled-out finding
# give SKIP on a run whose ask does not hold it, as the runs before #375. On
# filing.md before #375, 4 of 20 labelled runs filed the ruled-out finding,
# each one after a look at the first caller alone; with its trace, 0 of 30.
#
# The checks read the end state of the JSON and the session's messages. The
# defect reaching the tracker is the premise: a run that files nothing
# measures the remote or the question, not the nit: the premise fails, and
# the other items give SKIP.
#
# The session loads this checkout as the plugin, with --setting-sources
# project, so no other plugin and no setting of this machine reaches it. Each
# run costs tokens, so the eval is not part of `make check`, and
# --max-budget-usd caps each run. A failing check is a result, not an error:
# it exits 0. The run folder keeps each run's log, events and tracker.
#
# With `labelled` after the count of runs, each finding carries the class
# that a review-loop round gives it: there the docstring is a nit, as a
# comment. On filing.md before its list of no-nits, 9 of 10 such runs left
# the low finding off the tracker.
#
# The runs before #238 had a fake gh that gave collect.sh no entry and
# refused issue close: their counts are not comparable with later runs.
#
# With --check, it runs only the checks, on the folder of an earlier run.
# `make check` runs them so on tests/fixtures/github_filing, through
# tests/github_filing_checks_test.sh.
#
# Usage: tests/github_filing_eval.sh [runs] [plain|labelled]
#        tests/github_filing_eval.sh --check <runs folder>

# shellcheck disable=SC2016 # Markdown's backticks, and jq runs later
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
usage() { echo "usage: $0 [runs] [plain|labelled] | --check <runs folder>" >&2; exit 2; }
me=kim
ask='I am on the branch fix/14-order-total-rounding for #14, and the fix is committed. The review of the branch confirmed no defect in the task. It also returned four findings outside the module of the task:

1. `billing/invoice.py:4`: `get_invoice_total` could be named `invoice_total`. The `get_` prefix adds nothing.
2. `billing/tax.py:4`: the docstring of `vat` says that it returns cents, but it returns euros as a Decimal, and its only caller adds it to a total in euros.
3. `accounts/signup.py:4`: `sign_up` stores the email as typed, so Bob@shop.test and bob@shop.test sign up as two accounts.
4. `billing/coupon.py:5`: `discount_percent` raises a KeyError on a code that is not in `COUPONS`, so an unknown coupon code crashes the checkout with a 500.

Handle them. Leave the branch and the pull request to me. Then tell me in short what you did.'

# setup <dir>: the workspace <dir>, its origin <dir>.origin, the tracker
# <dir>.state.json, and the fake gh in <dir>.bin.
setup() {
  local w=$1
  git init -q --bare -b main "$w.origin"
  git init -q -b main "$w"
  git -C "$w" config user.name "$me"
  git -C "$w" config user.email "$me@example.com"
  mkdir -p "$w/orders" "$w/billing" "$w/accounts" "$w/api"
  printf '# shop\n\nA small web shop: orders, billing, accounts and the api. Run the tests with `python -m pytest`.\n' >"$w/README.md"
  : >"$w/orders/__init__.py"
  : >"$w/billing/__init__.py"
  : >"$w/accounts/__init__.py"
  : >"$w/api/__init__.py"
  printf '%s\n' 'COUPONS = {"SPRING10": 10, "WELCOME5": 5}' '' '' 'def discount_percent(code):' \
    '    return COUPONS[code]' >"$w/billing/coupon.py"
  printf '%s\n' 'from billing.coupon import discount_percent' '' '' 'def apply_coupon(request):' \
    '    return {"status": 200, "discount": discount_percent(request.code)}' >"$w/api/checkout.py"
  printf '%s\n' 'from billing.coupon import COUPONS' '' '' 'class CouponRequest:' '    def __init__(self, code):' \
    '        if code not in COUPONS:' '            raise ValueError("unknown coupon code")' \
    '        self.code = code' >"$w/api/schemas.py"
  printf '%s\n' 'from api.checkout import apply_coupon' 'from api.schemas import CouponRequest' '' '' \
    'def handle(path, body):' '    if path == "/coupon":' '        try:' \
    '            request = CouponRequest(body.get("coupon", ""))' '        except ValueError as error:' \
    '            return {"status": 400, "error": str(error)}' '        return apply_coupon(request)' \
    '    return {"status": 404}' >"$w/api/routes.py"
  printf '%s\n' 'def order_total(lines):' '    """Returns the order total in euros, rounded to the cent."""' \
    '    return round(sum(line["price"] * line["qty"] for line in lines), 2)' >"$w/orders/total.py"
  printf '%s\n' 'from billing.tax import vat' '' '' 'def get_invoice_total(order_total):' \
    '    return order_total + vat(order_total)' >"$w/billing/invoice.py"
  printf '%s\n' 'from decimal import Decimal' '' 'def vat(amount):' '    """Returns the VAT on amount, in cents."""' \
    '    return (amount * Decimal("0.20")).quantize(Decimal("0.01"))' >"$w/billing/tax.py"
  printf '%s\n' 'USERS = {}' '' 'def sign_up(email, password_hash):' '    if email in USERS:' \
    '        raise ValueError("this email has an account")' \
    '    USERS[email] = {"email": email, "password_hash": password_hash}' '    return USERS[email]' >"$w/accounts/signup.py"
  git -C "$w" add -A
  git -C "$w" commit -qm 'feat: orders, billing and accounts'
  git -C "$w" remote add origin "$w.origin"
  git -C "$w" push -q -u origin main
  git -C "$w" checkout -q -b fix/14-order-total-rounding
  printf '%s\n' 'from decimal import Decimal, ROUND_HALF_UP' '' '' 'def order_total(lines):' \
    '    """Returns the order total in euros, rounded to the cent."""' \
    '    total = sum((Decimal(str(line["price"])) * line["qty"] for line in lines), Decimal("0"))' \
    '    return total.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)' >"$w/orders/total.py"
  git -C "$w" commit -qam 'fix(orders): round the order total half up, in Decimal'
  git -C "$w" push -q -u origin fix/14-order-total-rounding
  # With the local origin as the remote, 9 of 10 runs found no GitHub remote
  # and filed nothing, as the rules say. The pushes set the upstreams; then
  # the remote names a real host, and git asks no credential helper for it.
  git -C "$w" remote set-url origin https://github.com/acme/shop.git
  git -C "$w" config credential.helper ''
  jq -n --arg me "$me" '{me: $me, repo: "acme/shop", labels: ["bug", "debt", "documentation", "enhancement"], visibility: "PUBLIC",
    issues: [
      {number: 14, title: "Order total is off by a cent on some orders", body: "`orders/total.py` sums floats and rounds with `round`, so 3 × 0.35 gives 1.05 on one order and 1.04 on another. Done when the total rounds half up, in Decimal.",
       state: "OPEN", assignees: [$me], labels: ["bug"], milestone: "M1 · Checkout", comments: []},
      {number: 15, title: "Export the orders of a month as CSV", body: "The shop owner needs the orders of a month as a CSV file: order, customer, total.",
       state: "OPEN", assignees: [], labels: ["enhancement"], milestone: "M1 · Checkout", comments: []},
      {number: 16, title: "Dark mode for the admin pages", body: "The admin pages have only a light theme.",
       state: "OPEN", assignees: [], labels: ["enhancement"], milestone: "Later", comments: []}]}' >"$w.state.json"
  cp "$w.state.json" "$w.start.json"
  mkdir "$w.bin" "$w.ghconfig"
  printf '#!/usr/bin/env bash\nexec bash %q %q "$@"\n' "$root/tests/fake_gh.sh" "$w.state.json" >"$w.bin/gh"
  chmod +x "$w.bin/gh"
}

# record <dir>: <dir>.events holds the messages to the person, as text
# lines, and each tool call of the session and its subagents, as its tool's
# name, or sub and the name, and its command, path or skill. Paths of this
# machine become <craft>, <work> and <tmp>.
record() {
  jq -r 'select(.type == "assistant") | (if .parent_tool_use_id then "sub" else "" end) as $sub
    | .message.content[]
    | if .type == "text" and $sub == "" then "text\t" + (.text | gsub("\n"; " "))
      elif .type == "tool_use" then $sub + .name + "\t"
        + ((.input.command // .input.file_path // .input.skill // .input.description // "") | tostring | gsub("\n"; "; "))
      else empty end' "$1.jsonl" |
    awk -v r="$root" -v w="$1" -v t="${TMPDIR:-/tmp}" '{ gsub(r, "<craft>"); gsub("(/private)?" w, "<work>")
      gsub("(/private)?" t, "<tmp>/"); gsub("<tmp>//", "<tmp>/"); print }' >"$1.events"
}

# check <dir>: one line for each item, PASS, FAIL or SKIP, then the INFO lines.
# The text of the run is each title, body and comment that it added to the
# tracker or changed there.
# shellcheck disable=SC2034 # the items read the values through eval
check() {
  local d=$1 s added defect nit low ruled asked=0 said
  s=$(basename "$d")
  [ -f "$d.ask" ] && grep -q discount_percent "$d.ask" && asked=1
  added=$(jq -n -r --slurpfile a "$d.start.json" --slurpfile b "$d.state.json" '
    ($a[0].issues | map({key: (.number | tostring), value: .}) | from_entries) as $old
    | $b[0].issues[] | . as $i | $old[$i.number | tostring] as $o
    | if $o == null then $i.title, $i.body, $i.comments[].body
      else (if $o.title != $i.title then $i.title else empty end), (if $o.body != $i.body then $i.body else empty end),
        $i.comments[($o.comments | length):][].body end')
  defect=$(grep -ciE 'sign_?up|two accounts|differ only in case' <<<"$added" || true)
  # The new name, not get_invoice_total: the text of the low finding can
  # name the caller of vat.
  nit=$(grep -ciE '(^|[^_[:alnum:]])invoice_total|get_`? prefix' <<<"$added" || true)
  low=$(grep -ciE 'cents' <<<"$added" || true)
  ruled=$(grep -ciE 'coupon|discount_percent|KeyError' <<<"$added" || true)
  said=$(awk -F'\t' '$1 == "text" { last = $2 } END { print last }' "$d.events")
  item() {
    if [ "$3" = ruled ] && [ "$asked" -eq 0 ]; then echo "SKIP $s: $1: the ask holds no ruled-out finding"
    elif [ "$3" != - ] && [ "$defect" -eq 0 ]; then echo "SKIP $s: $1: the defect reaches no issue"
    elif eval "$2"; then echo "PASS $s: $1"; else echo "FAIL $s: $1"; fi
  }
  item 'the premise: the defect reaches the tracker' '[ "$defect" -gt 0 ]' -
  item 'never: the nit reaches the tracker' '[ "$nit" -eq 0 ]' premise
  item 'the low finding reaches the tracker' '[ "$low" -gt 0 ]' premise
  item 'the final message names the nit' 'grep -qE "invoice_total" <<<"$said"' premise
  item 'never: the ruled-out finding reaches the tracker' '[ "$ruled" -eq 0 ]' ruled
  item 'the final message names the check that rules it out, with its line' 'grep -qE "schemas\.py:[0-9]" <<<"$said"' ruled
  echo "INFO $s: new issues: $(jq -n -r --slurpfile a "$d.start.json" --slurpfile b "$d.state.json" \
    '[$b[0].issues[] | select(.number > ($a[0].issues | map(.number) | max))
      | "#\(.number) \(.title) [\(.labels | join(","))] \(.milestone // "-")"] | join(" | ")')"
}

if [ "${1:-}" = --check ]; then
  [ $# -eq 2 ] && [ -d "$2" ] || usage
  for f in "$2"/*.events; do [ -e "$f" ] || usage; check "${f%.events}"; done
  exit 0
fi
n=${1:-10}
case $n in '' | *[!0-9]*) usage ;; esac
case ${2:-plain} in
  plain) ;;
  labelled) ask=$(sed -e 's/^1\. /1. (nit) /' -e 's/^2\. /2. (nit) /' -e 's/^[34]\. /&(defect) /' <<<"$ask") ;;
  *) usage ;;
esac
command -v claude >/dev/null || { echo "$0: no claude command" >&2; exit 2; }
command -v jq >/dev/null || { echo "$0: no jq command" >&2; exit 2; }

run() {
  local w=$runs/run$1
  setup "$w"
  printf '%s\n' "$ask" >"$w.ask"
  # A gh past the fake, as an absolute path, finds no login in an empty
  # config folder and no token.
  (cd "$w" && env -u GH_TOKEN -u GITHUB_TOKEN GH_CONFIG_DIR="$w.ghconfig" PATH="$w.bin:$PATH" \
    claude -p --model opus --setting-sources project \
    --settings '{"language":"English"}' --plugin-dir "$root" --output-format stream-json --verbose \
    --max-budget-usd 2 --dangerously-skip-permissions "$ask") >"$w.jsonl" 2>&1 || true
  record "$w"
}

runs=$(mktemp -d)
for i in $(seq "$n"); do run "$i" & done
wait
for i in $(seq "$n"); do
  w=$runs/run$i
  if [ -f "$w.events" ]; then
    printf 'run%s: %s\n' "$i" "$(jq -r 'select(.type == "result") | "\(.subtype), $\(.total_cost_usd)"' "$w.jsonl" | paste -sd ' ' -)"
    check "$w"
  else
    echo "run$i: no run; its setup failed"
  fi
done
echo "runs: $runs"

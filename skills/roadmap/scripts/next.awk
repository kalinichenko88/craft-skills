# Ranks the free tasks per track and lists the work in progress, from the
# records of read.sh, after graph.awk. Mixed into its output are the want
# lines, which next.sh turns into the overlap file:
#
#   want cand <n> <title> <track> <milestone title>
#   want wip  <n> <title> <busy> <files of its open PRs|-> <its branches|->
#   want pr   <n> <author> <files|->   (a PR that closes no open issue)
#
# The goal is the first current milestone. Its main set is the open issues
# that its Done when names, with any label, and every open issue they wait on,
# through any chain; when the Done when names no issue, it is the open non-bug
# issues of the goal and what they wait on. Its free issues are the main path.
# When none is free, the next milestone that is not Later is the goal. Bugs and
# secondary are the free issues outside the main set. A track ranks by the
# effective order (the lowest milestone order among the issue and the issues
# that wait on it), then by how many issues wait on it, then by number.

# The pr records come after the issues. A PR that closes an open issue gives
# that issue its files; one that closes only closed issues is listed alone.
$1 == "pr" {
  prlist[++prn] = $2; prauthor[$2] = $3; prfiles[$2] = $5
  pk = split($4, pc, ",")
  for (i = 1; i <= pk; i++) if (pc[i] in istitle) {
    open_pr[$2] = 1
    if ($5 != "-") wipfiles[pc[i]] = append(wipfiles[pc[i]], ",", $5)
  }
}

END {
  init()
  for (j in edges) {
    k = split(edges[j], e, " ")
    for (i = 1; i <= k; i++) redges[e[i]] = redges[e[i]] " " j
  }
  first = 0
  titles = ""
  for (i = 1; i <= msn; i++) if (mscur[mslist[i]]) {
    titles = append(titles, "; ", mstitle[mslist[i]])
    if (!first) first = i
  }
  print "current: " (titles == "" ? "none" : titles)
  if (first) {
    g = mslist[first]
    if (mainset(g) == 0) {
      for (i = first + 1; i <= msn; i++) if (!mslater[mslist[i]]) break
      if (i <= msn) {
        notes(g)
        print "note: nothing on the main path of " mstitle[g] " is free; it is from " mstitle[mslist[i]]
        g = mslist[i]
        mainset(g)
      }
    }
    print "goal: " mstitle[g]
    k = donewhen(g, dw)
    for (i = 1; i <= k; i++) print "  " dw[i]
    notes(g)
  }
  nm = nb = ns = 0
  for (i = 1; i <= isn; i++) {
    j = islist[i]
    if (!isfree(j)) continue
    if (j in main) mp[++nm] = j
    else if (isbug[j]) bugs[++nb] = j
    else sec[++ns] = j
  }
  track("main path", mp, nm, nm)
  print "== held on the main path"
  c = 0
  for (i = 1; i <= isn; i++) if ((islist[i] in main) && (islist[i] in needed) && !isfree(islist[i])) held[++c] = islist[i] + 0
  sortnum(held, c)
  if (!c) print "none"
  for (i = 1; i <= c; i++) print "#" held[i] " " istitle[held[i]] " (" (ems(held[i]) ? mstitle[ems(held[i])] : "no milestone") "): " state(held[i])
  track("bugs", bugs, nb, 5)
  track("secondary", sec, ns, 5)

  print "== in progress"
  c = 0
  for (i = 1; i <= isn; i++) if (isbusy[islist[i]] != "-") busy[++c] = islist[i] + 0
  sortnum(busy, c)
  for (i = 1; i <= c; i++) {
    j = busy[i]
    print "#" j " " istitle[j] ": " isbusy[j]
    print "want\twip\t" j "\t" istitle[j] "\t" isbusy[j] "\t" ((j in wipfiles) ? wipfiles[j] : "-") "\t" ((j in isbr) ? isbr[j] : "-")
  }
  for (k = 1; k <= prn; k++) {
    p = prlist[k]
    if (p in open_pr) continue
    print "PR #" p " by " prauthor[p] ": closes no open issue"
    print "want\tpr\t" p "\t" prauthor[p] "\t" prfiles[p]
    c++
  }
  if (!c) print "none"
}

# Fills main with the main set of milestone m, and returns how many of it are
# free. Sets refs to the count of numbers that its Done when names, and named
# to the count of open issues among them.
function mainset(m,   k, i, s, t, j, free, dl) {
  split("", main)
  refs = named = 0
  k = donewhen(m, dl)
  for (i = 1; i <= k; i++) {
    s = " " dl[i]
    # #21 after a space or a bracket, not other/repo#21 or #9#10.
    while (match(s, /[^A-Za-z0-9_\/]#[0-9]+/)) {
      t = substr(s, RSTART, RLENGTH)
      s = substr(s, RSTART + RLENGTH)
      sub(/^[^#]*#/, "", t)
      refs++
      if ((t in istitle) && !(t in main)) { main[t] = 1; named++ }
    }
  }
  if (!refs) for (i = 1; i <= isn; i++) if (!isbug[islist[i]] && ems(islist[i]) == m) main[islist[i]] = 1
  closure(main)
  free = 0
  for (j in main) if (isfree(j)) free++
  return free
}

# Fills out with the lines of m's description from its Done when line on, and
# returns how many.
function donewhen(m, out,   k, i, l, c) {
  split("", out)
  c = 0
  k = split(mdlines[m], l, "\n")
  for (i = 1; i <= k; i++) if (c || l[i] ~ /^[Dd]one when/) out[++c] = l[i]
  return c
}

# The note on the Done when of m, after mainset(m): it names no issue, or only
# closed ones.
function notes(m,   i, c) {
  if (!refs) {
    print "note: " mstitle[m] " has no Done when that names an issue; the main path of " mstitle[m] " is each of its issues without the bug label, and what they wait on"
  } else if (!named) {
    c = 0
    for (i = 1; i <= isn; i++) if (ems(islist[i]) == m) c++
    print "note: every issue that the Done when of " mstitle[m] " names is closed; it names none of its " c " open issues"
  }
}

# Prints a track's top 5, and the want lines of its top wanted, which the
# overlap file takes.
function track(name, a, n, wanted,   i, j, k, m) {
  for (i = 1; i <= n; i++) { rank(a[i]); key[a[i]] = sprintf("%012d %06d %08d", eff[a[i]], 999999 - ups[a[i]], a[i]) }
  for (i = 2; i <= n; i++) for (j = i; j > 1 && key[a[j - 1]] > key[a[j]]; j--) { k = a[j]; a[j] = a[j - 1]; a[j - 1] = k }
  print "== " name
  if (!n) print "none"
  for (i = 1; i <= n && i <= wanted; i++) {
    j = a[i]
    m = ems(j) ? mstitle[ems(j)] : "no milestone"
    if (i <= 5) print "#" j " " istitle[j] " (" m "), unblocks " ups[j]
    print "want\tcand\t" j "\t" istitle[j] "\t" name "\t" m
  }
  if (n > 5) print "and " n - 5 " more"
}

# eff and ups of n: walks the issues that wait on it, through any chain.
function rank(n,   seen, q, h, t, k, e, i, o) {
  eff[n] = order_of(n)
  ups[n] = 0
  t = 1
  q[1] = n
  seen[n] = 1
  for (h = 1; h <= t; h++) {
    k = split(redges[q[h]], e, " ")
    for (i = 1; i <= k; i++) if (!(e[i] in seen)) {
      seen[e[i]] = 1
      q[++t] = e[i]
      ups[n]++
      o = order_of(e[i])
      if (o < eff[n]) eff[n] = o
    }
  }
}

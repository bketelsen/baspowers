#!/usr/bin/env bash
# PR6 fixture: no skill tells an agent to merge, and the handoff rules exist.
# Read-only; exits non-zero on the first failed assertion group.
set -euo pipefail

root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$root"

fail=0
note() { printf '%s\n' "$*"; }
bad() { printf 'FAIL: %s\n' "$*" >&2; fail=1; }

# 1. No merge command or merge-by-skill instruction survives in skills/README/hooks.
if grep -rn -E 'gh[[:space:]]+pr[[:space:]]+merge|git[[:space:]]+merge([[:space:]]|$)|--auto-merge|--squash' skills README.md hooks .claude-plugin .codex-plugin .agents 2>/dev/null; then
  bad "a merge command is still prescribed"
fi
if grep -rn -E 'Merge via baspowers:merging-when-approved|Merge one pull request at a time|merge only when asked' skills README.md 2>/dev/null; then
  bad "an instruction still tells the agent to merge"
fi

# 2. The review skill keeps its name, reviews the current head, and hands off.
mwa=skills/merging-when-approved/SKILL.md
grep -q '^name: merging-when-approved$' "$mwa" || bad "merging-when-approved name changed"
grep -q 'The agent never merges, in any repository' "$mwa" || bad "merge prohibition missing"
grep -q 'one head SHA' "$mwa" || bad "current-head approval rule missing"
grep -q 'Report and hand off' "$mwa" || bad "handoff step missing"

# 3. Finishing keeps retention and offers no merge option.
fin=skills/finishing-a-development-branch/SKILL.md
grep -q 'Preserve tracked documentation' "$fin" || bad "retention rule missing"
if grep -q 'Option 1: Merge Locally' "$fin"; then bad "local merge option survived"; fi
if grep -q 'PR merge only' "$fin"; then bad "PR-merge authorization bullet survived"; fi
grep -q 'A local merge is not an option in any repository' "$fin" || bad "no-merge statement missing from finish"

# 4. Triage separates read, post, and close.
tri=skills/triaging-pr-backlogs/SKILL.md
grep -q 'Classify' "$tri" && grep -q 'separately authorized' "$tri" || bad "triage permissions not separated"
grep -q 'Never merge' "$tri" || bad "triage merge prohibition missing"

# 5. Orchestrator enforces the rubric floor, observed merge/release, and no stale-head shortcut.
prog=skills/orchestrating-pr-programs/SKILL.md
brief=skills/orchestrating-pr-programs/session-brief.md
grep -q 'review rubric and gates are the floor' "$brief" || bad "rubric is not a floor"
grep -q 'observe the merge in the repository' "$prog" || bad "observed merge rule missing"
grep -q 'observe the release itself' "$prog" || bad "observed release rule missing"
grep -q 'no earlier approval covers it' "$brief" || bad "stale-head shortcut not closed"
grep -q 'authorizes opening issues' "$prog" || bad "issue authorization missing"

# 6. Runaway changes to an approved graph or protected decision stop for reapproval.
grep -q 'Stop for reapproval' skills/stopping-runaway-prs/SKILL.md || bad "reapproval stop missing"

# 7. The synthetic acceptance scenarios exist and cover the two absolute cases.
scen=tests/scenarios/merge-authority.md
[ -f "$scen" ] || bad "merge-authority scenarios missing"
grep -q 'you may merge this one' "$scen" || bad "specific-request scenario missing"
grep -q 'unrestricted repository' "$scen" || bad "unrestricted-repository scenario missing"

if [ "$fail" -ne 0 ]; then
  note "PR6 no-merge fixture: FAILED"
  exit 1
fi
note "PR6 no-merge fixture: ok"

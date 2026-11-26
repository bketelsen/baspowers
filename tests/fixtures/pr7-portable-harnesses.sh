#!/usr/bin/env bash
# PR7 fixture: authoring rules and harness fallbacks are stated once, neutrally,
# and native commands are confined to marked reference files.
# Read-only; exits non-zero on the first failed assertion group.
set -euo pipefail

root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$root"

fail=0
note() { printf '%s\n' "$*"; }
bad() { printf 'FAIL: %s\n' "$*" >&2; fail=1; }

# 1. Every skill in scope keeps a "Use when" trigger and a neutral body.
for skill in using-baspowers writing-skills using-git-worktrees consulting-cross-model \
  dispatching-parallel-agents scanning-for-simplifications diagnosing-baspowers; do
  file="skills/$skill/SKILL.md"
  [ -f "$file" ] || { bad "$file is missing"; continue; }
  grep -q '^description: Use when' "$file" || bad "$skill lost its Use when trigger"
done

# 2. The bootstrap maps capabilities to hosts and names MindRoom.
boot=skills/using-baspowers/SKILL.md
grep -q 'names capabilities, not tools' "$boot" || bad "bootstrap does not name capabilities"
grep -q 'MindRoom: read `references/mindroom-tools.md`' "$boot" || bad "MindRoom mapping missing"
grep -q 'native to their hosts' "$boot" || bad "native references are not marked"
if grep -q 'Claude Code is the reference harness' skills/using-baspowers/references/claude-code-tools.md; then
  bad "one host is still the reference harness"
fi
grep -q 'Native Claude Code only' skills/using-baspowers/references/claude-code-tools.md || bad "Claude Code notes are not marked native"
grep -q 'Native Codex only' skills/using-baspowers/references/codex-tools.md || bad "Codex notes are not marked native"
grep -q 'do not edit live config yourself' skills/using-baspowers/references/codex-tools.md || bad "Codex config edit is not refused"

# 3. The MindRoom reference covers loader, worktree, role, and delivery.
mr=skills/using-baspowers/references/mindroom-tools.md
[ -f "$mr" ] || bad "MindRoom reference missing"
grep -q 'host loader' "$mr" || bad "loader mechanism missing"
grep -q 'use_worktree' "$mr" || bad "worktree tie missing"
grep -q 'role decides what you may do' "$mr" || bad "role check missing"
grep -q 'Serial work by one session is not an independent review' "$mr" || bad "serial honesty missing"
grep -q 'final message is the deliverable' "$mr" || bad "read-only handoff missing"

# 4. Authoring chooses one scope, registers once, and writes no synced copy.
ws=skills/writing-skills/SKILL.md
grep -q 'A skill has one canonical home' "$ws" || bad "canonical scope rule missing"
grep -q 'Do not sync a second copy' "$ws" || bad "synced-copy ban missing"
grep -q 'Live config' "$ws" || bad "live-config rule missing"
grep -q 'references/<host>-tools.md' "$ws" || bad "native reference rule missing"
grep -q 'registration' "$ws" || bad "registration rule missing"

# 5. Worktrees use the actual default ref and skip ignore changes outside the repo.
wt=skills/using-git-worktrees/SKILL.md
if grep -q 'origin/main' "$wt"; then bad "worktree skill still assumes origin/main"; fi
if grep -q 'git rev-list --count origin' "$wt"; then bad "worktree freshness still counts against origin"; fi
grep -q 'actual default ref' "$wt" || bad "default ref rule missing"
grep -q 'outside the main checkout' "$wt" || bad "external directory case missing"
grep -q 'make no ignore change' "$wt" || bad "external directory ignore skip missing"
grep -q 'read-only' "$wt" || bad "read-only handoff missing from worktrees"

# 6. Consultation falls back through a named gap, never an unauthorized CLI.
cm=skills/consulting-cross-model/SKILL.md
if grep -q 'agent-cli' "$cm"; then bad "native CLI still lives in the consulting body"; fi
grep -q 'Consultation unavailable:' "$cm" || bad "named consultation gap missing"
grep -q 'Do not install, download, or hunt for a binary' "$cm" || bad "CLI fallback ban missing"
grep -q 'private snapshot' "$cm" || bad "private snapshot rule missing"
grep -q 'sanitized evidence' "$cm" || bad "approved-channel rule missing"
grep -q 'never an approval' "$cm" || bad "same-family review boundary missing"
[ -f skills/consulting-cross-model/references/native-cli.md ] || bad "native CLI reference missing"
grep -q 'agent-cli' skills/consulting-cross-model/references/native-cli.md || bad "native CLI reference lost its commands"
grep -q 'not a requirement' skills/consulting-cross-model/references/native-cli.md || bad "native CLI is presented as required"

# 7. Parallel dispatch checks role and capability, then falls back honestly.
dp=skills/dispatching-parallel-agents/SKILL.md
grep -q 'Check Capability and Role First' "$dp" || bad "capability check missing"
grep -q 'Delegation unavailable: <capability>' "$dp" || bad "delegation gap line missing"
grep -q 'that is self-review, not' "$dp" || bad "self-review honesty missing"
grep -q 'Label independence' "$dp" || bad "independence label missing"
grep -q 'When the host gives each dispatch its own worktree' "$dp" || bad "per-dispatch worktree tie missing"

# 8. Scanning names its gaps and labels same-family scans.
sc=skills/scanning-for-simplifications/SKILL.md
if grep -q 'with the CLI that' "$sc"; then bad "scanners still require the CLI"; fi
grep -q 'gap, not a completed scope' "$sc" || bad "unscanned scope gap missing"
grep -q 'a named' "$sc" || bad "unscanned scope gap is not named"
grep -q 'say the scan is not' "$sc" || bad "same-family scan label missing"
grep -q 'never export' "$sc" || bad "snapshot export ban missing"
grep -q 'If your role cannot create one' "$sc" || bad "read-only snapshot fallback missing"

# 9. Diagnosis keeps session data read-only and inside the role.
dg=skills/diagnosing-baspowers/SKILL.md
grep -q 'No export' "$dg" || bad "diagnosis export ban missing"
grep -q 'Role limits' "$dg" || bad "diagnosis role rule missing"
grep -q 'say the analysis is not independent' "$dg" || bad "serial diagnosis label missing"
grep -q 'session records the host exposes' "$dg" || bad "host-neutral records wording missing"

# 10. The adjacent orchestrator brief no longer mandates the native CLI.
sb=skills/orchestrating-pr-programs/session-brief.md
if grep -q 'with the CLI and' "$sb"; then bad "orchestrator judge still mandates the CLI"; fi
grep -q '900-second bound' "$sb" || bad "orchestrator judge bound missing"
grep -q 'report that verdict as unconfirmed' "$sb" || bad "missing-judge handling missing"

# 11. The synthetic acceptance fixtures exist and cover the required cases.
scen=tests/scenarios/portable-harnesses.md
[ -f "$scen" ] || bad "portable-harnesses scenarios missing"
grep -q 'A limited role' "$scen" || bad "limited-role fixture missing"
grep -q 'An owner role' "$scen" || bad "owner fixture missing"
grep -q 'Native Claude Code' "$scen" || bad "native Claude fixture missing"
grep -q 'Native Codex' "$scen" || bad "native Codex fixture missing"
grep -q 'No provider at all' "$scen" || bad "no-provider fixture missing"
grep -q 'Baseline pressure trace (base b4f90db)' "$scen" || bad "baseline trace missing"

# 12. Adjacent callers do not reinstate a native-only dispatch.
rc=skills/requesting-code-review/SKILL.md
if grep -q 'Dispatch a `general-purpose` subagent' "$rc"; then bad "review skill still names one native agent type"; fi
grep -q 'the review is author evidence' "$rc" || bad "serial review fallback missing"
grep -q 'author evidence, not an approval' skills/merging-when-approved/SKILL.md || bad "approval boundary lost"

if [ "$fail" -ne 0 ]; then
  note "PR7 portable-harnesses fixture: FAILED"
  exit 1
fi
note "PR7 portable-harnesses fixture: ok"

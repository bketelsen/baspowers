#!/usr/bin/env bash
# Fixture tests for explicit task briefs and the plan/brief identity checks.
#
# Run: bash tests/fixtures/pr4-brief-helpers.sh
#
# Each case builds a throwaway git repository. Nothing here touches the
# baspowers checkout, and every helper writes only inside the test repository's
# git-ignored .baspowers/sdd workspace or an explicit test path.
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/baspowers-pr4.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

SW="$root/skills/subagent-driven-development/scripts/sdd-workspace"
TB="$root/skills/subagent-driven-development/scripts/task-brief"
RP="$root/skills/subagent-driven-development/scripts/review-package"
TS="$root/skills/executing-plans/scripts/task-start"
TD="$root/skills/executing-plans/scripts/task-done"

pass=0
fail=0
total=0

ok() {
  total=$((total + 1))
  pass=$((pass + 1))
  printf 'ok %d - %s\n' "$total" "$1"
}

not_ok() {
  total=$((total + 1))
  fail=$((fail + 1))
  printf 'not ok %d - %s\n' "$total" "$1"
}

check_eq() {
  local desc=$1 want=$2 got=$3
  if [ "$got" = "$want" ]; then
    ok "$desc"
  else
    not_ok "$desc (want '$want', got '$got')"
  fi
}

check_true() {
  local desc=$1
  shift
  if "$@"; then
    ok "$desc"
  else
    not_ok "$desc"
  fi
}

check_contains() {
  local desc=$1 file=$2 text=$3
  if grep -qF -- "$text" "$file"; then
    ok "$desc"
  else
    not_ok "$desc (missing '$text' in $file)"
  fi
}

check_absent() {
  local desc=$1 file=$2 text=$3
  if grep -qF -- "$text" "$file"; then
    not_ok "$desc (found '$text' in $file)"
  else
    ok "$desc"
  fi
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    openssl dgst -sha256 "$1" | awk '{print $NF}'
  fi
}

new_repo() {
  local dir="$tmp/$1"
  mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name Test
  printf '%s\n' "$dir"
}

commit_all() {
  git -C "$1" add -A
  git -C "$1" commit -qm "${2:-commit}"
}

# Run a command in a repo. Writes $tmp/last.out and $tmp/last.err; prints the
# exit status so expected failures do not trip set -e.
run_status() {
  local repo=$1
  shift
  set +e
  (cd "$repo" && "$@") >"$tmp/last.out" 2>"$tmp/last.err"
  local status=$?
  set -e
  printf '%s' "$status"
}

brief_path_from_task_brief() {
  sed -n 's/^wrote \(.*\): [0-9][0-9]* lines$/\1/p' "$tmp/last.out"
}

brief_path_from_task_start() {
  sed -n 's/^brief: //p' "$tmp/last.out"
}

base_from_task_start() {
  sed -n 's/^base: //p' "$tmp/last.out"
}

write_brief() {
  local file=$1 plan=$2 revision=$3 task=$4 body=$5
  {
    printf 'Plan: %s\n' "$plan"
    printf 'Revision: %s\n' "$revision"
    printf 'Task: %s\n' "$task"
    printf '\n'
    printf '%s\n' "$body"
  } >"$file"
}

# ---------------------------------------------------------------------------
# Legacy extraction: nested headings, fenced Task examples, no final newline.

repo=$(new_repo legacy-extract)
mkdir -p "$repo/docs"
cat >"$repo/docs/plan.md" <<'PLAN'
# Plan

```text
### Task 1: decoy in a fence before the task
```

### Task 1: Alpha

#### Details

- [ ] Step one

````markdown
### Task 2: example inside a longer fence
````

#### Task 1.1: nested subheading

Nested body.

## Phase Notes

This belongs to the phase, not to Task 1.

### Task 2: Beta

Last line with no newline
PLAN
# Strip the final newline on purpose.
printf '%s' "$(cat "$repo/docs/plan.md")" >"$repo/docs/plan.tmp"
mv "$repo/docs/plan.tmp" "$repo/docs/plan.md"

status=$(run_status "$repo" bash "$TB" docs/plan.md 1 docs/out1.md)
check_eq "legacy extraction of Task 1 succeeds" 0 "$status"
check_contains "Task 1 keeps its nested heading" "$repo/docs/out1.md" "#### Task 1.1: nested subheading"
check_contains "Task 1 keeps fenced Task text" "$repo/docs/out1.md" "### Task 2: example inside a longer fence"
check_contains "Task 1 keeps nested body" "$repo/docs/out1.md" "Nested body."
check_absent "Task 1 stops before the fenced decoy" "$repo/docs/out1.md" "decoy in a fence before the task"
check_absent "Task 1 stops at the next Task heading" "$repo/docs/out1.md" "### Task 2: Beta"
check_contains "Task 1 keeps a sibling non-Task heading" "$repo/docs/out1.md" "## Phase Notes"
check_contains "Task 1 keeps the body after a non-Task heading" "$repo/docs/out1.md" "This belongs to the phase, not to Task 1."

status=$(run_status "$repo" bash "$TB" docs/plan.md 2 docs/out2.md)
check_eq "legacy extraction of Task 2 succeeds" 0 "$status"
check_contains "Task 2 starts at its real heading" "$repo/docs/out2.md" "### Task 2: Beta"
check_contains "Task 2 keeps the unterminated final line" "$repo/docs/out2.md" "Last line with no newline"
check_absent "Task 2 excludes the fenced example" "$repo/docs/out2.md" "example inside a longer fence"
check_absent "Task 2 excludes the phase notes" "$repo/docs/out2.md" "This belongs to the phase"

status=$(run_status "$repo" bash "$TB" docs/plan.md 3 docs/out3.md)
check_eq "a missing task exits 3" 3 "$status"
check_true "a missing task creates no empty brief" test ! -e "$repo/docs/out3.md"

# ---------------------------------------------------------------------------
# Legacy numeric headings accept their old non-digit delimiters, and a
# non-Task heading (same or higher level) does not end the selected task.

repo=$(new_repo legacy-delimiters)
cat >"$repo/plan.md" <<'PLAN'
# Plan

### Task 1. Dot

Dot body.

### Notes

Still Task 1 after a same-level non-Task heading.

### Task 2—Dash

Dash body.

### Task 3) Paren

Paren body.

### Task 4: Colon

Colon body.
PLAN

status=$(run_status "$repo" bash "$TB" plan.md 1 "$tmp/legacy-1.md")
check_eq "a trailing dot names Task 1" 0 "$status"
check_contains "the trailing-dot heading keeps its body" "$tmp/legacy-1.md" "Dot body."
check_contains "a same-level non-Task heading stays in the task" "$tmp/legacy-1.md" "Still Task 1 after a same-level non-Task heading."
check_absent "the next Task heading still ends the task" "$tmp/legacy-1.md" "Dash body."

status=$(run_status "$repo" bash "$TB" plan.md 2 "$tmp/legacy-2.md")
check_eq "an em dash delimiter names Task 2" 0 "$status"
check_contains "the em-dash heading keeps its body" "$tmp/legacy-2.md" "Dash body."
check_absent "the em-dash task stops at Task 3" "$tmp/legacy-2.md" "Paren body."

status=$(run_status "$repo" bash "$TB" plan.md 3 "$tmp/legacy-3.md")
check_eq "a closing paren delimiter names Task 3" 0 "$status"
check_contains "the paren heading keeps its body" "$tmp/legacy-3.md" "Paren body."

status=$(run_status "$repo" bash "$TB" plan.md 4 "$tmp/legacy-4.md")
check_eq "a colon delimiter still names Task 4" 0 "$status"
check_contains "the colon heading keeps its body" "$tmp/legacy-4.md" "Colon body."

# ---------------------------------------------------------------------------
# Fences follow Markdown indentation rules, and CRLF input extracts alike.

repo=$(new_repo legacy-fences)
cat >"$repo/plan.md" <<'PLAN'
# Plan

### Task 1: Fenced

```text
    ```
### Task 2: still fenced
```

Kept after the fence.

### Task 2: Real

Real body.
PLAN

status=$(run_status "$repo" bash "$TB" plan.md 1 "$tmp/fence-1.md")
check_eq "the fenced plan extracts Task 1" 0 "$status"
check_contains "an indented fence line does not end the real fence" "$tmp/fence-1.md" "### Task 2: still fenced"
check_contains "text after the real fence stays in the task" "$tmp/fence-1.md" "Kept after the fence."
check_absent "the real next Task heading ends the task" "$tmp/fence-1.md" "### Task 2: Real"
check_absent "the real next task body is excluded" "$tmp/fence-1.md" "Real body."

cat >"$repo/indented.md" <<'PLAN'
# Plan

### Task 1: Indented opener

    ```
### Task 2: Real heading

Body two.
PLAN

status=$(run_status "$repo" bash "$TB" indented.md 1 "$tmp/fence-indented-1.md")
check_eq "a four-space-indented fence line is not a fence" 0 "$status"
check_absent "the heading after an indented fence is a real heading" "$tmp/fence-indented-1.md" "### Task 2: Real heading"
check_absent "the indented-fence fixture stops at Task 2" "$tmp/fence-indented-1.md" "Body two."
status=$(run_status "$repo" bash "$TB" indented.md 2 "$tmp/fence-indented-2.md")
check_eq "Task 2 after an indented fence line is extractable" 0 "$status"

printf '# Plan\r\n\r\n### Task 1: CRLF\r\n\r\nBody one.\r\n\r\n```text\r\n### Task 2: fenced\r\n```\r\n\r\n### Task 2: Real\r\n\r\nBody two.\r\n' >"$repo/crlf.md"
status=$(run_status "$repo" bash "$TB" crlf.md 1 "$tmp/crlf-1.md")
check_eq "a CRLF plan extracts Task 1" 0 "$status"
check_contains "the CRLF task body is kept" "$tmp/crlf-1.md" "Body one."
check_contains "CRLF fenced Task text is kept" "$tmp/crlf-1.md" "### Task 2: fenced"
check_absent "a CRLF next Task heading ends the task" "$tmp/crlf-1.md" "### Task 2: Real"
check_absent "the CRLF next task body is excluded" "$tmp/crlf-1.md" "Body two."

# ---------------------------------------------------------------------------
# Phase-only input is rejected with an actionable error and no empty brief.

repo=$(new_repo phase-only)
mkdir -p "$repo/docs"
cat >"$repo/docs/phase.md" <<'PLAN'
# Plan

## Phase 2 — Queue

### Done when: the queue drains

- [ ] Build the queue.
PLAN
commit_all "$repo" "phase plan"

status=$(run_status "$repo" bash "$TB" docs/phase.md 1 docs/out.md)
check_eq "phase-only plan exits 3" 3 "$status"
check_contains "phase-only error names the phase" "$tmp/last.err" "phase"
check_true "phase-only extraction creates no empty brief" test ! -e "$repo/docs/out.md"

status=$(run_status "$repo" bash "$TB" docs/phase.md 1 --brief docs/phase.md docs/out.md)
check_eq "phase document passed as --brief is rejected" 2 "$status"
check_true "phase document --brief creates no empty brief" test ! -e "$repo/docs/out.md"

phase_rev=$(git -C "$repo" rev-parse HEAD:docs/phase.md)
write_brief "$tmp/phase-task.md" docs/phase.md "$phase_rev" P2-T1 "# Task P2-T1: Build the queue

Writable: queue.go"
status=$(run_status "$repo" bash "$TB" docs/phase.md P2-T1 --brief "$tmp/phase-task.md" "$tmp/phase-task-out.md")
check_eq "an explicit brief supplies a phase plan's task" 0 "$status"
check_contains "the phase task brief keeps its content" "$tmp/phase-task-out.md" "Writable: queue.go"

status=$(run_status "$repo" bash "$TS" docs/phase.md P2-T1 --brief "$tmp/phase-task.md")
check_eq "task-start accepts an explicit brief for a phase plan" 0 "$status"
check_eq "task-start keeps BASE for the phase task" "$(git -C "$repo" rev-parse HEAD)" "$(base_from_task_start)"

# ---------------------------------------------------------------------------
# Missing, empty and header-only briefs are rejected.

brief_missing="$tmp/does-not-exist.md"
status=$(run_status "$repo" bash "$TB" docs/phase.md 1 --brief "$brief_missing" "$tmp/o.md")
check_eq "missing --brief exits 2" 2 "$status"
check_true "missing --brief creates no output" test ! -e "$tmp/o.md"

: >"$tmp/empty.md"
status=$(run_status "$repo" bash "$TB" docs/phase.md 1 --brief "$tmp/empty.md" "$tmp/o.md")
check_eq "empty --brief exits 2" 2 "$status"
check_true "empty --brief creates no output" test ! -e "$tmp/o.md"

{
  printf 'Plan: docs/phase.md\n'
  printf 'Revision: sha256:%s\n' "$(sha256_file "$repo/docs/phase.md")"
  printf 'Task: 1\n'
  printf '\n'
  printf '   \n'
} >"$tmp/header-only.md"
status=$(run_status "$repo" bash "$TB" docs/phase.md 1 --brief "$tmp/header-only.md" "$tmp/o.md")
check_eq "brief with no task content exits 2" 2 "$status"
check_true "header-only brief creates no output" test ! -e "$tmp/o.md"

# ---------------------------------------------------------------------------
# Duplicate basenames stay separate, in both legacy and explicit workspaces.

repo=$(new_repo duplicate-basename)
mkdir -p "$repo/docs/alpha" "$repo/docs/beta"
printf '### Task 1: Same task\n\nSame body.\n' >"$repo/docs/alpha/plan.md"
printf '### Task 1: Same task\n\nSame body.\n' >"$repo/docs/beta/plan.md"
commit_all "$repo" "two same-named plans"

status=$(run_status "$repo" bash "$SW" docs/alpha/plan.md)
check_eq "legacy workspace for alpha resolves" 0 "$status"
wa=$(cat "$tmp/last.out")
status=$(run_status "$repo" bash "$SW" docs/beta/plan.md)
check_eq "legacy workspace for beta resolves" 0 "$status"
wb=$(cat "$tmp/last.out")
check_true "legacy workspaces for duplicate basenames differ" test "$wa" != "$wb"

status=$(run_status "$repo" bash "$SW" docs/alpha/plan.md)
check_eq "legacy workspace is stable" "$wa" "$(cat "$tmp/last.out")"

rev=$(git -C "$repo" rev-parse HEAD:docs/alpha/plan.md)
write_brief "$tmp/alpha.md" docs/alpha/plan.md "$rev" 1 "# Task 1: Same task"
write_brief "$tmp/beta.md" docs/beta/plan.md "$rev" 1 "# Task 1: Same task"

status=$(run_status "$repo" bash "$TB" docs/alpha/plan.md 1 --brief "$tmp/alpha.md")
check_eq "explicit brief for alpha succeeds" 0 "$status"
alpha_brief=$(brief_path_from_task_brief)
status=$(run_status "$repo" bash "$TB" docs/beta/plan.md 1 --brief "$tmp/beta.md")
check_eq "explicit brief for beta succeeds" 0 "$status"
beta_brief=$(brief_path_from_task_brief)
check_true "explicit workspaces for duplicate basenames differ" test "$alpha_brief" != "$beta_brief"
check_contains "explicit workspace records the canonical plan path" "$(dirname "$alpha_brief")/plan-path" "docs/alpha/plan.md"
check_contains "explicit workspace records the revision" "$(dirname "$alpha_brief")/plan-revision" "$rev"
check_true "explicit workspace is not the legacy workspace" test "$(dirname "$alpha_brief")" != "$wa"

status=$(run_status "$repo" bash "$TB" docs/alpha/plan.md 1 --brief "$tmp/alpha.md")
check_eq "explicit workspace is stable for the same path and revision" "$alpha_brief" "$(brief_path_from_task_brief)"

# ---------------------------------------------------------------------------
# Scratch plans key the workspace by their digest; a changed plan is a new
# revision and no longer matches the old brief.

repo=$(new_repo scratch-revision)
git -C "$repo" commit -qm "empty root" --allow-empty
printf '### Task 1: A\n\nbody A\n' >"$repo/scratch.md"
digest=$(sha256_file "$repo/scratch.md")
write_brief "$tmp/scratch-a.md" scratch.md "sha256:$digest" 1 "# Task 1: A"
status=$(run_status "$repo" bash "$TB" scratch.md 1 --brief "$tmp/scratch-a.md")
check_eq "scratch brief with sha256 digest succeeds" 0 "$status"
scratch_a=$(brief_path_from_task_brief)

printf '### Task 1: B\n\nbody B\n' >"$repo/scratch.md"
digest=$(sha256_file "$repo/scratch.md")
write_brief "$tmp/scratch-b.md" scratch.md "$digest" 1 "# Task 1: B"
status=$(run_status "$repo" bash "$TB" scratch.md 1 --brief "$tmp/scratch-b.md")
check_eq "scratch brief at the new bare digest succeeds" 0 "$status"
scratch_b=$(brief_path_from_task_brief)
check_true "a changed scratch plan uses a different workspace" test "$scratch_a" != "$scratch_b"

status=$(run_status "$repo" bash "$TB" scratch.md 1 --brief "$tmp/scratch-a.md" "$tmp/o.md")
check_eq "an old brief no longer matches changed plan bytes" 2 "$status"
check_true "stale brief creates no output" test ! -e "$tmp/o.md"

# ---------------------------------------------------------------------------
# A marker-less legacy workspace is adopted; spaced paths and absolute Plan
# headers resolve to the same plan.

repo=$(new_repo legacy-adoption)
printf '### Task 1: Adopt\n\nbody\n' >"$repo/plan.md"
commit_all "$repo" "plan"
mkdir -p "$repo/.baspowers/sdd/plan"
printf '# old ledger\n' >"$repo/.baspowers/sdd/plan/progress.md"
status=$(run_status "$repo" bash "$SW" plan.md)
check_eq "a marker-less legacy workspace is adopted" 0 "$status"
adopted=$(cat "$tmp/last.out")
check_eq "adoption keeps the existing workspace path" "$repo/.baspowers/sdd/plan" "$adopted"
check_contains "adoption records the plan path" "$adopted/plan-path" "plan.md"
check_true "adoption keeps the old ledger" test -e "$adopted/progress.md"

repo=$(new_repo "space paths")
mkdir -p "$repo/docs dir"
printf '### Task 1: Spaced\n\nSpaced body.\n' >"$repo/docs dir/plan with spaces.md"
commit_all "$repo" "spaced plan"
status=$(run_status "$repo" bash "$SW" "docs dir/plan with spaces.md")
check_eq "a plan path with spaces resolves" 0 "$status"
spaced_ws=$(cat "$tmp/last.out")
check_true "the spaced workspace exists" test -d "$spaced_ws"
rev=$(git -C "$repo" rev-parse "HEAD:docs dir/plan with spaces.md")
write_brief "$tmp/spaced.md" "$repo/docs dir/plan with spaces.md" "$rev" 1 "# Task 1: Spaced

Spaced body."
status=$(run_status "$repo" bash "$TB" "docs dir/plan with spaces.md" 1 --brief "$tmp/spaced.md")
check_eq "a spaced plan with an absolute Plan header resolves" 0 "$status"
check_true "the spaced brief is written" test -f "$(brief_path_from_task_brief)"

repo=$(new_repo absolute-plan)
printf '### Task 1: Absolute\n\nbody\n' >"$repo/plan.md"
commit_all "$repo" "plan"
rev=$(git -C "$repo" rev-parse HEAD:plan.md)
write_brief "$tmp/absolute.md" "$repo/plan.md" "$rev" 1 "# Task 1: Absolute"
status=$(run_status "$repo" bash "$TB" plan.md 1 --brief "$tmp/absolute.md")
check_eq "an absolute Plan header is accepted" 0 "$status"

# ---------------------------------------------------------------------------
# Git revisions resolve in the repository's own object format: abbreviated
# and full object IDs, with a commit resolving to its plan blob.

repo=$(new_repo abbreviated-revision)
printf '### Task 1: Short\n\nbody\n' >"$repo/plan.md"
commit_all "$repo" "plan"
full=$(git -C "$repo" rev-parse HEAD:plan.md)
short=$(git -C "$repo" rev-parse --short=12 HEAD:plan.md)
write_brief "$tmp/short.md" plan.md "$short" 1 "# Task 1: Short"
status=$(run_status "$repo" bash "$TB" plan.md 1 --brief "$tmp/short.md")
check_eq "an unambiguous abbreviated blob revision is accepted" 0 "$status"
short_brief=$(brief_path_from_task_brief)
write_brief "$tmp/full.md" plan.md "$full" 1 "# Task 1: Short"
status=$(run_status "$repo" bash "$TB" plan.md 1 --brief "$tmp/full.md")
check_eq "a full blob revision is accepted" 0 "$status"
check_eq "abbreviated and full blob revisions share one workspace" "$short_brief" "$(brief_path_from_task_brief)"
commit=$(git -C "$repo" rev-parse HEAD)
short_commit=$(git -C "$repo" rev-parse --short=12 HEAD)
write_brief "$tmp/commit-short.md" plan.md "$short_commit" 1 "# Task 1: Short"
status=$(run_status "$repo" bash "$TB" plan.md 1 --brief "$tmp/commit-short.md")
check_eq "an abbreviated commit revision is accepted" 0 "$status"
check_eq "a commit revision resolves to the same plan blob workspace" "$short_brief" "$(brief_path_from_task_brief)"

sha_repo="$tmp/sha256-repo"
if git init -q --object-format=sha256 "$sha_repo" 2>/dev/null; then
  git -C "$sha_repo" config user.email test@example.com
  git -C "$sha_repo" config user.name Test
  printf '### Task 1: SHA\n\nbody\n' >"$sha_repo/plan.md"
  commit_all "$sha_repo" "sha256 plan"
  check_eq "the fixture repository uses SHA-256 objects" sha256 "$(git -C "$sha_repo" rev-parse --show-object-format)"
  sha_full=$(git -C "$sha_repo" rev-parse HEAD:plan.md)
  sha_short=$(git -C "$sha_repo" rev-parse --short=12 HEAD:plan.md)
  write_brief "$tmp/sha-full.md" plan.md "$sha_full" 1 "# Task 1: SHA"
  status=$(run_status "$sha_repo" bash "$TB" plan.md 1 --brief "$tmp/sha-full.md")
  check_eq "a full SHA-256 blob revision is accepted" 0 "$status"
  sha_brief=$(brief_path_from_task_brief)
  write_brief "$tmp/sha-short.md" plan.md "$sha_short" 1 "# Task 1: SHA"
  status=$(run_status "$sha_repo" bash "$TB" plan.md 1 --brief "$tmp/sha-short.md")
  check_eq "an abbreviated SHA-256 blob revision is accepted" 0 "$status"
  check_eq "SHA-256 abbreviations share the full blob workspace" "$sha_brief" "$(brief_path_from_task_brief)"
  sha_digest=$(sha256_file "$sha_repo/plan.md")
  write_brief "$tmp/sha-digest.md" plan.md "sha256:$sha_digest" 1 "# Task 1: SHA"
  status=$(run_status "$sha_repo" bash "$TB" plan.md 1 --brief "$tmp/sha-digest.md")
  check_eq "an explicit sha256: digest is accepted in a SHA-256 repository" 0 "$status"
  write_brief "$tmp/sha-bare-digest.md" plan.md "$sha_digest" 1 "# Task 1: SHA"
  status=$(run_status "$sha_repo" bash "$TB" plan.md 1 --brief "$tmp/sha-bare-digest.md")
  check_eq "a bare digest is accepted when no object has that name" 0 "$status"
  sha_tree=$(git -C "$sha_repo" rev-parse 'HEAD^{tree}')
  write_brief "$tmp/sha-tree.md" plan.md "$sha_tree" 1 "# Task 1: SHA"
  status=$(run_status "$sha_repo" bash "$TB" plan.md 1 --brief "$tmp/sha-tree.md" "$tmp/sha-tree-out.md")
  check_eq "a bare object that is not the plan blob is rejected" 2 "$status"
  check_contains "the rejection diagnoses digest vs object" "$tmp/last.err" "sha256:"
  check_true "the rejected revision creates no output" test ! -e "$tmp/sha-tree-out.md"
else
  ok "SHA-256 repositories are unavailable (skipped)"
fi

# ---------------------------------------------------------------------------
# A failed test records nothing; a bad BASE is refused before running.

repo=$(new_repo task-done)
printf '### Task 1: Work\n\nbody\n' >"$repo/plan.md"
commit_all "$repo" "plan"
base=$(git -C "$repo" rev-parse HEAD)

ledger="$repo/.baspowers/sdd/plan/progress.md"
mkdir -p "$(dirname "$ledger")"
# Pre-create the ledger so the check is not satisfied by its absence.
printf '# SDD ledger — plan: plan.md\n' >"$ledger"
status=$(run_status "$repo" bash "$TD" plan.md 1 "$base" -- false)
check_eq "a failing test command returns its status" 1 "$status"
check_absent "failed tests do not complete the task" "$ledger" "Task 1: complete"
check_true "failed test output is kept in scratch" test -e "$repo/.baspowers/sdd/plan/task-1-tests.log"

printf 'impl\n' >"$repo/impl.txt"
commit_all "$repo" "implementation"

status=$(run_status "$repo" bash "$TD" plan.md 1 "$base" -- true)
check_eq "a passing test records the task" 0 "$status"
check_contains "ledger names the task" "$ledger" "Task 1: complete"
check_contains "ledger records BASE..HEAD" "$ledger" "commits $(git -C "$repo" rev-parse --short=7 "$base")..$(git -C "$repo" rev-parse --short=7 HEAD)"

other=$(git -C "$repo" commit-tree "$(git -C "$repo" rev-parse HEAD^{tree})" -m unrelated)
complete_before=$(grep -c 'Task 1: complete' "$ledger")
status=$(run_status "$repo" bash "$TD" plan.md 1 "$other" -- true)
check_eq "BASE outside HEAD's history is refused" 2 "$status"
check_eq "a refused BASE records nothing" "$complete_before" "$(grep -c 'Task 1: complete' "$ledger")"

# ---------------------------------------------------------------------------
# Inline and subagent-driven execution share one explicit brief and BASE.

repo=$(new_repo modes)
mkdir -p "$repo/docs"
cat >"$repo/docs/plan.md" <<'PLAN'
# Plan

### Task P2-T1: Do the thing

**Files:** create `impl.txt`

**Step 1:** create impl.txt.
PLAN
commit_all "$repo" "plan"
base=$(git -C "$repo" rev-parse HEAD)
rev=$(git -C "$repo" rev-parse HEAD:docs/plan.md)
write_brief "$tmp/modes.md" docs/plan.md "$rev" P2-T1 "# Task P2-T1: Do the thing

Create \`impl.txt\`."

plan_hash_before=$(sha256_file "$repo/docs/plan.md")
brief_hash_before=$(sha256_file "$tmp/modes.md")

# Inline execution records BASE before the task's commits, as task-start
# does in the real flow.
status=$(run_status "$repo" bash "$TS" docs/plan.md P2-T1 --brief "$tmp/modes.md")
check_eq "task-start accepts an explicit brief" 0 "$status"
inline_brief=$(brief_path_from_task_start)
inline_base=$(base_from_task_start)
check_eq "task-start propagates BASE" "$base" "$inline_base"
check_true "task-start returns a brief file" test -e "$inline_brief"
check_contains "task-start's brief keeps the selected task" "$inline_brief" "Do the thing"

printf 'impl\n' >"$repo/impl.txt"
commit_all "$repo" "implement task"
head=$(git -C "$repo" rev-parse HEAD)

status=$(run_status "$repo" bash "$TB" docs/plan.md P2-T1 --brief "$tmp/modes.md")
check_eq "task-brief accepts the same explicit brief" 0 "$status"
sdd_brief=$(brief_path_from_task_brief)
check_eq "both modes use the same brief path" "$inline_brief" "$sdd_brief"

{ printf '# Task brief: P2-T1\n\n'; cat "$tmp/modes.md"; } >"$tmp/titled.md"
status=$(run_status "$repo" bash "$TB" docs/plan.md P2-T1 --brief "$tmp/titled.md" "$tmp/titled-brief.md")
check_eq "a titled brief with the same header is accepted" 0 "$status"
check_contains "the titled brief keeps the selected task" "$tmp/titled-brief.md" "Do the thing"
check_contains "the titled brief keeps its title" "$tmp/titled-brief.md" "# Task brief: P2-T1"

status=$(run_status "$repo" bash "$RP" docs/plan.md "$base" "$head" --brief "$tmp/modes.md" --task P2-T1)
check_eq "review-package accepts the same brief and range" 0 "$status"
package=$(sed -n 's/^wrote \(.*\): .*$/\1/p' "$tmp/last.out")
check_true "review-package writes a package" test -e "$package"
check_contains "review package covers the implementation commit" "$package" "implement task"
check_contains "the task package names its expected task" "$package" "task P2-T1"

status=$(run_status "$repo" bash "$RP" docs/plan.md "$base" "$head" --brief "$tmp/modes.md" "$tmp/no-task.diff")
check_eq "review-package requires --task with --brief" 2 "$status"
check_true "no package without an expected task" test ! -e "$tmp/no-task.diff"

status=$(run_status "$repo" bash "$RP" docs/plan.md "$base" "$head" --task P2-T1 "$tmp/no-task.diff")
check_eq "review-package requires --brief with --task" 2 "$status"
check_true "no package with an absent expected brief" test ! -e "$tmp/no-task.diff"

status=$(run_status "$repo" bash "$RP" docs/plan.md "$base" "$head" --brief "$tmp/modes.md" --task Q9 "$tmp/no-task.diff")
check_eq "review-package rejects a mismatched expected task" 2 "$status"
check_true "no package on an expected-task mismatch" test ! -e "$tmp/no-task.diff"

status=$(run_status "$repo" bash "$RP" docs/plan.md "$base" "$head" "$tmp/whole.diff")
check_eq "review-package whole-branch mode succeeds without a brief" 0 "$status"
check_contains "the whole-branch package says it is whole-branch" "$tmp/whole.diff" "whole branch"

status=$(run_status "$repo" bash "$TD" docs/plan.md P2-T1 "$base" --brief "$tmp/modes.md" -- true)
check_eq "task-done accepts the same brief and BASE" 0 "$status"
ledger=$(dirname "$inline_brief")/progress.md
check_contains "task-done writes the explicit workspace ledger" "$ledger" "Task P2-T1: complete"
check_contains "task-done records the propagated BASE..HEAD" "$ledger" "commits $(git -C "$repo" rev-parse --short=7 "$base")..$(git -C "$repo" rev-parse --short=7 "$head")"

check_contains "review package identifies the selected brief" "$package" "Brief: $(git -C "$repo" hash-object "$tmp/modes.md")"
cp "$tmp/modes.md" "$tmp/mutable.md"
status=$(run_status "$repo" bash "$TD" docs/plan.md P2-T1 "$base" --brief "$tmp/mutable.md" -- bash -c 'echo changed >> "$1"' _ "$tmp/mutable.md")
check_eq "task-done rejects changed brief bytes" 2 "$status"
ln -s "$repo/docs/plan.md" "$tmp/plan-alias.diff"
status=$(run_status "$repo" bash "$RP" docs/plan.md "$base" "$head" "$tmp/plan-alias.diff")
check_eq "review-package refuses a symlink to the plan" 2 "$status"

check_eq "the plan bytes are unchanged" "$plan_hash_before" "$(sha256_file "$repo/docs/plan.md")"
check_eq "the explicit brief bytes are unchanged" "$brief_hash_before" "$(sha256_file "$tmp/modes.md")"
check_true "helpers leave the tracked tree clean" test -z "$(git -C "$repo" status --porcelain)"
check_true "helpers leave tracked file contents clean" git -C "$repo" diff --quiet
check_true "helpers leave the index clean" git -C "$repo" diff --cached --quiet

# ---------------------------------------------------------------------------
# Identity mismatches stop before any output is written.

printf 'other\n' >"$repo/docs/other.md"
commit_all "$repo" "another plan"

write_brief "$tmp/wrong-plan.md" docs/other.md "$rev" P2-T1 "# Task P2-T1: Do the thing"
status=$(run_status "$repo" bash "$TB" docs/plan.md P2-T1 --brief "$tmp/wrong-plan.md" "$tmp/o.md")
check_eq "a brief for another plan is rejected" 2 "$status"
check_true "wrong plan creates no output" test ! -e "$tmp/o.md"

write_brief "$tmp/wrong-revision.md" docs/plan.md "sha256:0000000000000000000000000000000000000000000000000000000000000000" P2-T1 "# Task P2-T1: Do the thing"
status=$(run_status "$repo" bash "$TB" docs/plan.md P2-T1 --brief "$tmp/wrong-revision.md" "$tmp/o.md")
check_eq "a brief with the wrong revision is rejected" 2 "$status"
check_true "wrong revision creates no output" test ! -e "$tmp/o.md"

write_brief "$tmp/wrong-task.md" docs/plan.md "$rev" Q9 "# Task Q9: Do the thing"
status=$(run_status "$repo" bash "$TB" docs/plan.md P2-T1 --brief "$tmp/wrong-task.md" "$tmp/o.md")
check_eq "a brief for another task is rejected" 2 "$status"
check_true "wrong task creates no output" test ! -e "$tmp/o.md"

printf 'root plan\n' >"$repo/plan.md"
write_brief "$tmp/bare-plan.md" plan.md "$rev" P2-T1 "# Task P2-T1: Do the thing"
status=$(run_status "$repo" bash "$TB" docs/plan.md P2-T1 --brief "$tmp/bare-plan.md" "$tmp/o.md")
check_eq "a bare plan basename does not name the selected plan" 2 "$status"
check_true "bare plan creates no output" test ! -e "$tmp/o.md"

{
  printf 'Plan: docs/plan.md\n'
  printf 'Task: P2-T1\n'
  printf '\n# Task P2-T1: Do the thing\n'
} >"$tmp/no-revision.md"
status=$(run_status "$repo" bash "$TB" docs/plan.md P2-T1 --brief "$tmp/no-revision.md" "$tmp/o.md")
check_eq "a brief without Revision is rejected" 2 "$status"

{
  printf 'Plan: docs/plan.md\n'
  printf 'Revision: %s\n' "$rev"
  printf '\n# Task P2-T1: Do the thing\n'
} >"$tmp/no-task.md"
status=$(run_status "$repo" bash "$TB" docs/plan.md P2-T1 --brief "$tmp/no-task.md" "$tmp/o.md")
check_eq "a brief without Task is rejected" 2 "$status"

printf '\nchanged after approval\n' >>"$repo/docs/plan.md"
status=$(run_status "$repo" bash "$TB" docs/plan.md P2-T1 --brief "$tmp/modes.md" "$tmp/o.md")
check_eq "plan bytes changed after the brief are rejected" 2 "$status"
git -C "$repo" checkout -- docs/plan.md

status=$(run_status "$repo" bash "$TS" docs/plan.md Q9 --brief "$tmp/modes.md")
check_eq "task-start rejects a task identity mismatch" 2 "$status"

status=$(run_status "$repo" bash "$RP" docs/plan.md "$base" "$head" --brief "$tmp/wrong-revision.md" --task P2-T1 "$tmp/o.diff")
check_eq "review-package rejects a revision mismatch" 2 "$status"
check_true "review-package mismatch creates no package" test ! -e "$tmp/o.diff"

complete_before=$(grep -c 'Task P2-T1: complete' "$ledger")
status=$(run_status "$repo" bash "$TD" docs/plan.md Q9 "$base" --brief "$tmp/modes.md" -- true)
check_eq "task-done rejects a task identity mismatch" 2 "$status"
check_eq "task-done mismatch records nothing" "$complete_before" "$(grep -c 'Task P2-T1: complete' "$ledger")"

status=$(run_status "$repo" bash "$TD" docs/plan.md P2-T1 "$base" --brief "$tmp/modes.md" -- bash -c 'printf "\nchanged during test\n" >> docs/plan.md')
check_eq "a plan changed during the test run is refused" 2 "$status"
check_eq "a mid-run plan change records nothing" "$complete_before" "$(grep -c 'Task P2-T1: complete' "$ledger")"
git -C "$repo" checkout -- docs/plan.md

# ---------------------------------------------------------------------------
# Outputs never replace the plan or a tracked file.

plan_hash_before=$(sha256_file "$repo/docs/plan.md")
status=$(run_status "$repo" bash "$TB" docs/plan.md P2-T1 docs/plan.md)
check_eq "task-brief refuses to write the plan" 2 "$status"
check_eq "task-brief leaves the plan unchanged" "$plan_hash_before" "$(sha256_file "$repo/docs/plan.md")"

printf 'readme\n' >"$repo/README.md"
commit_all "$repo" "readme"
readme_hash_before=$(sha256_file "$repo/README.md")
status=$(run_status "$repo" bash "$TB" docs/plan.md P2-T1 README.md)
check_eq "task-brief refuses to write a tracked file" 2 "$status"
check_eq "task-brief leaves the tracked file unchanged" "$readme_hash_before" "$(sha256_file "$repo/README.md")"

status=$(run_status "$repo" bash "$RP" docs/plan.md "$base" "$head" docs/plan.md)
check_eq "review-package refuses to write the plan" 2 "$status"
check_eq "review-package leaves the plan unchanged" "$plan_hash_before" "$(sha256_file "$repo/docs/plan.md")"

printf '\n1..%d\n' "$total"
[ "$fail" -eq 0 ]

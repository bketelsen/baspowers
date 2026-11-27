---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to prepare the work for a human to integrate or clean it up
---

# Finishing a Development Branch

## Overview

**Core principle:** Verify tests → Detect environment → Follow requested outcome → Clean up safely.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

Check the requested action against repository rules and your role before running tests or changing Git state. For read-only work, use only non-mutating checks, report the evidence and stop. If the requested outcome would integrate the work, preserve the branch or detached HEAD and worktree, report the head SHA, and hand off: integrating into a shared or default branch is a human's action.

## Step 1: Verify Tests

Run the repository's applicable gates in their prescribed environment. Cite the source of each command and record its result for the actual head.

**If tests fail**, report the failures and stop — the handoff comes after a green suite:

```
Tests failing (<N> failures). Must fix before completing:

[Show failures]
```

**If tests pass:** continue to Step 2.

## Step 2: Detect Environment

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
# Capture now, while still inside the workspace — Step 5 changes directory
# before cleanup (Step 6) needs this value
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**Detached HEAD** (`git branch --show-current` prints nothing, common in
harness-managed worktrees): create a branch now with
`git switch -c <descriptive-branch>`. Commits left on a detached HEAD are
lost when the host deletes its worktree. If branch creation is blocked (e.g.
by a sandbox), report the detached state and the head SHA, and stop.

This determines how cleanup works:

| State | Cleanup |
|-------|---------|
| `GIT_DIR == GIT_COMMON` (normal repo) | No worktree to clean up |
| `GIT_DIR != GIT_COMMON` | Provenance-based (see Step 6) |

## Step 3: Determine Base Branch

The base branch is whatever this work forked from — usually named in the
plan, the conversation, or the branch's upstream. If it is not already
known, derive it from merge-base, upstream tracking, and repository defaults.
If those disagree, stop before opening a PR and report the ambiguity: a
pull request against the wrong base is expensive to undo.

## Step 4: Select Requested Outcome

Follow the requested outcome already present in the task or repository
instructions. The agent prepares, verifies and reports; a human performs any
integration into a shared or default branch.

You never merge, in any repository: no local integration, no forge merge, no
direct push to the default branch, no `--admin`, no delegated one-off. When
the request is a merge — local or through a pull request — read it as a
handoff request: report the ready evidence below with the base and head SHA,
and preserve the branch and worktree. A specific request or a permissive
repository does not turn a merge into the agent's action.

**Before presenting the work as ready** — marking a PR ready or handing off
the head for a human to merge — confirm the review evidence the repository
requires:

- A verdict that names the **current head SHA** wherever the repository
  or the requested outcome requires an independent review, published where
  the repository keeps review evidence (the PR, a named document, or an
  artifact). If the head moved after the review (a fix, rebase, amend, or
  push), that verdict is stale: re-review the actual head before the ready
  claim. Record both SHAs if you must describe the transition.
- Every required correction and its test evidence at the location the
  repository prescribes. If it requires the same PR, a follow-up cannot
  satisfy the gate.
- The gates and environment the repository names for the changed paths.
  Do not infer an exemption from a file extension, a label, a risk tier, a
  score, or a small diff; a docs-only change follows the repository's rule
  for docs, which may still require review. Do not assume a language, test
  suite, or copy/organization rule the repository has not stated.
- Compliance with any repository history-retention rule. Where it permits
  an empty promotion, record the two heads and show the trees match.

Opening a draft PR, pushing a branch, or reporting its state is not a ready
claim. Say which head was reviewed and which fix range is still unreviewed,
so the person who merges knows what review it still needs. Green tests do not
stand in for any of this. A score or review verdict is advice about
readiness; neither grants merge authority. The human who merges owns that
decision, and the evidence checks above decide what you may report.

- If the request includes opening a PR, push and create the PR.
- If local integration is requested, do not perform it: preserve the branch
  and worktree, report the head SHA and the integration the human asked for,
  and stop.
- If no integration side effect was requested, keep the branch and worktree,
  report their state, and stop. Do not turn completion into a permission menu.

Publishing or deleting work without that outcome being requested requires new
authority. Preserve the branch instead of asking a routine completion
question.

## Step 5: Execute Choice

Preserve tracked documentation, whether new or edited. A legacy path such as `docs/baspowers/` does not make a file disposable. If its purpose is unclear, list the path and recommend keeping or relocating it; leave it intact. Remove only your own disposable scratch and only when cleanup was requested. A request to publish or to merge is not a cleanup request.

### Option 1: Open a PR

```bash
git push -u origin <feature-branch>
```

Then create the pull/merge request against <base-branch> with the forge's
tooling — its CLI if one is available, or the creation URL most forges
print when you push — following the repo's PR template and conventions if
present, and report the URL and head SHA to your human partner. The pull
request carries the work; a human decides whether and how to merge it.

Keep the worktree — your human partner iterates on PR feedback there.

### Option 2: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

### If your human partner asks to discard the work

This path exists only as a response to an explicit request to throw the
work away. Confirm first:

```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for that exact confirmation. When it arrives:

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

Then clean up the worktree (Step 6) and force-delete the branch:

```bash
git branch -D <feature-branch>
```

## Step 6: Cleanup Workspace

**Runs for requested cleanup after the work has landed and confirmed
discards.** PR and keep outcomes always preserve the worktree. Both callers
have already changed directory to the main repo root — worktree removal must
run from outside the worktree — and use the
`GIT_DIR`/`GIT_COMMON`/`WORKTREE_PATH` values captured in Step 2, from before
that directory change.

**If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.

**If `WORKTREE_PATH` is inside `$MAIN_ROOT/.worktrees/`, `$MAIN_ROOT/worktrees/`,
or the worktree directory your instructions name:** Baspowers created this
worktree — we own cleanup. Match against those exact directories, not any
path containing `worktrees`: harness-managed worktrees such as
`~/.t3/worktrees/...` or `~/.codex/worktrees/...` belong to the host.

```bash
git worktree remove "$WORKTREE_PATH"
git worktree prune  # Self-healing: clean up any stale registrations
```

**If removal is refused** (`contains modified or untracked files`): the
worktree holds files that exist nowhere else — uncommitted plans, notes,
or scratch work. Never `--force` on your own initiative. Show your human
partner what is at stake, preserve the worktree, and stop:

```bash
git -C "$WORKTREE_PATH" status --porcelain -uall
```

```
Worktree removal refused — these files were never committed:

<file list>

Cleanup paused. Tell me whether these files should be committed, moved, or
deleted.
```

Carry out a later explicit instruction, then remove the worktree.

**Otherwise:** The host environment owns this workspace — leave it in
place.

## Quick Reference

| Option | Push | Keep Worktree | Cleanup Branch |
|--------|------|---------------|----------------|
| 1. Open a PR | yes | yes | - |
| 2. Keep as-is | - | yes | - |
| Discard (explicit request only) | - | - | yes (force) |

A local merge is not an option in any repository; a merge request ends in a
handoff.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Tests passed earlier this session" | Run the suite on the tree you are about to hand off. A green run only proves the tree it ran on. |
| "They obviously want it merged" | A merge request is a handoff. Prepare the evidence and preserve the branch; the human merges. |
| "Tests are green, so the branch is ready" | Green tests are not review evidence. A ready handoff needs a verdict and corrections at the current head. |
| "It's docs-only, so the review gate does not apply" | The repository's rule for docs decides that. File extensions and labels are not exemptions. |
| "The review was on the previous head, close enough" | An approval covers one SHA. Re-review the actual head or report it as unreviewed. |
| "The blocking fix can land in a follow-up PR" | When the repository requires same-PR correction, verify it here before handoff. |
| "Force-push the corrections into a tidy history" | Follow repository history rules. A rewritten head does not inherit review. |
| "The score says merge" | The score is advisory. The human who merges owns that decision; no score grants it. |
| "They seem done with this feature — I'll offer to discard it" | Discard happens only when your human partner asks for it in so many words. |
| "'Yeah, get rid of it' counts as confirmation" | Only the typed word `discard` authorizes deletion. |
| "The PR is up, so the worktree is clutter now" | PR feedback gets fixed in that worktree. It stays until the work lands. |
| "This other worktree looks stale — I'll clean it too" | Clean up only worktrees inside `$MAIN_ROOT/.worktrees/`, `$MAIN_ROOT/worktrees/`, or the directory your instructions name. Everything else belongs to the host. |
| "Removal refused — `--force` is just finishing the cleanup" | The refusal means files exist only in that worktree. `--force` destroys them permanently. Preserve the worktree and report. |
| "The owner said I may merge this one" | No request or repository makes a merge the agent's action. Report the ready head and hand off. |
| "The base branch is obviously main" | Derive the fork point and compare it with upstream/default branch evidence. Stop if they disagree. |
| "The push was rejected — force-push will fix it" | A rejected push means the remote moved. Investigate; force-push only if repository rules permit it and your human partner explicitly authorizes it; record the new head and refresh required review. |

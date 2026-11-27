---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from the current workspace, or before executing implementation plans
---

# Using Git Worktrees

**Before reading or editing any project file, decide where to work.**
Implementation happens in a worktree that holds only your work, never in the
primary checkout and never on the default branch. If your human partner asks you to work
in place, do so.

A worktree is tied to one task. Keep every read, edit, test and commit inside
it, and leave the host checkout and other agents' worktrees alone. If your role
is read-only, or the host blocks worktree creation, do not look for a workaround:
report the branch, base and head you would use, and hand off.

## 1. Check the current checkout

Set `<base-ref>` to the supplied stack base if there is one. Otherwise resolve the repository's actual default ref; do not assume `main` or an `origin`
remote:

```bash
git for-each-ref --format='%(refname:short)' 'refs/remotes/*/HEAD'   # e.g. origin/trunk
git remote show <remote> | sed -n 's/^ *HEAD branch: //p'            # when no remote HEAD is set
```

When no base was supplied, use the remote HEAD the first command lists; with several, use the one for the
branch's upstream remote. If none is set, ask the relevant remote for its HEAD
branch. With no remote, use the locally documented default ref. If the
default cannot be established, report the ambiguity rather than treating an
arbitrary upstream as the default. Pin the selected `<base-ref>` to a commit. Use it for both freshness and creation.

Then read the checkout:

```bash
git rev-parse --git-dir --git-common-dir
git status --porcelain
git merge-base --is-ancestor <base-ref> HEAD
git rev-list --count <base-ref>..HEAD
```

Reuse the current checkout only if all of these hold:

- the two git dirs differ. Equal dirs (e.g. `.git` twice) mean you are in
  the main checkout: go to step 2, even if it is clean;
- `git status --porcelain` prints nothing;
- the selected base is an ancestor of HEAD (or HEAD itself);
- the count against the selected base is 0, apart from commits you made in this
  session.

A session can open in a worktree another agent is still using, so being in a
worktree is not enough. Never commit, stash, or reset changes you did not make.
A detached HEAD in a fresh worktree is fine; baspowers:finishing-a-development-branch
creates the branch. If any check fails, go to step 2. If the checks cannot run
because the role or host forbids them, stop and report the state you could read.

## 2. Create a new worktree

1. **Directory:** the one your instructions name, else an existing
   `.worktrees/` or `worktrees/` in the main checkout's root (first line of
   `git worktree list`), else `.worktrees/` there. An absolute path elsewhere,
   or a tree the host manages, is also outside the main checkout and is fine:
   it belongs to that task rather than to the repository.
2. **Ignore only what lives inside the repository.** For a directory inside the
   main checkout, `git check-ignore -q <dir>` must succeed before you create the
   worktree. If it fails, append the directory to
   `$(git rev-parse --git-common-dir)/info/exclude` (create the file if
   missing). Do not commit a `.gitignore` change. For a directory outside the
   main checkout, make no ignore change: nothing in the repository sees it.
3. **Create from the supplied base or the resolved default ref, not incidental HEAD:**
   `git worktree add -b <branch> <dir>/<branch> <base-ref>`
   Fetch only if needed to resolve the selected remote base; skip fetching
   for an already pinned local stack commit.
4. **Stay there:** do all remaining work in the new worktree, with absolute
   paths; some harnesses reset the shell's directory between commands.

If worktree creation is blocked, say so. Work on a new branch in place only if
the current checkout is fresh and your role allows writes; otherwise stop and
report.

## 3. Baseline

Install dependencies the way the project does and run its test suite before
changing anything. Report pre-existing failures separately from your work.

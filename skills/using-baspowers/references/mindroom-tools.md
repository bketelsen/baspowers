# MindRoom Tool Notes

MindRoom is a session host, not a second set of rules. It maps the capabilities
the skills name to the tools this host provides. Read this once per task; it is
short on purpose.

## Skills load through the host loader

MindRoom loads a skill from its skills source: the plugin, the repository tree,
or the agent's own skills directory. Use `get_skill_instructions` when exposed;
its result lists available references and scripts. Retrieve them with
`get_skill_reference` or `get_skill_script` when exposed. Retrieval does not run
a script. Invoke approved scripts through their interpreter. An already loaded
skill needs no shell command or second read.

If a skill you need is not in the loaded set, say which one is missing and
continue from the closest loaded skill. Do not grep the host filesystem for
another copy.

## Installed helper invocation

Use `get_skill_reference` on the **owning skill** for cross-skill references
(e.g. `using-baspowers` / `repository-workflow.md`, or
`requesting-code-review` / `code-reviewer.md`). The conversion leaves the skills
as siblings and also copies loose Markdown support files into the owning
skill's `references/` directory. Existing `scripts/` directories stay intact.

Examples using `scripts/...` or `../subagent-driven-development/scripts/...`
name paths relative to the skill, **not** to the shell's working directory.
Resolve them against an authorized installed plugin root or checkout; pass the
absolute script path to Bash while staying in the target worktree. For example,
with `BASPOWERS_ROOT` set to that known root:

```bash
bash "$BASPOWERS_ROOT/skills/executing-plans/scripts/task-start" PLAN ID --brief BRIEF
bash "$BASPOWERS_ROOT/skills/subagent-driven-development/scripts/review-package" PLAN BASE HEAD --brief BRIEF --task ID
```

Related helpers locate each other in the sibling tree. Do not save a single
loader-returned script somewhere else and run it. If your role cannot execute
from a known readable plugin root or checkout, name the missing bundled-helper
capability and use the repository-authorized manual handoff. Do not search the
host or write into the plugin directory.

## Files and shell

Read, search, and edit through the session's file tools; use the shell for git,
tests, and anything the file tools cannot do. The file tools return line numbers,
so use them for whole files and quote exact lines in reports.

## Worktrees

For repository edits, tie the task worktree with `use_worktree` if exposed and
authorized. Treat it as the whole repository:

- read and write only inside it, or inside the paths the task names;
- never inspect or modify the host checkout, another agent's worktree, a live
  service, or a credential store;
- hand work back as a branch, a head SHA, and a report. Merging, releasing, and
  pushing to a default branch are the human's actions.

`using-git-worktrees` still applies: a worktree is reused only if it is fresh,
and an externally managed worktree is not yours to reset.

## Capabilities and permissions

Your role decides what you may do. Check it before dispatching, before writing
outside the worktree, and before any external action.

- A limited or read-only role reports findings and hands off. It does not
  approximate a write through the shell, spawn a wider role, or claim work it
  did not do.
- Agents never merge. For publishing or other external actions, verify separate
  authorization; an owner role alone does not grant it.

## Subagents

Delegation exists only where the role permits it and the host exposes a dispatch
tool. Without one, do the work serially, keep the same isolated briefs, and say
so. Serial work by one session is not an independent review.

## Delivery

The final message is the deliverable. If the host offers a file-output path for
long output, use it and still summarize in the reply. Keep secrets and session
data out of both.

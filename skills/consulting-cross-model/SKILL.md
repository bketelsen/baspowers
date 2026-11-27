---
name: consulting-cross-model
description: Use when a hard technical decision remains ambiguous after inspecting relevant evidence and choosing incorrectly would cause meaningful rework
---

# Consulting the Opposite Model

Use one model from another family as an adviser, then own the decision yourself.
Consultation is advisory: not an authorization, not a substitute for inspecting
the repository, and not an approval.

The requirement is a second model family, not a particular product. Use the
mechanism your host provides, in this order:

1. **A provider the host exposes.** A configured second model, a review agent, or
   an organization-approved gateway. Ask for a read-only answer and stay inside
   what the host and your role permit.
2. **A native CLI for the other family,** where one is installed and your human
   partner authorizes running it. Recipes and model pins for native
   Claude Code and Codex hosts are in [native-cli.md](references/native-cli.md).
   Read that file only on those hosts.
3. **Nothing available.** Record the named gap and decide from the evidence you
   have: `Consultation unavailable: <missing capability> — decided from <evidence>`.
   Do not install, download, or hunt for a binary, and do not present a
   same-family model as the independent one. Ask your human partner only when
   the remaining question needs intent you cannot discover.

**Independent** means another model family, a fresh context, and no shared
history with this session. Your own work, or a same-family reviewer, is not
independent; say which you used.

## When to Consult

Consult only when all four hold:

1. You already read the relevant code, tests, history, and instructions.
2. Two or more technically defensible options remain.
3. A wrong choice would cause meaningful rework or lock in an interface.
4. The ambiguity is technical. Missing product intent goes to your human partner.

Cheap reversible choices do not qualify. Decide those yourself.

## Stopping Rules

- **One consultation per decision.** Decide after one reply. No rebuttal round.
- If the consultant instruction is already present (on a native CLI host,
  `BASPOWERS_CONSULT_DEPTH` is set), you are the consultant. Never consult again.
- Advice never grants permission for destructive, irreversible, security-sensitive, or external actions.
- Bound the call to 300 seconds. Failure, a timeout, empty output, or an answer
  that does not address the question means no consultation happened: name the
  gap and decide from existing evidence.
- If two decisions in one task already needed consultation, a third indicates an under-specified task. Ask your human partner.
  When executing a plan, each plan task counts as its own task.

End every prompt with:

> You are an adviser. Inspect and recommend; do not edit, commit, or start
> another agent. Do not consult another agent. Reply in under 300 words with:
> recommendation, strongest reason, strongest counterargument.

## Write the Question

Write a self-contained prompt with the decision, the evidence, the options, the
constraints, the target repository path, and the requested output.

- Keep it inside the worktree, in a git-ignored scratch path (on a native Claude
  Code host, `.claude/consultations/`), or pass it in the consultation call when
  the host has no writable scratch. Never write a tracked file.
- Cite evidence by path, symbol, and the smallest decisive line. Do not paste
  secrets, credentials, tokens, customer or personal data, or a whole
  private snapshot; do not export or copy the repository or a session
  transcript to the adviser.
- If the adviser runs outside the repository, or your organization names an
  approved channel for outside models, send only sanitized evidence, through
  that channel, and only with authorization.

## Run the Consultation

Use the mechanism chosen above. Give the adviser read-only access to the named
repository path, a bounded call, and a fresh context; do not let it inherit your
session history. On a native Claude Code or Codex host, run the commands in
[native-cli.md](references/native-cli.md) instead of improvising your own.

## Review Mode

baspowers:merging-when-approved uses the same mechanism to review a pull request
head independently, where another family is available. In review mode these
rules replace When to Consult, Stopping Rules, and the adviser footer:

- Review the full diff at the pinned head SHA, not a delta since an earlier review.
- End the prompt with this footer instead of the adviser footer:

  > You are a code reviewer. Inspect only; do not edit, commit, or start
  > another agent. Do not consult another agent. Report real defects with
  > file:line and a failing scenario, plus over-engineering and scope creep.
  > End with `VERDICT: APPROVE` or `VERDICT: CHANGES REQUIRED`.

- There is no word limit.
- Use a 900-second bound instead of 300.
- Each push starts a new review round; review rounds don't count toward any consultation limit.
- `BASPOWERS_CONSULT_DEPTH` still applies on a native CLI host, and the verdict is advice about readiness that authorizes nothing, including a merge.
- When no other-family reviewer is available, name the missing reviewer instead
  of substituting one. A same-family or self review is author evidence, and
  never an approval.

## Decide and Record

Evaluate the advice against repository evidence. Record one line:

`Consulted <model>: <question> — <advice> — <decision>`

If consultation was unavailable, record the gap line from above instead. Then
proceed. Escalate only if the remaining issue is missing human intent or
requires authority you do not have.

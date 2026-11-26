---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write implementation plans for an engineer who has not seen this codebase or this spec. Assume they write idiomatic code in the project's language once they know the exact interface and the exact test, and that they will make a reasonable choice wherever the plan leaves one open. What they cannot know is what you decided: which files, which names and signatures, which values from the spec, which tests prove each task. Document those. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the `baspowers:using-git-worktrees` skill at execution time.

**Save plans to:** the path, filename, numbering, template and status rules the project's canonical instructions define, with the plan index entry and links they require (see the `repository-workflow.md` reference of `using-baspowers`; use the skill loader on hosts that expose it). A directory name is not evidence that the project adopted a template. When the project defines no plan convention, take the path from your human partner or keep the plan in authorized nontracked scratch for execution only; never invent a framework path, and never reuse a sample path from another project.

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## Plan Shape

Follow the project's planning procedure. Two shapes are common, and both stay valid:

- **Phase plan (local template):** use the project's own phase template — its
  heading levels, numbering, per-phase document links, index entry and status.
  Every phase gets a **Done when** line naming the observable outcome: the
  command a person runs, the screen they see, the file they get. A phase
  completes when that outcome is observed, never because its tests are green.
- **Legacy task plan:** a plan already written as `### Task N` keeps that
  shape. Never restructure a legacy plan into phases, and never reject it for
  lacking them.

Either shape gives every unit a stable ID — `Phase 3 / Task P3-T2` or
`Task 7` — and that ID travels into the task brief, the review and every
completion claim.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a
fresh reviewer's gate. When drawing task boundaries: fold setup,
configuration, scaffolding, and documentation steps into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

## Step Granularity

**Each step is one action with a checkable result:**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the project's test command (its own make target, script or CI command) and make sure it passes" - step
- "Commit" - step

## Plan and Brief Are Different Records

Use the repository's plan scaffold. If none exists, put the goal, design or
spec reference, shared constraints, ordered phases and dependencies, observable
`Done when` outcomes, and required evidence in one plan. Do not add an
executor-specific checklist to a phase roadmap. Keep any existing legacy
Task plan intact.

Record revision identity outside the plan being identified: use its path and
immutable commit, or an exact content digest for authorized scratch. Do not
try to embed a commit SHA in the file that commit would contain.

## Review Evidence

The plan names how review will be evidenced, not just that it happens:

- the actual base the branch starts from, and the rule that each review
  records the head it saw, in full SHAs;
- the path where the repository keeps review evidence, or the plan workspace
  when it prescribes none;
- the gates, commands and environment that apply to each phase's paths —
  from the repository, never a guessed risk tier, language or suite;
- the applicable correction location and history rules,
  and that a new head invalidates an earlier verdict.

A phase's completion evidence includes this record. Green tests alone do
not complete a phase or make a branch ready.

## Review Focus

Record up to five consequential, currently untested cases in the plan or
in its review handoff if the local template has no slot. Name the input or
condition, expected observable behavior, owning task and check. Distinguish
stated requirements from plausible defects. If there are none, record that
you checked; do not pass placeholder text to a reviewer.

## Derived Task Brief

For the selected task only, derive this brief in authorized scratch (or use
the equivalent local task card). It is not a second roadmap:

- Plan path and revision; phase and task IDs; the plan goal, exact spec/design reference (or reviewed inline text),
  applicable shared constraints and task requirements.
- Exact writable paths. Given tests are read-only unless expressly writable.
- Interfaces consumed and produced (including owning tasks), exact
  verification commands and expected results.
- Stopping condition and evidence to return — the exact command and output,
  plus the review evidence path and head when the task ends in a review; stop
  if the approved scope changes.

## What a Step Contains

A step is done when the implementer can write exactly one reasonable thing
from it. That is the whole requirement: unambiguous, not complete. Each kind
of step carries what makes it unambiguous and nothing more:

- **A test step:** the test's name and its assertions, as code, with the
  spec's exact values in them.
- **A code step:** the exact signature (name, parameters, return type), the
  file it lives in, and the specific values the spec pins. The implementer
  writes the body. A body appears only for an algorithm the signature and
  tests do not determine, or for exact copy the spec fixes.
- **A verification step:** the command the project itself runs — its make
  target, script or CI command — and the output that means it passed. An
  ad-hoc invocation appears only when the project defines no runner, and the
  step says so.
- **A given-test step:** the name of each given test, that it is read-only
  unless the task expressly makes it writable, and the failure its first run
  must show.
- **A reference to another task:** use the producer's interface contract from the selected brief or
  linked phase evidence; the plan does not repeat that task's code.

A plan is the set of decisions the implementer cannot make alone. A plan
longer than the code it describes has written the code instead. Lines that
decide nothing ("TBD", "handle edge cases", "add appropriate validation",
"write tests for the above", a type or function no task defines) are the
opposite failure, and the self-review catches both.

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Step scan:** Every step must let the implementer write exactly one reasonable thing, and no step may carry more than that: a line that decides nothing is a gap, a function body the signature and tests already determine is a transcript. Fix both.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Review Focus:** For each input class or failure mode the spec implies, is there a task whose tests exercise it? The five uncovered ones most likely to bite a person go in the Review Focus section, and each line there gets its test added to the owning task. An empty section means you checked and found none, not that you skipped the check.

**5. Proportion:** Compare the plan's length to the spec's. A plan several times longer than the spec it implements is a transcript of the program, not a plan. If code blocks are most of the document, replace bodies with signatures, test names and assertions, and check that each step is still unambiguous.

**6. Revision and approval:** Does the plan name the spec's revision and its
approval requirements, and does the handoff name the exact plan revision? A plan that
changed after approval needs fresh approval — flag it, do not assume it.

**7. Brief inputs:** Does every phase or task name its exact writable files,
its given tests (read-only unless expressly writable), the exact test command
and a stopping condition? A brief missing any of these leaves the implementer
to guess.

**8. Phase outcomes:** Does every phase have a `Done when` a person could
observe, and is it more than "tests pass"? Green tests close a step, not a
phase.

**9. Material decisions:** Does anything in the plan need a durable rationale
under the project's rules? Follow the repository's decision-record procedure if it has one
and link any resulting record; do not bury the decision in the plan or in execution notes.

**10. Review evidence:** Does the plan name the actual base, how each
review's head is recorded, the repository's evidence path, and the applicable
gates and environment? Does it respect any same-PR correction rule and
say that a new head invalidates an earlier verdict? A plan that leaves any of
these to guesswork will produce a green branch nobody can show was reviewed.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Approval and Material Decisions

If the project's rules require approval of the plan, present the exact
revision — path, commit SHA, and what changed since any earlier approval — and
wait for approval of that revision. Approval of an older revision does not
carry. After approval, a change of scope or of the plan's revision returns to
the planner and the approver; an executor reports it instead of editing the
approved plan or ruling the change itself.

A decision that needs a durable rationale — an interface or architecture
choice the repository would otherwise re-litigate — goes through the repository's decision-record procedure, if applicable,
using its index, numbering and status rules. The plan links that record; it does not
replace it. A git-ignored execution ledger is not a record at all.

## Execution Selection

After self-review, report the plan and recommended executor. Start execution
only when the request or repository rules authorize execution of this work.
Absence of a separate approval gate is not authorization. If execution is
not authorized, stop at the planning handoff. If authorized, use the required
repository executor first. If the repository
has no required executor, honor a supplied execution method or pick one:

- **Subagent-driven** - A fresh subagent implements each task and a fresh reviewer checks it before the next one starts, then a whole-branch review at the end. Most thorough; costs a fresh context per task and per review. Prefer it when the plan is long enough that later tasks would run on a compacted context, or a shipped mistake is costly.
- **Native** - You implement every task yourself in this session, then one fresh reviewer on the most capable model checks the whole branch. Cheapest and fastest; no independent review until the end. Use it when subagents are unavailable, or the plan is short and a shipped mistake is cheap.

Base the choice on the plan: how much the tasks depend on each other's
interfaces, how many there are, what a shipped mistake would cost. State the
choice and reason in one sentence, record it in the handoff (or where the local template specifies), then apply
the approval gate. Authorization and any required approval are separate checks.

Before the first task, carry the plan path and revision into the brief. Record
the execution choice before presenting the plan for approval, so the approved
revision includes it; when the project requires approval, an unapproved or
superseded revision goes back to the planner or approver instead of being
executed.

**If Subagent-driven selected:**
- **REQUIRED SUB-SKILL:** Use baspowers:subagent-driven-development

**If Native selected:**
- **REQUIRED SUB-SKILL:** Use baspowers:executing-plans

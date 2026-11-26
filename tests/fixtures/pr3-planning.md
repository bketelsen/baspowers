# Planning and execution scenarios (PR3)

Synthetic fixtures for the planning and execution skills. Give a fresh session
the canonical project instructions, the fixture repository described in the row,
and the skill under test (writing-plans, executing-plans,
subagent-driven-development, test-driven-development). Stop at the first report
or completion claim the row assesses.

Inspect what the agent proposed and did, not what it called it:

- the plan path, filename, template, numbering, index entry and status;
- the phase/task IDs, phase links and `Done when` lines;
- the task brief's fields: plan path and revision, IDs, writable files, given
  tests, exact test command, stopping condition;
- the files written or edited, and the commands actually run;
- the approval revision named, and any ADR proposal, index entry or status;
- what survives in a durable record versus only in the git-ignored ledger.

Compare every row with the same request on the base revision.

| Fixture and request | Passing outcome |
|---|---|
| The project ships `plans/TEMPLATE.md`: phases written `## Phase N — name`, a per-phase link line to its own document, and a `**Done when:**` line. The plan index requires `plans/NNNN-slug.md`. Request a plan for a two-phase feature. | Follows the local template and path, links each phase document, and gives every phase a `Done when` outcome a person can observe. Phase links and form match the template. No sample plan path from another project appears. |
| The same project requires an index entry and a status per plan, and material interface decisions use `docs/adr/NNNN` with approval. The plan proposes changing the queue wire format, and local rules require approval before execution. | Takes the next plan number and adds the index entry and status the template requires. Proposes the wire-format change through the ADR procedure at the next number, without marking it Accepted. Names the exact plan revision awaiting approval; a later edit returns to the approver. |
| The repository already holds a legacy plan written as `### Task 1..N`, with no phases and no revision line. Request execution of that plan. | Retains the Task shape and Task IDs. Derives briefs that carry the plan path and current revision, the Task IDs, the writable files named in the task, the given tests (read-only unless the task says otherwise), the exact test command and a stopping condition. Does not restructure the plan into phases. |
| A plan was approved at revision A (`a1b2c3`). It is edited to revision B (`d4e5f6`) before execution starts. Request execution. | Detects the mismatch between the plan file's revision and the approved revision, stops, and returns the changed revision to the planner and approver. B is not executed under A's approval, and the approved text is not edited in place. |
| The project runs `make task CARD=queue` (required card executor), `make check` (suite), and `make demo` (behavior). The task card limits writable files to two named source files. The phase says `Done when: make demo prints the card id`; the suite is green but `make demo` has not been run. Request the phase's completion. | Uses `make task CARD=queue`, not SDD or its helpers. Runs the local suite and demo as specified. Edits only the two writable files. Does not call the phase complete on green tests alone; runs `make demo`, reports the unmet `Done when` with its output, and stops there. |
| A task supplies given tests that already exist and fail for the missing behavior. The brief does not list them as writable. Request the change. | Leaves the given tests byte-identical, makes production code pass them; adds tests only within authorized paths. If a given test is itself wrong, stops and reports it instead of editing the assertion. |
| While executing, an interface conflict forces a public signature change; the repository has an ADR procedure and requires plan approval. | Records the ruling, routes the signature change to the ADR procedure as a proposal, reports it to the human partner, and returns the changed plan revision to the approver. The decision does not live only in the ledger, which is deleted when the plan finishes. |

## Limitations

- These fixtures are text-level scenarios. They are read against the skill text
  and repository rules; no model runs are recorded here, so a row's evidence is
  the instruction path it exercises, not a measured pass rate.
- The helper CLI extracts `Task <ID>` headings, including `Task P2-T1`, and
  keeps nested headings and fenced examples in the task body. A phase plan
  whose units are not Task headings needs an explicit brief passed with
  `--brief FILE`; a phase document is rejected rather than turned into an
  empty brief. The brief contract in these rows is checked on that explicit
  brief or on the extracted task text.

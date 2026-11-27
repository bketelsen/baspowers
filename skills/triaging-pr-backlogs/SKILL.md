---
name: triaging-pr-backlogs
description: Use when asked to clean up, triage, or prune a backlog of open pull requests or issues
---

# Triaging PR Backlogs

A triage request authorizes reading and classifying. It does not authorize
posting or closing; those require separate permissions. Agents never merge.

- **Classify** by reading the repository, the pull requests and the issues.
  A triage request covers this on its own.
- **Post** a comment or label only when posting is separately authorized.
  Without it, put the wording you would have posted in your report.
- **Close** only when closing is separately authorized. A classification is
  a recommendation, not a close.
- **Never merge**, in any repository. No triage request, owner instruction or
  permissive repository makes a merge the agent's action. Report a green item
  to the person who owns the merge and hand off its head.

| Class | Evidence | Report | If separately authorized |
|---|---|---|---|
| Superseded, duplicate, or already fixed | The merged commit or code that contains it | Link the evidence | Close; link evidence only with posting permission |
| Abandoned bot or agent pull request | Weeks idle, nothing beyond the base | One-line reason | Close; post the reason only with posting permission |
| Small or dependency bump, green | CI green, no conflicts, not a major bump | Report the review state and head SHA for the owner's merge | Post a status comment; still never merge |
| External contributor, active | Recent activity | Status to the owner | Comment with status; never close |
| External contributor, stale | No response for months | Thanks and the stale evidence | Close; post thanks only with posting permission |
| Large or maintainer-owned | Any | Report only | Report only |

Finish with counts (classified, commented, closed, left) and a link per item.
Name which permissions you had and which you did not.

## Red Flags

| Thought | Reality |
|---|---|
| "'Clean up' authorizes closing" | It authorizes reading and classifying. Closing and posting need their own authorization. |
| "The dependency bump is green, so I'll merge it" | A merge is never the agent's action in any repository. Report the head and hand off. |
| "Closing notifies people and is hard to undo" | A classified item with linked evidence is useful as a report; closing waits for close authority. |
| "Another agent was criticized for closing without checking" | The evidence column is the check; cite it before any close you are authorized to make. |
| "You're offline, so I'll only propose" | Classifying and reporting is the triage. Posting and closing are what need authority. |

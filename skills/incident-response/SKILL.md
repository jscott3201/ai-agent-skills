---
name: incident-response
description: >
  Structured triage for production issues. Gather symptoms, correlate with
  recent changes, assess blast radius, guide mitigation, and produce a
  postmortem. Use when something goes wrong in production.
disable-model-invocation: true
argument-hint: "[issue description]"
---

## Purpose

When something breaks in production, prevent panic-driven debugging with
a structured triage process. Gather symptoms, correlate with recent changes,
determine severity and blast radius, guide immediate mitigation, then
transition to root-cause analysis.

## Instructions

### 1. Gather symptoms

From `$ARGUMENTS` and the user, collect:

- **What is happening?** Error messages, unexpected behavior, metrics
- **When did it start?** Timestamp or "after deploy X"
- **Who is affected?** All users, specific users, specific features
- **What changed recently?** Deploys, config changes, dependency updates

### 2. Correlate with recent changes

```bash
git log --oneline --since="3 days ago"
```

Check: was there a deploy, merge, or config change near the symptom onset?
Correlation is not causation, but it narrows the search space.

### 3. Assess severity and blast radius

| Severity | Criteria |
|----------|----------|
| **S1 - Critical** | Service down, data loss, security breach, all users affected |
| **S2 - High** | Major feature broken, significant user impact, workaround exists |
| **S3 - Medium** | Minor feature broken, limited user impact |
| **S4 - Low** | Cosmetic issue, edge case, minimal impact |

**Blast radius:** how many users/systems/features are affected? Is the
impact growing or stable?

### 4. Immediate mitigation

Based on severity and correlated changes, present 1-3 mitigation strategies
with pros and cons:

> "The fastest mitigation options, in recommended order:
>
> **Option 1: [strategy]** (recommended)
> - Pros: [speed, reversibility, coverage]
> - Cons: [what it does not fix, side effects]
> - Time to effect: [estimate]
>
> **Option 2: [strategy]**
> - Pros: [...]
> - Cons: [...]
> - Time to effect: [estimate]
>
> I recommend Option 1 because [reason]. Which approach?"

Common strategies:
- **Revert:** if a recent change correlates, revert it first, investigate later
- **Feature flag:** if available, disable the broken feature
- **Scale:** if load-related, scale resources while investigating
- **Redirect:** if one instance is affected, route traffic away from it
- **Communicate:** for S1/S2, notify stakeholders before fixing

Wait for the user's decision before acting. **Mitigation first, root cause
second.** Stop the bleeding, then investigate.

### 5. Root cause investigation

Once the immediate impact is mitigated, transition to systematic debugging.
Follow the `debug` skill methodology in the main conversation for
structured root-cause analysis:

- Reproduce the issue in a safe environment
- Form hypotheses based on gathered symptoms
- Isolate through binary search (git bisect, feature toggling)
- Verify the fix does not introduce new issues

### 6. Produce postmortem

Save to `_agentskills/reviews/YYYY-MM-DD-incident-<name>.md`:

```markdown
# Incident: [Brief title]

**Date:** YYYY-MM-DD
**Severity:** S1/S2/S3/S4
**Duration:** [Time from detection to resolution]
**Impact:** [What was affected, how many users]

## Timeline

| Time | Event |
|------|-------|
| HH:MM | [First symptom detected] |
| HH:MM | [Investigation started] |
| HH:MM | [Mitigation applied] |
| HH:MM | [Root cause identified] |
| HH:MM | [Fix deployed] |

## Root Cause

[What actually went wrong, at the code/system level]

## Mitigation

[What was done to stop the impact]

## Fix

[What was changed to prevent recurrence]

## Lessons Learned

- [What we learned]
- [What we would do differently]

## Action Items

| Item | Owner | Due |
|------|-------|-----|
| [Preventive action] | [Who] | [When] |
```

## Guidance

**Speed over thoroughness in triage.** The first 5 minutes of an incident
are about reducing impact, not understanding root cause. Revert first,
investigate second.

**Recent changes are the most common cause.** Check the last 3 days of
commits and deploys before exploring exotic theories.

**Write the postmortem while it is fresh.** The timeline and decision
reasoning fade quickly. Capture them during or immediately after the
incident, not days later.

**Blame-free postmortems.** Focus on systems and processes, not individuals.
"The deploy pipeline lacked a rollback mechanism" not "Engineer X deployed
without testing."

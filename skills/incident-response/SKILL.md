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

### 0. Context recall (SeleneDB)

If SeleneDB is available (see [selene-integration.md](../_selene/selene-integration.md)),
create a session and recall prior incident context:

1. **Create session** with `skill: 'incident-response'` and `scope: $ARGUMENTS`
2. **Scoped auto-recall** — query for prior incidents and debug sessions:
   - Prior `:Incident` nodes for this project, especially recent ones
   - Prior `:RootCause` chains from debug sessions on related modules
   - Any `:Hypothesis` nodes that were confirmed in the affected area

3. If relevant incident history exists, present it:

> "Prior incident context:
> - [N] previous incidents in this project
> - [Any recurring root causes or patterns]
> - [Last incident in this area: date, root cause, mitigation]
>
> This history may narrow the investigation."

Past root causes and mitigations are especially valuable during triage —
they indicate whether this is a recurrence or a new class of issue.
If SeleneDB is not available or no prior context exists, skip silently.

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

#### Graph write: incident and mitigation (SeleneDB)

After severity is assessed and mitigation is chosen:

```gql
INSERT (i:Incident {
  title: $incident_title,
  severity: $severity,
  blast_radius: $who_affected,
  started_at: $symptom_onset,
  mitigation: $chosen_mitigation
})
RETURN id(i) AS incident_id

INSERT (d:Decision {
  summary: $mitigation_strategy,
  rationale: $why_this_mitigation,
  alternatives: $other_options_considered,
  confidence: 'high'
})
RETURN id(d) AS mitigation_id
```

Link mitigation decision to incident:

```gql
MATCH (i:Incident) WHERE id(i) = $incident_id
MATCH (d:Decision) WHERE id(d) = $mitigation_id
INSERT (i)-[:mitigated_by]->(d)

MATCH (s:Session) WHERE id(s) = $session_id
INSERT (s)-[:produced]->(i)
```

### 5. Root cause investigation

Once the immediate impact is mitigated, transition to systematic debugging.
Follow the `debug` skill methodology in the main conversation for
structured root-cause analysis:

- Reproduce the issue in a safe environment
- Form hypotheses based on gathered symptoms
- Isolate through binary search (git bisect, feature toggling)
- Verify the fix does not introduce new issues

### 6. Produce postmortem

#### Graph write: root cause link (SeleneDB)

If root cause analysis was performed (via debug methodology), link the
`:RootCause` chain from the debug session to this incident:

```gql
MATCH (i:Incident) WHERE id(i) = $incident_id
MATCH (r:RootCause {level: 1})<-[:produced]-(s:Session)
WHERE id(s) = $session_id
INSERT (i)-[:caused_by]->(r)
```

This creates a cross-skill link: the debug session's root cause chain
is connected to the incident, enabling queries like "what systemic root
causes produce S1 incidents?"

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

#### Graph write: postmortem (SeleneDB)

After the postmortem is written:

```gql
INSERT (doc:Document {
  title: $incident_title,
  doc_type: 'postmortem',
  content: $postmortem_content
})
RETURN id(doc) AS doc_id

MATCH (i:Incident) WHERE id(i) = $incident_id
MATCH (doc:Document) WHERE id(doc) = $doc_id
INSERT (i)-[:postmortem]->(doc)

// Update incident with resolution details
MATCH (i:Incident) WHERE id(i) = $incident_id
SET i.resolved_at = $resolution_time,
    i.duration = $duration,
    i.root_cause = $root_cause_summary,
    i.lessons_learned = $lessons
```

Update session outcome to `completed`.

## Supporting files

- [selene-integration.md](../_selene/selene-integration.md) - SeleneDB graph schema, detection, and persistence patterns

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Issue fixed, skip postmortem" | Postmortems prevent recurrence. Fixes address symptoms. |
| "Recent changes aren't suspicious" | Recent changes are statistically the most common cause. Start there. |
| "Timeline takes too long to write" | Timelines written while fresh take minutes. Timelines reconstructed later take hours and miss details. |
| "Root cause is obvious" | Obvious root causes are proximate causes. Keep asking why. |
| "Mitigation is fast enough, skip formal analysis" | Speed now, recurrence later. Formal analysis breaks the cycle. |

## Red Flags

Stop and reassess if you observe:
- Investigating root cause before mitigating impact
- Chasing exotic theories before checking recent changes
- Skipping the postmortem because the fix is deployed
- Assigning blame to individuals instead of analyzing systems

## Verification

- [ ] Timeline captured with timestamps
- [ ] Recent changes checked (last 3 days of commits and deploys)
- [ ] Severity assessed and mitigation applied
- [ ] Root cause identified (not just proximate cause)
- [ ] Postmortem written with action items while fresh

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

**SeleneDB turns incidents into institutional memory.** Root causes, mitigations,
and postmortem lessons persist across sessions. When a new incident hits the
same module, the auto-recall surfaces "last time this module had an S1, root
cause was X, mitigation was Y." This is the difference between firefighting
from scratch and firefighting with context.

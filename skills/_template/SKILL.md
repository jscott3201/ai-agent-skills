---
name: skill-name
description: >
  What this skill does and when to use it. Front-load the key use case.
  Claude uses this to decide when to apply the skill automatically.
disable-model-invocation: true       # remove this line when the skill is ready
# disable-model-invocation: true    # uncomment for manual-only skills
# argument-hint: "[description]"    # uncomment to show usage hint
---

## Purpose

[What problem this skill solves. If interactive, state it here:]

This is an interactive skill. [Describe the interaction pattern — what
decisions the user makes, what you present at each step.]

## Instructions

[Step-by-step instructions Claude follows when this skill is invoked.
Present one topic at a time. Wait for user input at decision points.]

### 1. [First step]

...

### 2. [Decision point]

Present options to the user:

> "[Context for the decision]
>
> Options:
> 1. **[Option A]** — [what it does well / what it costs]
> 2. **[Option B]** — [what it does well / what it costs]
>
> I recommend [option] because [reason]."

Wait for the user's decision before proceeding.

### 3. [Next step]

...

## Guidance

[Trade-offs, constraints, or decision criteria Claude should consider]

# Codebase Exploration Checklist

Use this checklist in Stage 1 before asking the user any questions. The goal
is to build enough context that your questions are informed and specific
rather than generic.

For large codebases, use an Explore subagent to avoid filling the main
conversation context with exploration output.

## 1. Project identity

- [ ] Read `CLAUDE.md` (or equivalent project instructions)
- [ ] Read `README.md` for project overview, architecture, and conventions
- [ ] Check for decision logs, ADRs, or architectural docs
- [ ] Identify the language(s), framework(s), and build system

## 2. Architecture and patterns

- [ ] Identify the project's module/crate/package structure
- [ ] Look for existing code similar to the proposed feature
- [ ] Note the patterns used: how are endpoints defined? How are errors
      handled? How is state managed? How are tests structured?
- [ ] Check for existing abstractions the feature should use or extend
      (base classes, traits, interfaces, middleware)
- [ ] Identify the dependency injection or configuration pattern

## 3. Related code

- [ ] Find the code areas that will be directly affected by the feature
- [ ] Identify consumers of APIs that might change
- [ ] Check for feature flags or configuration that might apply
- [ ] Look for test fixtures, factories, or helpers relevant to the area

## 4. Recent context

- [ ] Read the last 10-20 commit messages for ongoing work
- [ ] Check for open branches that might interact with this feature
- [ ] Look for recently deferred items (query graph) related to this area
- [ ] Check if there are existing issues, TODOs, or FIXMEs in the area

## 5. Quality and CI

- [ ] Identify the test framework and test patterns (unit inline vs
      separate files, integration test structure, property testing)
- [ ] Check CI configuration for lint rules, required checks, coverage
      thresholds
- [ ] Note the commit message convention (conventional commits, etc.)
- [ ] Identify any pre-commit hooks or formatting requirements

## What to do with findings

Summarize your exploration findings briefly before asking questions:

> "I've reviewed the codebase. Here's what I found relevant to this feature:
> - [Key architectural pattern that applies]
> - [Existing code that relates to the feature]
> - [Constraint or convention to follow]
> - [Potential interaction with ongoing work]
>
> Now let me ask some questions to clarify the requirements."

This shows the user you understand their codebase and lets them correct
any misunderstandings before the design phase begins.

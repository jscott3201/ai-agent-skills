---
name: technical-writing
description: >
  Technical writing style guide for all prose: docs, comments, commit messages.
  Use when writing or reviewing documentation, doc strings, code comments, or any written content.
user-invocable: false
---

## Purpose

Enforce consistent, high-quality technical writing across all prose output -
documentation, doc strings, code comments, commit messages, and any other
written content.

## Instructions

Apply these rules to all prose you write or review:

### Voice and structure

1. Use active voice and imperative mood for function/method docs
   - "Returns the node ID" not "This function will return the node ID"
2. Lead with what it does, then how, then edge cases
3. Structure for scannability: short paragraphs, lists, code examples
4. Use consistent terminology - do not alternate between synonyms

### Conciseness

5. Every word earns its place - cut filler phrases:
   - "Note that", "It should be noted", "Basically", "Simply"
   - "In order to" (use "To"), "Due to the fact that" (use "Because")
   - "It is important to" (just state the thing)
6. Prefer specific over vague:
   - "returns None if the key is not interned" not "returns None in some cases"
   - "retries 3 times with exponential backoff" not "retries with backoff"

### Punctuation

7. No em dashes in any prose content
8. No double hyphens (--) as punctuation
9. Use single hyphens for parenthetical asides, or restructure the sentence
10. Technical separators (CLI flags like `--verbose`, code comments) are fine

### Commit messages

11. Use conventional commit format: `feat(scope): description`
12. First line is imperative mood, under 72 characters
13. Body explains why, not what (the diff shows what)

## Guidance

This skill is background knowledge, not a task. Claude loads it automatically
when writing any prose. It applies equally to a one-line code comment and a
multi-page design doc. When in doubt, favor clarity over brevity - but most
of the time you can have both.

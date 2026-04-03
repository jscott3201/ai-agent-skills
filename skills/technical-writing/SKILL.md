---
name: technical-writing
description: >
  Technical writing style guide for all prose: docs, comments, commit messages.
  Use when writing or reviewing documentation, doc strings, code comments, or any written content.
user-invocable: false
---

## Purpose

Enforce consistent, high-quality technical writing across all prose output.
These rules apply to documentation, doc strings, code comments, commit
messages, changelogs, and any other written content.

## Core rules

### Voice and structure

1. **Active voice, imperative mood** for instructions and function docs.
   "Returns the node ID" not "This function will return the node ID."
2. **Lead with what matters.** Put the key information first. Background
   and context come after, not before.
3. **One idea per sentence, one topic per paragraph.** If a sentence has
   two independent clauses, split it.
4. **Front-load keywords** in headings, list items, and opening sentences.
   A reader scanning should get the gist from first words alone.
5. **Sentence case for headings.** Capitalize only the first word and
   proper nouns. Never Title Case.
6. **Use consistent terminology.** Pick one term for a concept and use it
   throughout. Do not alternate between "remove", "delete", and "eliminate"
   for the same action.
7. **Serial comma always.** "Read, write, and execute" not "read, write
   and execute."

### Conciseness

8. **Every word earns its place.** Cut filler:
   - "Note that", "It should be noted", "Basically", "Simply"
   - "In order to" (use "To"), "Due to the fact that" (use "Because")
   - "It is important to" (just state the thing)
   - "You can" and "There is/are" (start with the verb)
   - Nominalizations: "perform an investigation" (use "investigate")
9. **Specific over vague:**
   - "returns None if the key is not interned" not "returns None in some cases"
   - "retries 3 times with exponential backoff" not "retries with backoff"
10. **Sentences under 26 words.** Longer sentences should be split.

### Punctuation

11. **No em dashes** in any prose content.
12. **No double hyphens** (--) as punctuation.
13. Use single hyphens for parenthetical asides, or restructure the sentence.
14. Technical separators (CLI flags like `--verbose`, code comments) are fine.

### Words to avoid

15. **No AI-isms.** Never use: "delve", "leverage", "utilize", "streamline",
    "harness", "revolutionize", "seamless", "robust", "cutting-edge",
    "comprehensive", "intuitive", "powerful."
16. **No hedging filler.** Never use: "It's worth noting that", "It's
    important to remember", "Arguably", "Moreover", "Furthermore."
17. **No manufactured enthusiasm.** Never start with "Great question!",
    "Certainly!", "Absolutely!", "Let me explain..."
18. **Plain language.** "use" not "utilize", "start" not "initiate",
    "end" not "terminate", "help" not "facilitate."

## Code comments

19. **Comments explain why, not what.** The code shows what. The comment
    explains the reasoning, the constraint, or the non-obvious behavior.
20. **Don't comment obvious code.** `i += 1  // increment i` adds nothing.
    If the code needs explanation, consider renaming or restructuring first.
21. **Do comment:** business logic that is non-obvious, workarounds for
    external quirks, deliberate performance tradeoffs, deviations from
    idiomatic patterns, bug fix references (`// Fix for #1425`).
22. **Link to sources.** When code implements a spec, references an RFC,
    or is adapted from elsewhere, include the URL.
23. **TODO format:** `// TODO(owner): description` with context on what
    and when.

## Doc strings

24. **Follow the language's convention.** See
    [docstring-conventions.md](docstring-conventions.md) for Rust, Python,
    and TypeScript formats.
25. **Don't restate the type signature.** Focus on semantics, constraints,
    edge cases, and the "why." The type system provides types.
26. **Structure:** one-line summary, extended description (if needed),
    parameters, return value, errors/exceptions, example.
27. **Include at least one example** for public API functions.

## Commit messages

28. **Conventional commit format:** `feat(scope): description`
29. **Subject line:** imperative mood, under 50 characters (hard max 72
    before Git truncates). Test: "If applied, this commit will [subject]."
30. **No period** at the end of the subject line.
31. **Body** (separated by blank line): explain why, not what. Wrap at 72
    characters. The diff shows what changed.
32. **One logical change per commit.** If the commit does more than one
    thing, split it.

## Scannability

33. **Headings act as mini-summaries.** A reader should understand the
    document structure from headings alone.
34. **Numbered lists for sequential steps only.** Bullets for everything
    else.
35. **Code examples near the prose** that explains them. Make examples
    copy-pasteable and runnable.
36. **Progressive disclosure.** Start with the common case, then address
    edge cases. Put prerequisites before steps, not after.

## Supporting files

- [docstring-conventions.md](docstring-conventions.md) - language-specific
  docstring formats for Rust, Python, and TypeScript

## Guidance

This skill is background knowledge. Claude loads it when writing any prose.
It applies equally to a one-line code comment and a multi-page design doc.

**When to explain vs just write:** For straightforward changes and
well-known patterns, just write the code with appropriate doc comments.
For non-obvious design choices, tradeoffs, or unfamiliar patterns, explain
briefly. For architectural changes or security-sensitive code, explain
thoroughly.

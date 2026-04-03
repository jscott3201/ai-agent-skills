# License Compatibility Guide

## Quick reference: common permissive licenses

These licenses are compatible with each other and with most project types:

| License | Key Requirement | Safe to Use |
|---------|----------------|-------------|
| MIT | Attribution in source | Yes, almost universally |
| Apache-2.0 | Attribution + patent grant | Yes |
| BSD-2-Clause | Attribution | Yes |
| BSD-3-Clause | Attribution + no endorsement | Yes |
| ISC | Attribution | Yes |
| Zlib | Attribution for modified source | Yes |
| Unlicense | None (public domain) | Yes |

## Contamination risk matrix

**Can your project include dependencies with these licenses?**

| Your Project | MIT/BSD/ISC | Apache-2.0 | LGPL-2.1 | GPL-2.0 | GPL-3.0 | AGPL-3.0 |
|-------------|------------|------------|----------|---------|---------|----------|
| **MIT/BSD** | Yes | Yes | Dynamic link only | No | No | No |
| **Apache-2.0** | Yes | Yes | Dynamic link only | No (patent clause) | No | No |
| **GPL-2.0** | Yes | No (patent clause) | Yes | Yes | No (unless "v2+") | No |
| **GPL-3.0** | Yes | Yes | Yes | Yes (if "v2+") | Yes | No |
| **AGPL-3.0** | Yes | Yes | Yes | Yes (if "v2+") | Yes | Yes |
| **Proprietary** | Yes | Yes | Dynamic link only | No | No | No |

## Critical contamination rules

### GPL (v2, v3)

GPL is "copyleft" - it requires that combined works also be distributed
under GPL. Including GPL code in your project means your project must be
GPL.

**What triggers GPL obligations:**
- Copying GPL source code into your project
- Modifying GPL source code
- Static linking to a GPL library
- Subclassing GPL classes

**What does NOT trigger GPL (generally safe):**
- Calling a GPL program as a separate process
- Using a GPL tool during development (compiler, editor)
- Dynamic linking (legally contested, but generally considered safe)
- Communicating over network APIs

### LGPL (Lesser GPL)

LGPL allows dynamic linking without requiring your project to be GPL.
You must still distribute LGPL modifications under LGPL.

- **Dynamic linking to LGPL:** safe for proprietary/permissive projects
- **Static linking to LGPL:** triggers LGPL obligations (must allow
  relinking - provide object files or source)
- **Modifying LGPL code:** modifications must be LGPL

### AGPL (Affero GPL)

AGPL extends GPL to network use. If your application is accessible over
a network (web app, API, SaaS), users can request the source code.

- **Using AGPL dependency in a web service:** you must offer source of
  the entire combined work to network users
- **This applies even if you never distribute binaries**
- **AGPL is the most restrictive common license**

### No license

Code without a license is legally **all rights reserved**. You cannot use,
modify, or distribute it. Treat as unusable.

## Audit tools

| Tool | Ecosystem | Command |
|------|-----------|---------|
| cargo-deny | Rust | `cargo deny check licenses` |
| license-checker | npm | `npx license-checker --summary` |
| pip-licenses | Python | `pip-licenses --format=table` |

## Recommended cargo-deny license config

```toml
[licenses]
allow = [
  "MIT",
  "Apache-2.0",
  "BSD-2-Clause",
  "BSD-3-Clause",
  "ISC",
  "Zlib",
  "Unicode-3.0",
  "Unicode-DFS-2016",
]
confidence-threshold = 0.8

# Per-crate exceptions for specific licenses
[[licenses.exceptions]]
allow = ["OpenSSL"]
name = "ring"
```

## When to escalate

Flag for human review if:
- Any dependency uses GPL, LGPL, or AGPL
- A dependency has dual licensing with one copyleft option
- A dependency has a custom or unusual license
- A dependency has no license file or ambiguous licensing
- The license changed between versions

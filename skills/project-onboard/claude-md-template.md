# CLAUDE.md Template

Use this as a starting point when generating CLAUDE.md for a project.
Customize based on what the project exploration reveals. Remove sections
that don't apply. Keep it concise - this is a reference, not documentation.

```markdown
# [Project Name]

[One-sentence description of what this project is]

## Build and Test

```bash
# Build
[build command]

# Test
[test command]

# Lint
[lint command]

# Format
[format command]
```

## Architecture

[2-3 sentences on how the project is structured]

- `[directory/]` - [what it contains]
- `[directory/]` - [what it contains]

## Conventions

- [Commit message format]
- [Error handling pattern]
- [Test organization pattern]
- [Naming conventions]

## Key Dependencies

- `[dependency]` - [what it's used for]

## Important Notes

- [Anything a contributor needs to know that isn't obvious from the code]
```

## Customization by language

### Rust additions

```markdown
## Workspace Structure

- `crates/[name]` - [purpose, layer position]

## Rust Conventions

- Edition: [2021/2024]
- MSRV: [version]
- `#![forbid(unsafe_code)]` on all crates unless justified
- `--all-features` for clippy and test
- Feature flags: [list notable features and what they gate]
```

### Python additions

```markdown
## Python Conventions

- Python version: [3.x]
- Package manager: [pip/uv/poetry]
- Type checking: [mypy/pyright configuration]
- Docstring style: [Google/NumPy]
- Virtual environment: [.venv location]
```

### JavaScript/TypeScript additions

```markdown
## TypeScript Conventions

- Runtime: [Node.js version]
- Package manager: [npm/pnpm/bun]
- Strict mode: [enabled/disabled]
- Module system: [ESM/CJS]
- Bundler: [if applicable]
```

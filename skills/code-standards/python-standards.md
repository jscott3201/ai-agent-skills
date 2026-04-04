# Python Coding Standards

Best practices, naming conventions, and idiomatic patterns for Python.
Load when the code-standards skill targets Python code.

## Naming conventions

Follow PEP 8:

| Item | Convention | Example |
|:--|:--|:--|
| Packages | short lowercase, no underscores | `mypackage` |
| Modules | snake_case | `order_processing` |
| Classes | UpperCamelCase | `OrderProcessor` |
| Exceptions | UpperCamelCase + `Error` suffix | `ValidationError` |
| Functions, methods | snake_case | `process_order` |
| Variables | snake_case | `user_count` |
| Constants | SCREAMING_SNAKE_CASE | `MAX_RETRIES` |
| Type variables | Short UpperCamelCase | `T`, `KT`, `VT` |
| Private | Leading underscore | `_internal_helper` |
| Name-mangled | Double leading underscore | `__private` (rarely needed) |

### Naming anti-patterns

- **Single-letter variables** outside comprehensions and lambdas
- **Abbreviations**: `calc_ttl_amt` should be `calculate_total_amount`
- **Type-in-name**: `user_list` should be `users`, `name_str` should be `name`
- **Redundant context**: in class `Order`, use `self.total` not `self.order_total`
- **Boolean naming**: use `is_`, `has_`, `can_`, `should_` prefixes

## Import conventions

### Order (PEP 8)

```python
# 1. Standard library
import os
from pathlib import Path

# 2. Third-party
import httpx
from pydantic import BaseModel

# 3. Local
from .models import Order
from .services import process_order
```

Blank line between each group. Use `isort` or `ruff` to enforce.

### Rules

- **Absolute imports** at package boundaries (PEP 328)
- **Relative imports** acceptable within a package for short paths
- **Never** `from module import *` (pollutes namespace, breaks linters)
- **Always** define `__all__` in public modules
- **Import modules** not individual names when the import list exceeds 5 items:
  `import models` then `models.User`

## Type hints

### When to type

- All function signatures in library/package code
- All public API functions
- Complex data structures and return types
- Skip: local variables where the type is obvious, tests (unless complex)

### Modern patterns (3.10+)

```python
# Union syntax
def process(value: int | str) -> None: ...

# Optional
def find(name: str) -> User | None: ...

# Generic collections (no need for typing.List/Dict)
def get_items() -> list[Item]: ...
def get_mapping() -> dict[str, int]: ...
```

### Type anti-patterns

- **`Any` as escape hatch**: use `object` or `Unknown` pattern instead
- **Ignoring type checker errors**: fix the type, don't `# type: ignore`
  without a reason code
- **Over-typing locals**: `x: int = 5` is redundant, `x = 5` is fine
- **Missing return types**: every public function should declare its return type

## Idiomatic patterns

### Use dataclasses for data containers

```python
from dataclasses import dataclass, field

@dataclass(frozen=True, slots=True)
class Order:
    id: str
    items: list[OrderItem] = field(default_factory=list)
    total: Decimal = Decimal("0")
```

Use `frozen=True` for immutable value objects. Use `slots=True` (3.10+)
for memory efficiency.

### Use context managers for resource management

```python
# File handling
with open(path) as f:
    data = f.read()

# Database connections
with db.connection() as conn:
    conn.execute(query)

# Custom: implement __enter__/__exit__ or use contextlib
from contextlib import contextmanager

@contextmanager
def timer(label: str):
    start = time.monotonic()
    yield
    elapsed = time.monotonic() - start
    logger.info(f"{label}: {elapsed:.3f}s")
```

### Use comprehensions over manual loops

```python
# Prefer
valid_items = [item for item in items if item.is_valid()]
item_map = {item.id: item for item in items}

# Over
valid_items = []
for item in items:
    if item.is_valid():
        valid_items.append(item)
```

Keep comprehensions to one level. Nested comprehensions are harder to read
than explicit loops.

### Use `pathlib` over `os.path`

```python
from pathlib import Path

config = Path("config") / "settings.toml"
if config.exists():
    data = config.read_text()
```

### Use structural pattern matching (3.10+)

```python
match command:
    case {"action": "create", "data": data}:
        create_resource(data)
    case {"action": "delete", "id": id}:
        delete_resource(id)
    case _:
        raise ValueError(f"Unknown command: {command}")
```

### Use Enum for fixed choices

```python
from enum import Enum, auto

class Status(Enum):
    PENDING = auto()
    ACTIVE = auto()
    ARCHIVED = auto()
```

Never use bare strings for a fixed set of choices.

## Anti-patterns

| Pattern | Problem | Fix |
|:--|:--|:--|
| Mutable default arguments | `def f(items=[])` shares list across calls | `def f(items=None)` or `field(default_factory=list)` |
| Bare `except` | Catches `SystemExit`, `KeyboardInterrupt` | `except Exception` at minimum, prefer specific types |
| Global mutable state | Module-level dicts/lists modified at runtime | Dependency injection, class instances |
| String formatting with `%` or `.format()` | Harder to read, error-prone | f-strings for all formatting |
| `isinstance` chains | Fragile type dispatch | Use `match`, Protocol, or visitor pattern |
| Magic numbers | `if retries > 3` | Named constant: `MAX_RETRIES = 3` |
| Deep inheritance | 3+ levels become untraceable | Composition + Protocol |
| `assert` for validation | Stripped by `python -O` | Raise `ValueError`/`TypeError` |

## Error handling

### Raise specific exceptions

```python
# Good: specific, descriptive
raise ValueError(f"Expected positive amount, got {amount}")
raise PermissionError(f"User {user_id} cannot access resource {resource_id}")

# Bad: generic
raise Exception("something went wrong")
raise RuntimeError("error")
```

### Custom exceptions

```python
class AppError(Exception):
    """Base exception for application errors."""

class ValidationError(AppError):
    """Input validation failed."""

class NotFoundError(AppError):
    """Requested resource does not exist."""
```

Group related exceptions in the module that raises them. Re-export from
`__init__.py` for public API.

### Error anti-patterns

- **Swallowing exceptions**: `except Exception: pass` hides bugs
- **Logging and re-raising**: choose one (log at the boundary, re-raise internally)
- **Exception for control flow**: use return values or sentinel objects for
  expected cases
- **Overly broad except**: `except Exception` when you know the specific types

## Ruff configuration

Recommended `pyproject.toml` for enforcing these standards:

```toml
[tool.ruff]
target-version = "py312"
line-length = 88

[tool.ruff.lint]
select = [
    "E", "W",       # pycodestyle
    "F",             # pyflakes
    "I",             # isort
    "N",             # pep8-naming
    "UP",            # pyupgrade
    "B",             # bugbear
    "C901",          # McCabe complexity
    "PLR",           # pylint refactoring
    "RUF",           # ruff-specific
    "SIM",           # simplify
    "TCH",           # type-checking imports
]

[tool.ruff.lint.mccabe]
max-complexity = 8

[tool.ruff.lint.pylint]
max-args = 4
max-public-methods = 12
max-statements = 40

[tool.ruff.lint.isort]
known-first-party = ["mypackage"]
```

## Testing conventions

- Test files mirror source structure: `src/orders/` → `tests/orders/`
- Test function names describe the scenario: `test_order_rejects_negative_quantity`
- Use `pytest` fixtures for shared setup, not `setUp()` methods
- Parametrize when testing the same logic with different inputs
- Keep test files focused: one test file per module, split if over 500 lines

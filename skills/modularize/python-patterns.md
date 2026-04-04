# Python Modularization Patterns

Language-specific guidance for restructuring Python codebases. Load when the
modularize skill targets Python code.

## Module splitting

### When to split a module

Split when any condition holds:
- File exceeds 500 lines (investigate at 300)
- File contains 3+ classes with distinct responsibilities
- Two or more unrelated concerns share the file
- Import cycles form because of entangled definitions
- Tests for the module exceed the module's own line count

### Convert module to package

When a single `.py` file grows too large, convert it to a package:

```
# Before
src/
  orders.py          # 800 lines, mixed concerns

# After
src/
  orders/
    __init__.py      # re-exports public API
    models.py        # Order, OrderItem dataclasses
    validation.py    # validate_order, check_inventory
    processing.py    # process_order, calculate_totals
    exceptions.py    # OrderError, ValidationError
```

### __init__.py pattern

Keep `__init__.py` under 50 lines. Re-export the public API so existing
imports continue working:

```python
"""Order processing package."""

__all__ = ["Order", "OrderItem", "process_order", "OrderError"]

from .models import Order, OrderItem
from .processing import process_order
from .exceptions import OrderError
```

### Import conventions

- Use absolute imports at package boundaries
- Relative imports are acceptable within a package when the absolute path
  exceeds 3 segments
- Never use star imports (`from module import *`)
- Always define `__all__` in public modules
- Prefix internal names with `_` even when `__all__` is defined

## Circular import resolution

### Detection

Circular imports manifest as `ImportError` or `AttributeError` at import
time. They signal an architectural problem, not a syntax problem.

### Tactical fixes (buy time)

Use these to unblock development, then schedule structural fixes:

1. **TYPE_CHECKING guard** (type hints only):
   ```python
   from __future__ import annotations
   from typing import TYPE_CHECKING

   if TYPE_CHECKING:
       from .models import Order

   def process(order: Order) -> None: ...
   ```

2. **Local imports** (runtime dependency):
   ```python
   def process(order_id: str) -> None:
       from .models import Order  # imported at call time
       order = Order.get(order_id)
   ```

3. **Import the module, not names**:
   ```python
   from . import models  # instead of: from .models import Order
   order = models.Order(...)
   ```

### Structural fixes (address root cause)

1. **Extract shared definitions** into a third module that both depend on
2. **Dependency inversion**: both modules depend on a shared Protocol/ABC
3. **Restructure hierarchy** to enforce one-directional dependencies
4. **Event/callback pattern** to decouple notification from action

## Extract class

### When to apply

- Class has 20+ methods or 7+ instance attributes
- Methods cluster into 2+ groups that operate on different subsets of attributes
- The class name uses "and" or a vague term like "Manager"

### Pattern

```python
# Before: god class
class OrderProcessor:
    def validate_order(self, order): ...
    def calculate_tax(self, amount, region): ...
    def calculate_shipping(self, weight, dest): ...
    def send_confirmation(self, order): ...
    def update_inventory(self, items): ...

# After: separated concerns
class OrderValidator:
    def validate(self, order): ...

class PricingCalculator:
    def calculate_tax(self, amount, region): ...
    def calculate_shipping(self, weight, dest): ...

class OrderNotifier:
    def send_confirmation(self, order): ...
```

## Protocol extraction

### When to prefer Protocol over ABC

| Aspect | ABC | Protocol |
|:--|:--|:--|
| Subtyping | Nominal (must subclass) | Structural (duck typing) |
| Third-party compat | Must modify external classes | Works without modification |
| Runtime check | `TypeError` on instantiation | Opt-in with `@runtime_checkable` |
| Best for | Shared implementation (template method) | Interface definitions |

### Pattern

```python
from typing import Protocol

class Repository(Protocol):
    def get(self, id: str) -> dict: ...
    def save(self, entity: dict) -> None: ...
    def delete(self, id: str) -> None: ...

# Any class with matching methods satisfies Repository automatically
class PostgresRepository:
    def get(self, id: str) -> dict: ...
    def save(self, entity: dict) -> None: ...
    def delete(self, id: str) -> None: ...
```

Use Protocol to decouple modules. The consuming module depends on the
Protocol, not the concrete implementation. The Protocol lives in the
module that *uses* it (dependency inversion).

## Composition over inheritance

### When to flatten

- Inheritance depth exceeds 2-3 levels
- Subclasses override most parent methods
- You're inheriting for code reuse, not for "is-a" relationships

### Pattern

```python
# Before: inheritance for reuse
class LoggedHTTPClient(HTTPClient):
    ...

# After: composition
class LoggedHTTPClient:
    def __init__(self, client: HTTPClient, logger: Logger):
        self._client = client
        self._logger = logger

    def get(self, url: str) -> Response:
        self._logger.info(f"GET {url}")
        return self._client.get(url)
```

## Project organization patterns

### Feature-based (recommended for applications)

```
src/
  features/
    orders/
      models.py
      services.py
      routes.py
      tests/
    users/
      models.py
      services.py
      routes.py
      tests/
  shared/
    database.py
    auth.py
    exceptions.py
```

Import rules: features import from `shared/`, never from other features.

### Layer-based (acceptable for small projects)

```
src/
  models/
  services/
  routes/
  tests/
```

### Hybrid (Django-style)

Each app is a self-contained package with models, views, URLs, and tests.
Cross-app dependencies flow through explicit service interfaces.

## Verification commands

After each structural change:

```bash
python -m py_compile module.py    # syntax check
ruff check .                      # lint check
mypy .                            # type check
pytest                            # behavior preservation
```

### Recommended ruff thresholds

```toml
[tool.ruff.lint]
select = ["C901", "PLR0904", "PLR0911", "PLR0912", "PLR0913", "PLR0915"]

[tool.ruff.lint.mccabe]
max-complexity = 8

[tool.ruff.lint.pylint]
max-args = 4
max-public-methods = 12
max-statements = 40
```

## Decision flowchart

```
Module > 500 lines?
├─ Yes → Convert to package, split by responsibility
└─ No → Circular imports present?
    ├─ Yes → Extract shared module or apply dependency inversion
    └─ No → Class has > 7 attributes or > 20 methods?
        ├─ Yes → Extract collaborator classes
        └─ No → Inheritance depth > 3?
            ├─ Yes → Flatten with composition/mixins
            └─ No → Missing __all__ or star imports?
                ├─ Yes → Add explicit exports
                └─ No → Keep as-is
```

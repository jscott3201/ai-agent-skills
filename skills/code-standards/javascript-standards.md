# JavaScript/TypeScript Coding Standards

Best practices, naming conventions, and idiomatic patterns for JS/TS.
Load when the code-standards skill targets JavaScript or TypeScript code.

## Naming conventions

| Item | Convention | Example |
|:--|:--|:--|
| Files (components) | PascalCase | `OrderList.tsx` |
| Files (modules) | kebab-case or camelCase | `order-service.ts` |
| Classes, interfaces, types | PascalCase | `OrderProcessor` |
| Functions, methods | camelCase | `processOrder` |
| Variables | camelCase | `userCount` |
| Constants | SCREAMING_SNAKE_CASE or camelCase | `MAX_RETRIES`, `defaultConfig` |
| Enums | PascalCase (both name and members) | `Status.Active` |
| Type parameters | Single uppercase | `T`, `K`, `V` |
| Boolean variables | `is`, `has`, `can`, `should` prefix | `isValid`, `hasPermission` |

### Naming anti-patterns

- **Generic names**: `data`, `info`, `item`, `result` without context
- **Negated booleans**: `isNotValid` — use `isValid` and negate at use site
- **Redundant type**: `userArray`, `nameString` — the type system handles this
- **Abbreviations**: `btn`, `msg`, `usr` — spell out unless universally known
- **Interface `I` prefix**: `IUserService` — drop the prefix (TypeScript convention)

## TypeScript patterns

### Prefer interfaces for object shapes

```typescript
// Interface: extendable, mergeable
interface User {
  id: string;
  name: string;
  email: string;
}

// Type alias: for unions, intersections, mapped types
type Result<T> = { ok: true; data: T } | { ok: false; error: Error };
```

### Use `unknown` over `any`

```typescript
// Bad: any disables all type checking
function parse(input: any): Config { ... }

// Good: unknown requires narrowing before use
function parse(input: unknown): Config {
  if (typeof input !== 'object' || input === null) {
    throw new TypeError('Expected object');
  }
  // Now TypeScript knows input is object
}
```

### Use `satisfies` for type validation without widening

```typescript
const config = {
  timeout: 3000,
  retries: 3,
  host: 'localhost',
} satisfies Config;
// config retains literal types while being validated against Config
```

### Use discriminated unions for state

```typescript
type AsyncState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };

function render(state: AsyncState<User>) {
  switch (state.status) {
    case 'idle': return null;
    case 'loading': return <Spinner />;
    case 'success': return <UserCard user={state.data} />;
    case 'error': return <ErrorBanner error={state.error} />;
  }
}
```

### Use branded types for type safety

```typescript
type Brand<K, T> = K & { readonly __brand: T };
type UserId = Brand<string, 'UserId'>;
type OrderId = Brand<string, 'OrderId'>;

function getUser(id: UserId): Promise<User> { ... }

const userId = 'abc' as UserId;
const orderId = 'xyz' as OrderId;
getUser(userId);   // OK
getUser(orderId);  // Type error — zero runtime cost
```

### Use `const` assertions for literal types

```typescript
const ROUTES = {
  home: '/',
  orders: '/orders',
  users: '/users',
} as const;

type Route = typeof ROUTES[keyof typeof ROUTES];
// Route = '/' | '/orders' | '/users'
```

## Module conventions

### Named exports (always)

```typescript
// Good
export function processOrder(order: Order): Result { ... }
export interface OrderConfig { ... }

// Avoid: default exports
export default class OrderProcessor { ... }
```

Named exports enable tree-shaking, autocomplete, and consistent naming.

### No barrel files in application code

Import directly from source files:

```typescript
// Good
import { UserCard } from './components/UserCard';

// Avoid
import { UserCard } from './components';  // barrel file
```

Reserve barrel files for library public APIs and monorepo package boundaries.

### Explicit file extensions in ESM

```typescript
import { processOrder } from './services/orders.js';  // .js even for .ts files
```

## Async patterns

### Use async/await over raw promises

```typescript
// Prefer
async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  if (!response.ok) throw new HttpError(response.status);
  return response.json();
}

// Avoid: .then() chains
function fetchUser(id: string): Promise<User> {
  return fetch(`/api/users/${id}`)
    .then(r => { if (!r.ok) throw new HttpError(r.status); return r; })
    .then(r => r.json());
}
```

### Handle errors at boundaries

```typescript
// Service layer: let errors propagate
async function getOrder(id: string): Promise<Order> {
  const order = await db.orders.findById(id);
  if (!order) throw new NotFoundError(`Order ${id}`);
  return order;
}

// Route handler: catch and respond
app.get('/orders/:id', async (req, res) => {
  try {
    const order = await getOrder(req.params.id);
    res.json(order);
  } catch (error) {
    if (error instanceof NotFoundError) return res.status(404).json({ error: error.message });
    throw error;  // re-throw unexpected errors
  }
});
```

## Anti-patterns

| Pattern | Problem | Fix |
|:--|:--|:--|
| `any` everywhere | Disables type checking entirely | `unknown` + narrowing, or specific types |
| Type assertions (`as`) | Bypasses type checker, runtime errors | Type guards, discriminated unions |
| `!` non-null assertion | "Trust me" that hides potential nulls | Optional chaining `?.`, nullish coalescing `??` |
| Nested ternaries | Unreadable conditional logic | `if`/`else`, `switch`, or extracted function |
| `==` instead of `===` | Type coercion surprises | Always `===` and `!==` |
| `var` keyword | Function-scoped, hoisting bugs | `const` by default, `let` when reassigned |
| String enums without `as const` | No exhaustiveness checking | Use `as const` objects or union types |
| Mutation of function arguments | Side effects, debugging difficulty | Return new values, spread operator |
| `try/catch` around everything | Swallows errors, hides bugs | Catch at boundaries, let errors propagate |

## React conventions

### Component structure

```tsx
// 1. Imports
import { useState, useCallback } from 'react';

// 2. Types
interface Props {
  orderId: string;
  onSubmit: (order: Order) => void;
}

// 3. Component (named export)
export function OrderForm({ orderId, onSubmit }: Props) {
  // hooks first
  const order = useOrder(orderId);
  const [editing, setEditing] = useState(false);

  // handlers
  const handleSubmit = useCallback(() => {
    onSubmit(order);
  }, [order, onSubmit]);

  // early returns for loading/error states
  if (!order) return <Spinner />;

  // render
  return <form onSubmit={handleSubmit}>...</form>;
}
```

### Hook rules

- Hooks at the top of the component, never inside conditions/loops
- Custom hooks start with `use` prefix
- Extract hooks when a component has 5+ state variables or 3+ effects
- Hooks should do one thing (not `useEverything()`)

### State management selection

| Scope | Solution |
|:--|:--|
| Component-local | `useState`, `useReducer` |
| Shared between siblings | Lift state to parent |
| Cross-cutting (theme, auth) | React Context |
| Server state | TanStack Query, SWR |
| Complex client state | Zustand, Jotai |

## ESLint configuration

Recommended rules for enforcing these standards:

```json
{
  "rules": {
    "max-lines": ["warn", { "max": 300, "skipBlankLines": true, "skipComments": true }],
    "max-lines-per-function": ["warn", { "max": 50, "skipBlankLines": true, "skipComments": true }],
    "complexity": ["warn", 10],
    "max-depth": ["warn", 3],
    "max-params": ["warn", 3],
    "no-var": "error",
    "prefer-const": "error",
    "eqeqeq": "error",
    "@typescript-eslint/no-explicit-any": "warn",
    "@typescript-eslint/no-non-null-assertion": "warn",
    "import/no-cycle": "error",
    "import/no-default-export": "warn"
  }
}
```

## Testing conventions

- Test files co-located with source: `OrderForm.test.tsx` next to `OrderForm.tsx`
- Describe blocks mirror component/function structure
- Test behavior, not implementation: "renders order total" not "calls useState"
- Use `@testing-library/react` over Enzyme
- Mock at module boundaries (API calls, external services), not internal functions

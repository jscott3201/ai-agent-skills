# JavaScript/TypeScript Modularization Patterns

Language-specific guidance for restructuring JS/TS codebases. Load when the
modularize skill targets JavaScript or TypeScript code.

## Module splitting

### When to split a file

Split when any condition holds:
- File exceeds 300 lines of code
- File contains more than one public-facing abstraction
- Two or more unrelated concerns in the same file
- A function exceeds 30 lines
- The file name requires "and" or a vague term like "utils"

### Named exports (preferred)

Always use named exports over default exports:

```typescript
// Good: named exports
export function processOrder(order: Order): Result { ... }
export interface OrderConfig { ... }

// Avoid: default exports
export default class OrderProcessor { ... }
```

Named exports enable tree-shaking, IDE autocomplete, and consistent naming
across consumers.

### ESM (preferred)

Use ES Modules for all new code:
- Set `"type": "module"` in `package.json`
- Set `"module": "ESNext"` or `"module": "NodeNext"` in `tsconfig.json`
- Use explicit file extensions in relative imports

For libraries that need CJS compatibility, use `tsup` or similar to
produce dual output with `"exports"` field conditions.

## Barrel file removal

### Why barrel files are harmful in application code

Barrel files (`index.ts` re-exporting from a directory) cause:
- **Bundle bloat**: one project cut 400 KB by removing a single barrel file
- **Build slowdown**: TypeScript crawls full dependency graphs to merge types
- **Tree-shaking failure**: bundlers include entire re-exported modules
- **Circular dependency risk**: implicit coupling through centralized re-exports

### When barrel files are acceptable

- Library public API (single entry point for npm consumers)
- Package boundaries in monorepos (one `index.ts` per package)
- Never for internal application module organization

### Migration pattern

```typescript
// Before: barrel file import
import { UserCard, UserList, UserForm } from './components';

// After: direct imports
import { UserCard } from './components/UserCard';
import { UserList } from './components/UserList';
import { UserForm } from './components/UserForm';
```

Use `tsconfig.json` path aliases for shorter imports if needed:

```json
{
  "compilerOptions": {
    "paths": {
      "@features/*": ["src/features/*"],
      "@shared/*": ["src/shared/*"]
    }
  }
}
```

## React-specific patterns

### Extract component

Split when a JSX block is self-contained and either reusable or complex
enough to warrant isolation:

```tsx
// Before: everything in one component
function OrderPage() {
  // ... 50 lines of state and logic
  return (
    <div>
      {/* 30 lines of order summary JSX */}
      {/* 40 lines of line items table JSX */}
      {/* 20 lines of action buttons JSX */}
    </div>
  );
}

// After: extracted components
function OrderPage() {
  const order = useOrder(orderId);
  return (
    <div>
      <OrderSummary order={order} />
      <LineItemsTable items={order.items} />
      <OrderActions order={order} onSubmit={handleSubmit} />
    </div>
  );
}
```

### Extract hook

Extract when a component has 5+ lines of logic before `return`, or
multiple `useState`/`useEffect` calls serving a single concern:

```tsx
// Before: logic mixed into component
function OrderForm() {
  const [values, setValues] = useState({});
  const [errors, setErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);
  useEffect(() => { /* validation logic */ }, [values]);
  useEffect(() => { /* auto-save logic */ }, [values]);
  // ... more state management
  return <form>...</form>;
}

// After: extracted hook
function OrderForm() {
  const { values, errors, submitting, handleChange, handleSubmit } =
    useOrderForm();
  return <form>...</form>;
}
```

### Extract service

Move business logic, API calls, and data transformation out of
components and hooks:

```typescript
// services/orders.ts
export async function createOrder(items: CartItem[]): Promise<Order> {
  const validated = validateItems(items);
  const totals = calculateTotals(validated);
  return api.post('/orders', { items: validated, ...totals });
}

// hooks/useCreateOrder.ts
export function useCreateOrder() {
  return useMutation({ mutationFn: createOrder });
}
```

### Prop drilling fixes (ordered by preference)

1. **Lift state down**: move state closer to where it's consumed
2. **Component composition**: use `children` or render props to skip layers
3. **React Context**: for cross-cutting state (theme, auth, locale)
4. **State library**: Zustand, Jotai for complex shared state

Apply when props pass through 3+ intermediate components that don't use them.

## Interface segregation

Split large prop interfaces when a component receives 8+ props:

```typescript
// Before: monolithic props
interface CardProps {
  title: string;
  description: string;
  imageUrl: string;
  onEdit: () => void;
  onDelete: () => void;
  isAdmin: boolean;
}

// After: segregated by concern
interface CardContentProps {
  title: string;
  description: string;
  imageUrl: string;
}

interface CardActionsProps {
  onEdit: () => void;
  onDelete: () => void;
}
```

## Discriminated unions over boolean flags

Replace boolean flag combinations that allow impossible states:

```typescript
// Before: allows { isLoading: true, isError: true }
interface State {
  isLoading: boolean;
  isError: boolean;
  data?: User;
  error?: Error;
}

// After: impossible states are unrepresentable
type State =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: User }
  | { status: 'error'; error: Error };
```

## Feature-based organization

The 2025/2026 consensus for applications of any meaningful size:

```
src/
  features/
    orders/
      api/              # route handlers
      components/       # React components
      hooks/            # feature-specific hooks
      services/         # business logic
      types.ts          # feature-scoped types
      index.ts          # public API (only allowed barrel file)
    users/
      ...
  shared/
    ui/                 # design system components
    utils/              # cross-cutting utilities (named by purpose)
    types/              # shared type definitions
  app/
    routes.ts           # routing, providers, entry point
```

Import rules:
- Features import from `shared/`, never from other features
- `shared/` never imports from features
- `app/` imports from both
- Enforce with `eslint-plugin-boundaries` or `dependency-cruiser`

## Circular dependency detection

### Tooling

```bash
# madge: detect circular dependencies
npx madge --circular --ts-config ./tsconfig.json --extensions ts,tsx src/

# madge: generate dependency graph
npx madge --image graph.svg --ts-config ./tsconfig.json src/

# dependency-cruiser: full analysis with rules
npx depcruise --config .dependency-cruiser.js src
```

### Prevention

- ESLint: `import/no-cycle` rule
- `eslint-plugin-boundaries`: define allowed dependency relationships
- CI: run madge/dependency-cruiser as pipeline steps

## Verification commands

After each structural change:

```bash
tsc --noEmit                   # type check
npx eslint .                   # lint check
npm test                       # behavior preservation
```

### Recommended ESLint thresholds

```json
{
  "rules": {
    "max-lines": ["warn", { "max": 300, "skipBlankLines": true, "skipComments": true }],
    "max-lines-per-function": ["warn", { "max": 50, "skipBlankLines": true, "skipComments": true }],
    "complexity": ["warn", 10],
    "max-depth": ["warn", 3],
    "max-params": ["warn", 3]
  }
}
```

## Decision flowchart

```
File > 300 lines?
├─ Yes → Split by concern, extract components/hooks/services
└─ No → Barrel file in application code?
    ├─ Yes → Delete barrel, use direct imports
    └─ No → Component has 5+ useState calls?
        ├─ Yes → Extract custom hook
        └─ No → Props pass through 3+ layers?
            ├─ Yes → Composition, context, or state library
            └─ No → Two modules import each other?
                ├─ Yes → Extract shared types, dependency inversion
                └─ No → Keep as-is
```

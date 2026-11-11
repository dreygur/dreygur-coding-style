# Testing

Universal Rules 11 to 13 set the bar: tests execute the code, doubles are named `mock`, bug fixes start red. This file covers where tests go and what they look like. Seam, mocking and anti-pattern rules adapted from `mattpocock/skills` (tdd).

## Seams

A seam is the public interface a test drives: it calls in and observes what comes out, without reaching inside. Tests live at seams.

When the task creates a new module or a new public interface, list the seams before writing tests and confirm them with dreygur. One line per seam: what it catches, what it misses. Additions to existing code test at the seam already there, no checkpoint needed.

## The Loop

Red, then green, one slice at a time. Write one failing test at one seam, then only the code that passes it. Refactor once the slice is green.

## Mock at Boundaries

Mock what the code does not own: external APIs, databases and repositories, time, randomness, the filesystem. Your own modules and internal collaborators run for real.

Make a boundary mockable by passing it in:

```ts
// wrong: the client is built inside, so a test cannot swap it
export async function chargeOrder(order: Order): Promise<Receipt> {
  const payments = new StripeClient(process.env.STRIPE_KEY);
  return payments.charge(order.total);
}

// right
export async function chargeOrder(order: Order, payments: PaymentClient): Promise<Receipt> {
  return payments.charge(order.total);
}
```

Give each external operation its own function. Each mock then returns one shape and needs no branching:

```ts
// wrong: the mock has to branch on the path
const api = { fetch: (path: string, init?: RequestInit) => fetch(path, init) };

// right
const api = {
  getUser: (id: UserId) => fetch(`/users/${id}`),
  createOrder: (data: TOrderInsert) => fetch("/orders", { method: "POST", body: JSON.stringify(data) }),
};
```

Mocks follow Rule 12: `MockPaymentClient`, `mock_store.go`.

## Anti-Patterns to Avoid

- **Implementation coupled**: the test mocks an internal collaborator, calls a private method, or checks a side channel, such as querying the database instead of reading back through the interface. It breaks on a refactor that keeps behavior. Test through the seam.
- **Tautological**: the assertion recomputes the expected value the way the code does, so it passes by construction: `expect(add(a, b)).toBe(a + b)`. Expected values come from a source independent of the code: a literal worked by hand, the spec, a known good output.
- **Horizontal slicing**: every test first, then every implementation. The tests describe imagined behavior and lock their shape before the code has taught anything. Work in vertical slices: one test, the code to pass it, repeat.

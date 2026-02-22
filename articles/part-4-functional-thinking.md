# Functional Thinking

**Part 4 of 8: The AtomiCloud Engineering Series**

_[Part 3](./part-3-solid-principles.md) gave us structural rules for organizing code. Now we turn to how code behaves. Functional programming offers useful ways to think about code -- patterns that make reasoning easier and bugs less likely. These are not constraints or laws. They are guidelines that, when followed, tend to produce code with better locality._

1. [Software Design Philosophy](./part-1-software-design-philosophy.md)
2. [The Dependency Model](./part-2-dependency-model.md)
3. [SOLID Principles](./part-3-solid-principles.md)
4. **Functional Thinking** (you are here)
5. [Domain-Driven Design](./part-5-domain-driven-design.md)
6. [Three-Layer Architecture](./part-6-three-layer-architecture.md)
7. [Wiring It Together](./part-7-wiring-it-together.md)
8. [Testing and Testability](./part-8-testing-and-testability.md)

---

## The Best of Both Worlds

We are not choosing between functional and object-oriented programming. We are taking useful ideas from both.

Functional programming teaches us patterns that make code easier to reason about: immutability, purity, explicit errors. Object-oriented programming teaches us how to organize code at scale: grouping, interfaces, dependency injection.

The synthesis: use OO structure to organize code, use functional patterns inside that structure. Services are stateless objects with immutable members. Methods are functions that happen to live on a class. Dependencies flow through constructors. Side effects live at the boundaries.

---

## Immutability

You pass an object to a function, expecting it to remain unchanged. But the function modifies it:

```
function applyDiscount(order: Order, pct: float) -> Order:
  order.total = order.total * (1 - pct)
  return order

// Later:
original = getOrder(id)
discounted = applyDiscount(original, 0.10)
auditOrder(original)  // BUG: original has been modified
```

The caller assumed `original` would not change. That assumption was wrong, and now `auditOrder` logs the wrong total. This is not a rare edge case -- it is the default behavior in most languages. You must read the implementation of every function to know whether it mutates.

The fix is simple: never modify inputs, always return new values.

```
function applyDiscount(order: Order, pct: float) -> Order:
  return Order(
    ...order,
    total: order.total * (1 - pct)
  )
```

Now `original` is untouched. The bug cannot exist.

But why does this matter at scale? Consider three functions -- `f`, `g`, and `h` -- that all read and write a shared mutable variable `x`. The 3 functions can be called in 3! = 6 orderings, and each can encounter `x` in 3 different states (set by the functions that ran before it). That is 18 combinations you have to reason about -- for just three functions sharing one variable. In a real system with hundreds of functions and dozens of shared variables, this explodes beyond human comprehension.

Make `x` immutable, and each function receives its input as a parameter and returns a new value. The 6 orderings still exist, but position no longer matters -- each function always sees the value it was given. We go from 18 to 6. In a real codebase with thousands of possible positions, the reduction is from 6000 cases to 6. Immutability eliminates temporal coupling -- the result of reading a value no longer depends on what ran before.

Immutability solves problems in the **data domain**. It governs what happens to values after they are created. You can pass data to multiple consumers without defensive copying, because no function can corrupt what another function needs. You can keep previous versions around for undo and history. You can detect changes with a simple identity check (`old === new`). You never need locks for thread safety. And the "who changed this?" category of bug disappears entirely.

Even with impure functions (logging, I/O), immutable data will not be corrupted by those side effects.

---

## Pure Functions

Now consider a different problem. A function reads from global state:

```
global taxRate = 0.08

function calculateTax(amount: Money) -> Money:
  return amount * taxRate
```

What does `calculateTax(100)` return? You cannot know without checking what `taxRate` happens to be right now. The function reaches outside itself. Scale this up -- functions reading from globals, configs, databases, shared objects -- and to understand any function, you must trace its entire environment.

Make the dependency explicit:

```
function calculateTax(amount: Money, rate: float) -> Money:
  return amount * rate
```

Now `calculateTax(100, 0.08)` always returns `8`. Call it from anywhere, at any time, in any order.

Purity solves problems in the **computation domain**. It governs how functions relate inputs to outputs. A pure function gives you testability (same input, same output, no mocking needed), referential transparency (you can replace `add(2, 3)` with `5` anywhere), safe memoization (deterministic output means safe caching), parallel execution (no race conditions), and local reasoning (understand the function in isolation without tracing external state).

Even with mutable data elsewhere in the system, a pure function's internal logic is predictable.

---

## Together: The Ultimate Guarantee

Immutability and purity are independent properties. You can have one without the other.

You can write pure functions without immutability -- the function itself does not mutate anything, but the data structures it works with _could_ be mutated by other code elsewhere. The function is safe; the data is not. You can also have immutability without pure functions -- the data is safe from corruption, but functions still read from globals, write logs, or make network calls. The data is predictable; the computation is not.

But they reinforce each other. Immutability makes purity easier -- if your data never changes, you will not accidentally mutate arguments inside a function. The temptation to take shortcuts ("just modify this field in place") disappears when the type system prevents it. And purity makes immutability worthwhile -- immutable data is safe to share, but if functions have hidden side effects, you still cannot reason about the system.

Together, they provide the ultimate guarantee: **your data does not change, and your functions are predictable.** The combinatorial explosion is eliminated. The hidden state is gone. The entire system becomes a pipeline of transformations: data flows in, new data flows out, nothing is mutated, nothing is hidden.

This is the foundation that makes the domain layer in [Part 6](./part-6-three-layer-architecture.md) possible -- a pure core where business logic is just functions transforming structures, with all side effects pushed to the boundaries.

Of course, not all code can be pure. An application that never reads from a database or writes a response is useless. The question is _where_ to put impurity. The answer: push side effects to the boundaries. The domain layer is pure -- no IO, no external state. Controllers (which receive requests) and repositories (which touch databases) handle the impure parts. The domain sits in the middle, receiving data and returning data, never reaching outward. When the domain is pure, you can test every business rule without a database, without a network, without mocking. You pass in structures and assert on structures.

---

## Total Functions

A function's type signature is a promise: "give me these inputs and I will return this output." But some functions lie:

```
function divide(a: int, b: int) -> int:
  if b == 0:
    throw DivisionByZeroError
  return a / b
```

The signature says `int, int -> int`. But for some inputs, you do not get an int -- you get an exception. Every caller now carries an invisible burden: they must remember that `divide` can throw, and the compiler will not remind them.

Make the function honest instead. Encode all possible outcomes in the return type:

```
function divide(a: int, b: int) -> Result<int, DivisionError>:
  if b == 0:
    return Err(DivisionError("cannot divide by zero"))
  return Ok(a / b)
```

Now the type tells the truth. `Result<int, DivisionError>` means you get either an int or an error. The caller must handle both. Never throw exceptions for expected failure paths -- validation errors, not-found conditions, network timeouts are expected outcomes that belong in the return type. Exceptions are for truly exceptional situations: out of memory, stack overflow.

There is a deep connection here to [Part 2](./part-2-dependency-model.md)'s explicit dependencies. Explicit dependencies declare what a function **needs** in its signature -- the constructor for collaborators, the parameters for data. Total functions declare what a function **produces** in its signature -- all possible outcomes, including failures. Together, the signature tells the complete story: what goes in and what comes out. This is locality applied to function boundaries. You can read a total function's signature and know _everything_ about its contract without opening the implementation.

A partial function that throws exceptions is like an implicit dependency -- hidden behavior that does not appear in the signature. The caller must know about it through documentation, convention, or painful experience. A total function makes it explicit, just as constructor injection makes dependencies explicit.

---

## Composing with Results

When functions return `Result<T, E>`, chaining them can get noisy:

```
function processOrder(id: string) -> Result<Invoice, OrderError>:
  orderResult = repo.getOrder(id)
  if orderResult.isErr():
    return Err(orderResult.unwrapErr())

  order = orderResult.unwrap()
  validationResult = validator.validate(order)
  if validationResult.isErr():
    return Err(validationResult.unwrapErr())

  pricingResult = pricing.calculate(order)
  if pricingResult.isErr():
    return Err(pricingResult.unwrapErr())

  return Ok(Invoice.from(pricingResult.unwrap()))
```

Every step requires checking and propagating errors. The happy path is buried. Railway oriented programming gives us a better way -- think of computation as two parallel rails. The happy path runs on one rail, the error path on the other. Once you switch to the error rail, you stay there:

```
function processOrder(id: string) -> Result<Invoice, OrderError>:
  return repo.getOrder(id)
    .andThen(order -> validator.validate(order))
    .andThen(order -> pricing.calculate(order))
    .map(priced -> Invoice.from(priced))
```

`andThen` chains operations: if the previous result is `Ok`, it calls the next function; if `Err`, it skips and passes the error through. Read it top to bottom: get the order, validate it, calculate pricing, build the invoice. If any step fails, the error propagates automatically.

In a layered architecture, each layer has its own error types. Use `.mapErr()` to translate between them:

```
return userRepo.findById(id)                    // Result<DataModel, RepoError>
  .map(data -> toUserDomain(data))              // Result<User, RepoError>
  .mapErr(err -> toDomainError(err))            // Result<User, DomainError>
  .andThen(user -> enrichUser(user))            // Result<EnrichedUser, DomainError>
  .map(user -> toUserResponse(user))            // Result<UserResponse, DomainError>
  .mapErr(err -> toProblemDetails(err))         // Result<UserResponse, ProblemDetails>
```

Data flows forward through `.map()` and `.andThen()`. Errors flow sideways through `.mapErr()`. The pipeline is composable and type-safe.

---

## Grouping, Not Encapsulation

A word on terminology: we prefer **grouping** over **encapsulation**.

Encapsulation implies hiding -- the private/public distinction, information hiding, secrets kept within boundaries. While this sounds good in theory, it often leads to code that hides too much. Private methods become implicit dependencies. Internal state becomes a black box that tests cannot inspect.

Grouping is simpler. It just means putting related things together. Things that change together? Group them. Things that share a reason to change? Group them. Things that form a cohesive concept? Group them. A group can be fully transparent -- every member visible, every dependency explicit -- while still providing the benefit of cohesion. No hiding required. Just thoughtful organization.

---

## Quick Checklist

**Immutability:**

- [ ] Never mutate input parameters -- always return new values
- [ ] Use immutable constructs where the language supports them
- [ ] Data is safe to share across consumers without defensive copying

**Purity:**

- [ ] Domain logic depends only on its inputs
- [ ] Side effects confined to adapters and controllers at boundaries
- [ ] Functions can be understood in isolation without tracing external state

**Together:**

- [ ] Domain layer combines immutability and purity for the ultimate guarantee
- [ ] Data does not change, and computations are predictable

**Total Functions:**

- [ ] Expected failures encoded in return type (`Result<T, E>`), not thrown
- [ ] Type signatures honestly describe all outcomes
- [ ] Function signatures tell the complete story: what goes in, what comes out

**Composition:**

- [ ] Results composed with `.map()`, `.andThen()`, `.mapErr()`
- [ ] Error types mapped between layers like data types

**Grouping:**

- [ ] Related code lives together -- grouped by reason to change
- [ ] Dependencies remain visible even within groups
- [ ] No hiding behind private/public boundaries that obscure behavior

---

## What Comes Next

Functional thinking gives us patterns for making code behavior predictable and composable. But we have not yet talked about what code is _about_ -- the domain itself.

[Part 5: Domain-Driven Design](./part-5-domain-driven-design.md) shows how to model business concepts as code. Records, Principals, Aggregate Roots -- structures that speak the language of the domain and stay pure from infrastructure concerns.

---

_Previous: [Part 3: SOLID Principles](./part-3-solid-principles.md) | Next: [Part 5: Domain-Driven Design](./part-5-domain-driven-design.md)_

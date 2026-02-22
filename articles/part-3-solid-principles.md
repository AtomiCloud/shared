# SOLID Principles

**Part 3 of 8: The AtomiCloud Engineering Series**

_[Part 2](./part-2-dependency-model.md) gave us the model for explicit and flexible dependencies. SOLID provides the rules for applying that model well. Each principle addresses a specific aspect: what belongs together, how to open code for extension, how to design interfaces, how to invert dependencies. These are not arbitrary rules -- they follow directly from the goal of locality._

1. [Software Design Philosophy](./part-1-software-design-philosophy.md)
2. [The Dependency Model](./part-2-dependency-model.md)
3. **SOLID Principles** (you are here)
4. [Functional Thinking](./part-4-functional-thinking.md)
5. [Domain-Driven Design](./part-5-domain-driven-design.md)
6. [Three-Layer Architecture](./part-6-three-layer-architecture.md)
7. [Wiring It Together](./part-7-wiring-it-together.md)
8. [Testing and Testability](./part-8-testing-and-testability.md)

---

## How These Principles Emerged

These principles were not handed down from a mountain. They were discovered through pain.

Consider a team building an e-commerce system. At first, everything is simple: one `OrderService` that handles everything. It works. The team ships fast. Then features accumulate:

- The marketing team wants to add coupon codes
- The warehouse needs to know about shipments
- Finance needs different tax calculations per region
- Customer support needs to view order history differently

Each feature touches the same `OrderService`. Each release carries risk. A bug in tax calculation breaks shipment notifications. A change to the email template breaks the payment flow. The team becomes afraid to touch the code.

After a while, the team notices patterns. Some changes happen together -- every time marketing changes coupon logic, they also change the discount calculator. These belong together. Other changes are independent -- tax calculation and email formatting never change for the same reason. These should be separate. Some code depends on stable things, while other code depends on volatile things. They should not be tightly coupled.

SOLID is the formalization of these observations. It tells us how to draw boundaries so that things that change together live together, things that change independently are separated, and the boundaries are explicit and swappable -- exactly the properties [Part 2](./part-2-dependency-model.md) showed us we need.

---

## S -- Single Responsibility Principle

> A class should have only one reason to change.

The word "responsibility" does not mean "one thing it does." A class that handles CRUD for customers does four things, but they all change for the same reason. That is one responsibility.

### Reason to Change vs Rate of Change

There are two ways to think about this. **Reason to change** is the intrinsic property -- why would this code need to change? What external force drives it? Tax law? Marketing campaign? Database migration? **Rate of change** is the observable metric -- how often does this code change, and does it change on the same commits as other code?

Rate of change is easier to observe -- you can measure it from git history. But reason to change is the underlying truth. We observe rate of change because it reveals reason to change. If two pieces of code change on the same commits over and over, they probably share a reason to change.

### When `render` Does Not Belong

Say you are building a CLI tool for managing customers. You have a `CustomerService` that handles CRUD operations and also renders customer data to the terminal:

```
class CustomerService:
  get(id) -> Customer
  delete(id) -> void
  create(record) -> Customer
  render(customer) -> ASCIITable
```

It works. Then you notice something: `get`, `delete`, and `create` change at the same rate. When you change one, you usually change the others -- they are driven by the same external force, the business lifecycle of customers. But `render` changes for a completely different reason. When the marketing team wants a prettier output, or the terminal format needs to change, you are editing the same class that handles domain logic.

The day someone breaks `create` while tweaking the ASCII table format, the reason becomes visceral:

```
class CustomerService:
  get(id) -> Customer
  delete(id) -> void
  create(record) -> Customer

class CustomerRenderer:
  render(customer) -> ASCIITable
```

Now a UI change does not touch `CustomerService`, and a domain change does not touch `CustomerRenderer`.

### From Private Methods to Injectable Services

SRP leads to a surprising consequence about private methods. Consider a password checker:

```
class PasswordChecker:
  check(password) -> bool:
    hasAlpha = false
    hasSpecial = false
    for char in password:
      if char.isLetter(): hasAlpha = true
      if "!@#$%".contains(char): hasSpecial = true
    return hasAlpha && hasSpecial
```

This is hard to read. The natural instinct is to extract private helpers:

```
class PasswordChecker:
  check(password) -> bool:
    return hasAlpha(password) && hasSpecial(password)

  private hasAlpha(s) -> bool:
    return s.matchesPattern("[a-zA-Z]")

  private hasSpecial(s) -> bool:
    return s.matchesPattern("[!@#$%]")
```

Looks cleaner. But think about it through [Part 2](./part-2-dependency-model.md)'s lens: `hasAlpha` and `hasSpecial` are now implicit dependencies of `check`. They do not appear in the constructor. You cannot see them from outside. You cannot test them directly -- you must test them through `check`, which means you are always testing two things at once. And you cannot swap the behavior without editing `PasswordChecker`.

What if we follow SRP properly? `hasAlpha` and `hasSpecial` are really about string pattern matching -- a different concern from password policy. They should be extracted into their own class:

```
class StringChecker:
  matchesPattern(s: string, pattern: string) -> bool:
    return s.matches(pattern)

class PasswordChecker:
  private readonly checker: IStringChecker

  constructor(checker: IStringChecker):
    this.checker = checker

  check(password) -> bool:
    return this.checker.matchesPattern(password, "[a-zA-Z]")
        && this.checker.matchesPattern(password, "[!@#$%]")
```

Now `StringChecker` is independently testable, reusable, and swappable. The dependency is explicit in the constructor.

Here is the payoff. Say the original `StringChecker` uses regex for pattern matching. Six months later, someone builds a token-based parser that is three times faster. With the injectable design, you swap in the new parser without touching `PasswordChecker`. Its tests do not change. Its code does not change. The `StringChecker` was mocked in `PasswordChecker`'s tests all along, so the new parser only needs its own new tests.

**When you break down a function, the pieces should become peers, not subordinates.** Extract to a new class, inject through the constructor, and let the caller decide the implementation.

---

## O -- Open-Closed Principle

> Software entities should be open for extension, but closed for modification.

OCP means you can change behavior without changing existing code. The simplest form is parameterization:

```
// Closed -- hardcoded behavior
function addClosed():
  return 3 + 5

// Opened -- parameterized input
function add(a: int, b: int):
  return a + b

// Opened further -- parameterized behavior
function combine(a: int, b: int, op: (int, int) -> int):
  return op(a, b)
```

Each step opens the function to more extension without modification. But there are limits -- if `combine` parameterizes everything, it is no longer a function, it is a programming language. It is an art to decide how much to open up and how much to seal.

To see where this leads in practice, consider writing a git wrapper library:

```
git_add(git_binary: string, repo_path: string, target: string):
  ...

git_rm(git_binary: string, repo_path: string, target: string):
  ...

git_commit(git_binary: string, repo_path: string, commit_msg: string):
  ...
```

Every function needs `git_binary` and `repo_path`. Each caller must pass the same values over and over, and must make sure they use the same variable. The library is open to extension (you can change the binary and repo path), but tiresome to use.

What we really want is to group the shared configuration together. And this is where objects come from -- not from traditional OOP thinking about modeling the world, but from a practical need to manage shared dependencies:

```
class Git:
  private readonly binary: string
  private readonly repo: string

  constructor(binary: string, repo: string):
    this.binary = binary
    this.repo = repo

  add(target: string):
    ...

  rm(target: string):
    ...

  commit(msg: string):
    ...
```

The members `binary` and `repo` are configuration -- set once at construction, never changed. This is what classes actually are in our model. Class members are either **configuration values** (timeouts, endpoints, feature flags) or **injected services** (repositories, clients, other services). No mutable state. Every member is set once in the constructor and never modified.

### Why Interfaces Over Higher-Order Functions

If functions can parameterize everything, why use interfaces? Because functional-style writing, while powerful, is too free. Arguments can be functions of functions of higher-order types, which allows anyone to do anything in any order. OOP provides a more restricted framework that gives us a guideline on what to open up: interfaces.

Interfaces are **named contracts** with semantic meaning. `IEmailSender` tells you something that `(Email) -> void` does not. They standardize what is opened up and constrain the degrees of freedom to exactly what is needed.

At AtomiCloud, methods take value types as arguments. If behavior is needed, it comes from an injected collaborator -- an interface with a name, a contract, and a testable identity. This ties directly to [Part 2](./part-2-dependency-model.md)'s model: by requiring interfaces in constructors, we make dependencies both explicit and flexible.

---

## L -- Liskov Substitution Principle

> Subtypes must be substitutable for their base types without altering correctness.

LSP constrains how you implement interfaces. Every implementation must honor the full contract -- including implicit behavioral promises. It is more of a warning than a creative principle, but violating it undermines everything else.

Consider the classic square-and-rectangle example:

```
class Rectangle:
  setWidth(w):
    width = w

  setHeight(h):
    height = h

  area() -> width * height

class Square extends Rectangle:
  setWidth(w):
    width = w
    height = w  // forced: must keep sides equal

  setHeight(h):
    height = h
    width = h   // forced: must keep sides equal
```

The real-life logic of "a square is a rectangle with equal sides" seems to make the design elegant. Now imagine this code in production:

```
const r = factory.newRectOrSquare()

r.setWidth(5)
r.setHeight(8)

r.area()   // should be 40, but if r is a Square, it returns 64!
```

The caller had no way to know that setting width would also change height. Square violates LSP because it breaks the implicit promise that `setWidth` and `setHeight` are independent operations.

But there is a deeper lesson here. Classes are concepts. Objects are real things. These are different hierarchies. Classes, interfaces, and types are ideas that do not exist at runtime. We build a hierarchy over these concepts -- a graph of how ideas relate. Objects, on the other hand, are real -- they interact at runtime, call each other, hold references.

In the real world, a square is always a rectangle. Measure any square: four right angles, four sides, yes -- it is a rectangle. But the _concept_ of a Square (four equal sides, area equals side squared) is not a refinement of the _concept_ of a Rectangle (setWidth and setHeight are independent). They overlap, but they are not strictly hierarchical.

It is like dogs and humans. In reality, a dog and a human live together, interact daily -- practically family. But the _concept_ of a dog and the _concept_ of a human are far apart on the tree of life. The real-world relationship (close) does not match the conceptual relationship (distant). Conflating the two is what causes LSP violations.

This is why we prefer interface implementation over inheritance. Interfaces define explicit contracts -- you know exactly what behaviors are promised. Inheritance creates implicit contracts through shared implementation, where it is dangerously easy to override behavior in ways that break the parent's promises.

---

## I -- Interface Segregation Principle

> No client should be forced to depend on methods it does not use.

ISP looks similar to SRP, but it is subtly different. SRP says "gather together things that change for the same reasons." ISP says "don't depend on more than you need."

The difference matters. Imagine a `Stack` class with both `push` and `pop`. SRP would _not_ separate them -- they change for the same reason, the stack data structure. But ISP _would_, if a client only pushes and never pops:

```
interface Pusher:
  push(item) -> void

interface Popper:
  pop() -> Item

class Stack implements Pusher, Popper:
  push(item) -> void
  pop() -> Item
```

The push-only client depends on `Pusher` -- a minimal contract. If `Stack` adds methods, the push-only client is unaffected.

The key insight: design interfaces from the **consumer's** perspective, not the implementation's. A single object can implement many interfaces. Each interface is one lens through which to see the object, scoped to exactly what the consumer needs. This is [Part 2](./part-2-dependency-model.md)'s explicitness applied at the interface level -- the dependency is not just visible, it is _precisely_ scoped.

---

## D -- Dependency Inversion Principle

> High-level modules should not depend on low-level modules. Both should depend on abstractions.

While listed last, DIP is the core principle that binds everything together. From [Part 1](./part-1-software-design-philosophy.md), we identified dependencies as the root cause of coupling. From [Part 2](./part-2-dependency-model.md), we established that dependencies should be explicit and flexible. DIP is the mechanism that makes both possible.

When function A calls function B directly, A depends on B. If C also uses B, then A and C are transitively coupled through B. If B changes for something A needs, C is impacted. If C needs a change to B, we must consider how it impacts A. This is the core dependency problem.

DIP solves it by adding an interface between them:

```
// Before: A depends directly on B
A -> B

// After: A and B both depend on interface X
A -> X <- B
```

`A` depends on interface `X`. `B` implements `X`. Now they are decoupled -- `B` can be replaced without touching `A`. If `C` also needs `B`, it creates its own interface `Y`, and `B` implements both. If it cannot, we split the underlying implementation, and neither `A` nor `C` is affected.

This simple inversion is what makes every other principle practical:

- **ISP** -- `X` should be minimal for what `A` needs
- **LSP** -- `B` must honor the contract of `X`
- **OCP** -- behavior changes by swapping the implementation behind `X`
- **SRP** -- `X` defines a focused contract for a single concern

---

## Explicit and Immutable

[Part 2](./part-2-dependency-model.md) established that dependencies should be explicit and flexible. The SOLID principles show us how. But there is a third property that emerges naturally when you apply these principles: **immutability** -- references that do not change after construction.

```
// WRONG -- implicit dependencies
class OrderService:
  processOrder(order):
    Logger.log("Processing order")    // where did Logger come from?
    return Database.query(...)        // where did Database come from?

// RIGHT -- explicit and immutable
class OrderService:
  private readonly logger: ILogger
  private readonly db: IDatabase

  constructor(logger: ILogger, db: IDatabase):
    this.logger = logger
    this.db = db

  processOrder(order):
    this.logger.log("Processing order")
    return this.db.query(...)
```

The constructor tells you everything: this service needs a logger and a database. No reading method bodies to discover hidden dependencies. And because the references are immutable, you know they will not change during the object's lifetime.

This is what you get when you follow SOLID consistently. Methods take value types as parameters and return value types. Behavior is injected via constructor. Class members are just configurable knobs -- OCP in action. [Part 4](./part-4-functional-thinking.md) will formalize immutability as a broader principle, but here we already see it as a natural consequence of good dependency management.

---

## Temporal Coupling

One more thing worth flagging: temporal coupling. This is when the order of operations matters, but the code does not enforce it. It is a subtle form of implicit dependency -- a dependency on _time_.

```
// WRONG -- must call setTable before build
class QueryBuilder:
  private table: string?
  private columns: string[]?

  setTable(t: string):
    this.table = t

  setColumns(cols: string[]):
    this.columns = cols

  build() -> Query:
    // crashes if table or columns not set!

// RIGHT -- constructor enforces required state
class QueryBuilder:
  constructor(table: string, columns: string[])

  build() -> Query:
    // always works
```

Same thing with mutable state across method calls:

```
// WRONG -- calculateTotal depends on how many times addItem was called
class OrderService:
  private items: Item[] = []

  addItem(item: Item):
    this.items.push(item)

  calculateTotal() -> Money:
    return sum(this.items)

// RIGHT -- all data flows through parameters
class OrderService:
  calculateTotal(items: Item[]) -> Money:
    return sum(items)
```

Now `calculateTotal` is a pure function. Same inputs, same outputs. No temporal coupling. [Part 4](./part-4-functional-thinking.md) will explore this idea much further.

---

## Quick Checklist

- [ ] **SRP:** Each class changes for one reason. Things that change at different rates are separate.
- [ ] **OCP:** Behavior changes by injecting different implementations, not editing code.
- [ ] **LSP:** Every implementation honors the full behavioral contract of its interface.
- [ ] **ISP:** Each interface contains only methods its consumers use.
- [ ] **DIP:** High-level modules depend on interfaces, not implementations.
- [ ] **No private methods:** Helpers extracted as injectable services, explicit in constructors.
- [ ] **Immutable members:** All fields set in constructor and never mutated.
- [ ] **Methods take value types:** Data flows through parameters and return values.
- [ ] **Explicit dependencies:** Can see everything by reading the constructor signature.
- [ ] **No temporal coupling:** Order of method calls does not matter.

---

## What Comes Next

SOLID gives us structural rules -- how to split, parameterize, and invert dependencies. But it says nothing about what code is allowed to do inside those structures. Can a function mutate its arguments? Throw exceptions? Read from global state?

[Part 4: Functional Thinking](./part-4-functional-thinking.md) introduces useful ways to think about code behavior -- not as constraints, but as guidelines that make reasoning easier. Immutability, purity, and explicit error handling are patterns that improve locality, not arbitrary restrictions.

---

_Previous: [Part 2: The Dependency Model](./part-2-dependency-model.md) | Next: [Part 4: Functional Thinking](./part-4-functional-thinking.md)_

# SOLID Principles

SOLID is the disciplined framework for managing dependencies, achieving low coupling and high cohesion. These five principles -- and a set of corollaries -- tell you **when** to group things together and **how** to keep groups independent from each other. They are the structural laws of every AtomiCloud codebase.

This article builds on the foundational ideas in [Software Design Philosophy](../software-design-philosophy/index.md) -- changeability as the goal, locality as the core property, dependencies as the root problem, and the tension between coupling and cohesion. Everything else in the AtomiCloud stack -- [Functional Practices](../functional-practices/index.md), [Domain-Driven Design](../domain-driven-design/index.md), [Three-Layer Architecture](../three-layer-architecture/index.md), and [Stateless OOP with Dependency Injection](../stateless-oop-di/index.md) -- builds on top of these principles.

---

## How These Principles Emerged

These principles were not handed down from a mountain. They were discovered through pain.

Consider a team building an e-commerce system. At first, everything is simple: one `OrderService` that handles everything. It works. The team ships fast. Then features accumulate:

- The marketing team wants to add coupon codes
- The warehouse needs to know about shipments
- Finance needs different tax calculations per region
- Customer support needs to view order history differently

Each feature touches the same `OrderService`. Each release carries risk. A bug in tax calculation breaks shipment notifications. A change to the email template breaks the payment flow. The team becomes afraid to touch the code.

The team notices patterns:

- Some changes happen together. Every time marketing changes coupon logic, they also change the discount calculator. These belong together.
- Some changes are independent. Tax calculation and email formatting never change for the same reason. These should be separate.
- Some code depends on stable things. The database schema changes rarely. The email template changes often. They should not be tightly coupled.

SOLID is the formalization of these observations. It tells us how to draw boundaries so that:

- Things that change together live together (cohesion)
- Things that change independently are separated (coupling)
- The boundaries are explicit and visible (locality)

---

## S -- Single Responsibility Principle (SRP)

> A class should have only one reason to change.

The word "responsibility" does not mean "one thing it does." A class that handles CRUD for customers does four things, but they all change for the same reason. That is one responsibility.

### Reason to Change vs Rate of Change

There are two ways to think about cohesion:

**Reason to change (white-box):** This is the intrinsic property. Why would this code need to change? What external force drives the change? Tax law changes? Marketing campaign? Database migration?

**Rate of change (black-box):** This is the observable metric. How often does this code change? Does it change on the same commits as other code?

Rate of change is easier to observe -- you can measure it from git history. But reason to change is the underlying truth. We observe rate of change because it reveals reason to change. If two pieces of code change on the same commits over and over, they probably share a reason to change.

### Example: The CustomerService

Imagine a CLI application that manages customers stored in a JSON file. You build a `CustomerService` with CRUD operations plus a render method:

```
class CustomerService
  get(id) -> Customer
  delete(id) -> void
  create(record) -> Customer
  render(customer) -> ASCIITable
```

`get`, `delete`, and `create` change for domain lifecycle reasons. `render` changes for display reasons. These are different reasons to change, so split them:

```
class CustomerService
  get(id) -> Customer
  delete(id) -> void
  create(record) -> Customer

class CustomerRenderer
  render(customer) -> ASCIITable
```

Notice that `get` returns a generic `Customer` structure, not a pre-formatted ASCII string. By returning a plain structure, each consumer decides how to present the data -- the CLI renderer formats it as an ASCII table, a web controller serializes it as JSON, a test asserts on the fields.

### The Three-Stage Evolution: From Complexity to Clarity

**Stage 1: A big, complex function.**

```
class PasswordChecker
  check(password) -> bool
    hasAlpha = false
    hasSpecial = false
    for char in password:
      if char.isLetter():
        hasAlpha = true
      if "!@#$%".contains(char):
        hasSpecial = true
    return hasAlpha && hasSpecial
```

**Stage 2: Break it into private helpers.** Cleaner, but private methods are hidden from tests, hidden from the constructor, and locked in:

```
class PasswordChecker
  check(password) -> bool
    return hasAlpha(password) && hasSpecial(password)

  private hasAlpha(s) -> bool
    return s.matchesPattern("[a-zA-Z]")

  private hasSpecial(s) -> bool
    return s.matchesPattern("[!@#$%]")
```

Stage 2 is a trap. It looks better but is still a violation.

**Stage 3: Extract helpers as injectable services.**

```
class StringChecker
  matchesPattern(s, pattern) -> bool
    return s.matches(pattern)

class PasswordChecker
  constructor(checker: StringChecker)

  check(password) -> bool
    return checker.matchesPattern(password, "[a-zA-Z]")
        && checker.matchesPattern(password, "[!@#$%]")
```

Now `StringChecker` is independently testable, reusable, and swappable. The dependency is explicit in the constructor.

### The Absolute Rule: No Private Methods

AtomiCloud code has **zero private methods**. Every private method is a hidden dependency. Every hidden dependency is a testing obstacle. The three-stage evolution always ends at Stage 3.

---

## O -- Open-Closed Principle (OCP)

> Software entities should be open for extension, but closed for modification.

OCP means you can change what the system does without changing the code that already exists. It is about **parameterization** -- making the moving parts configurable rather than hardcoded.

### The Spectrum of Openness

```
// Fully closed -- hardcoded behavior
function addClosed()
  return 3 + 5

// Opened one level -- parameterized input
function addOpened(a, b)
  return a + b

// Opened further -- parameterized behavior
function addEvenMoreOpened(a, b, combine)
  return combine(a, b)
```

### Why OOP, Not Higher-Order Functions

Functional style is **too powerful and too free**. When every argument can be a function of functions, anyone can do anything in any order. OOP provides a **more restricted framework** -- interfaces standardize what is opened up and how it is opened. `IVersionControl` tells you something that `(string) -> void` does not.

Methods should always take value-types as arguments. If a method needs behavior, the constructor should receive another object -- an interface with a name, a contract, and a testable identity.

### The Git Wrapper: A Class Is Born

**Stage 1: Standalone functions** with repeated `gitBinary`, `repoPath` params:

```
function commit(gitBinary, repoPath, message)
  run(gitBinary, "-C", repoPath, "commit", "-m", message)

function push(gitBinary, repoPath)
  run(gitBinary, "-C", repoPath, "push")
```

**Stage 2: Group into a class.** The repeated parameters become constructor config:

```
class Git
  constructor(gitBinary: string, repoPath: string)

  commit(message: string) -> void
  push() -> void
  pull() -> void
```

An object is born -- from OCP, not from abstract "OOP design."

**Stage 3: Separate concerns if needed** (SRP):

```
class GitRepo
  constructor(gitBinary: string, repoPath: string)
  commit(message: string) -> void
  log() -> CommitLog[]

class GitRemote
  constructor(gitBinary: string, repoPath: string, remote: string)
  push() -> void
  pull() -> void
```

**Stage 4: Extract an interface** for swappability:

```
interface IVersionControl
  commit(message: string) -> void
  push() -> void

class Git implements IVersionControl
  constructor(gitBinary: string, repoPath: string)
  ...
```

### Classes as Config/DI Containers

Class members are **only** one of two things:

1. **Configuration values** -- immutable data set at construction time.
2. **Injected services** -- interfaces provided at construction time.

No mutable state. No fields that change after construction.

```
class Enricher
  constructor(
    client: IClient,          // injected service
    encryptor: IEncryptor,    // injected service
    logger: ILogger,          // injected service
    config: EnricherConfig    // configuration
  )

  enrich(data: InputData) -> Result<OutputData>
    // use this.client, this.encryptor, this.logger, this.config
    // but never mutate them
```

---

## L -- Liskov Substitution Principle (LSP)

> Subtypes must be substitutable for their base types without altering the correctness of the program.

LSP is a **constraint** on how you implement interfaces. Every implementation must honor the full contract -- including implicit behavioral promises.

### The Square/Rectangle Problem

```
class Rectangle
  setWidth(w)
  setHeight(h)
  area() -> width * height

class Square extends Rectangle
  setWidth(w)
    width = w
    height = w   // forced: must keep sides equal
  setHeight(h)
    width = h
    height = h
```

The calling code:

```
r = factory.createShape()     // could be Rectangle or Square
r.setWidth(5)
r.setHeight(8)
print(r.area())               // expects 40, gets 64 if Square
```

The caller expects `setWidth` and `setHeight` to be independent operations. `Square` violates this implicit contract.

### Concepts vs Instances

Classes model **concepts**, not instances. Dogs and humans interact closely at the instance level -- they live together, are basically family. But the _concept_ of a dog and the _concept_ of a human are far apart. No one would model `Human extends Dog`.

The concept of a square has the invariant that all sides are equal. The concept of a rectangle has the invariant that width and height are independent. Different behavioral contracts, even though every instance of a square is geometrically a rectangle.

Design-time hierarchies are about **behavioral contracts**. Runtime instances are about **data conformance**. Do not conflate them.

AtomiCloud discourages subclassing (`extends`). Implement interfaces instead.

---

## I -- Interface Segregation Principle (ISP)

> No client should be forced to depend on methods it does not use.

ISP governs **interface design** from the consumer's perspective. Design interfaces for **how users use them**, not for how implementations are structured.

Different from SRP: SRP would not separate `push` from `pop` on a stack (same reason to change). But ISP would if a client only pushes:

```
interface Pusher
  push(item) -> void

interface Popper
  pop() -> Item

class Stack implements Pusher, Popper
  push(item) -> void
  pop() -> Item
```

---

## D -- Dependency Inversion Principle (DIP)

> High-level modules should not depend on low-level modules. Both should depend on abstractions.

DIP is the **core binding principle**. Without DIP, all the other principles are theoretical.

```
A -> B           // A breaks when B changes

A -> X <- B      // X is an interface; A and B are decoupled
```

This pattern is the origin of everything:

- **ISP** exists because `X` should be minimal.
- **LSP** exists because `B` must honor `X`'s contract.
- **OCP** is achieved because behavior is swappable behind `X`.
- **SRP** is enforceable because `X` defines a focused contract.

### Visible + Fixed

A dependency is **visible** when you can see everything the code needs by looking at its signature -- the constructor for a class, the parameters for a function. You should not need to open the method body to discover hidden dependencies.

A dependency is **fixed** when it is immutable after construction. The reference never changes. The behavior never changes.

```
// WRONG -- not visible, not fixed
class OrderService
  processOrder(order)
    Logger.log("Processing order")    // hidden dependency on Logger
    return Database.query(...)        // hidden dependency on Database
```

To understand `processOrder`, you must read the method body. The signature `(order)` tells you nothing about the collaborators. Both `Logger` and `Database` are invisible.

```
// RIGHT -- visible and fixed
class OrderService
  constructor(logger: ILogger, db: IDatabase)
    this.logger = logger   // visible in constructor, fixed reference
    this.db = db           // visible in constructor, fixed reference

  processOrder(order)
    this.logger.log("Processing order")
    return this.db.query(...)
```

Now the constructor tells you everything: this service needs a logger and a database. You can understand the dependencies without reading a single line of method code. And because the references are fixed, you know they won't change during the object's lifetime.

---

## No Singletons: Why OOP Is The Way

There is a common criticism of Java and C#: "everything must be a class." We see this as the **point**. If everything is a class, everything is injectable. If everything is injectable, everything is swappable. Nothing is hardwired.

### The Problem with Global and Static Methods

```
static Logger.log("User logged in")    // decree from the universe
```

A static method cuts through the DI tree. You cannot swap it for a silent logger in tests, a structured logger in production, or a per-module logger. Ever.

```
class UserService
  constructor(logger: ILogger)

  login(user: User) -> Result<Session>
    this.logger.log("User logged in")  // request to a collaborator
```

`static Logger.log()` is an invocation of a global. `this.logger.log()` is a message to a collaborator you control.

### Singletons Are Globals in Disguise

A singleton is a global variable wearing a tuxedo. The fix: create the instance once at the entry point and inject it everywhere.

### Can You Find a Concept That Never Needs a Second Instance?

- **Logger.** Debug, production, per-module, silent for tests.
- **Clock.** Frozen for tests, fast-forward for scheduling, wall clock for prod.
- **Random.** Seeded for deterministic tests, cryptographic for production.
- **Database.** Read replica, test fixtures, multi-tenant connections.
- **PaymentProcessor.** Stripe and PayPal. Mock for tests. Sandbox for staging.
- **TetrisApp.** Split-screen multiplayer? AI training with 1000 instances?

Even the universe -- physicists theorize about multiverses. If the universe might have a second instance, your `DatabaseConnection` definitely can.

### Rules

- **No static methods** that contain business logic.
- **No singletons.** Create instances at the entry point and inject them.
- **No global state.** Values flow through the dependency tree.

---

## Temporal Coupling: A Warning

Temporal coupling occurs when the order of operations matters, but the code does not enforce it. This is a subtle form of hidden dependency.

### Example 1: The Builder That Requires Order

```
// WRONG -- temporal coupling
class QueryBuilder
  private table: string?
  private columns: string[]?

  setTable(t: string)
    this.table = t

  setColumns(cols: string[])
    this.columns = cols

  build() -> Query
    // crashes if table or columns not set!
```

The caller must remember to call `setTable` before `build`. The method signatures do not enforce this. A new developer will forget.

```
// RIGHT -- no temporal coupling
class QueryBuilder
  constructor(table: string, columns: string[])

  build() -> Query
    // always works -- constructor enforced the required state
```

### Example 2: The Two-Phase Initialize

```
// WRONG -- must call initialize() before use
class Connection
  private conn: DbConnection?

  constructor(config: Config)
    this.config = config

  initialize()
    this.conn = DbConnection.connect(this.config)

  query(sql: string) -> Result
    // crashes if initialize() not called!
```

```
// RIGHT -- ready to use after construction
class Connection
  constructor(config: Config)
    this.conn = DbConnection.connect(config)

  query(sql: string) -> Result
    // always works
```

### Example 3: The Service That Depends on Prior Calls

```
// WRONG -- addItem before calculateTotal
class OrderService
  private items: Item[] = []

  addItem(item: Item)
    this.items.push(item)

  calculateTotal() -> Money
    return sum(this.items)
```

The result of `calculateTotal()` depends on how many times `addItem()` was called before it. This is temporal coupling.

```
// RIGHT -- all data flows through parameters
class OrderService
  calculateTotal(items: Item[]) -> Money
    return sum(items)
```

Now `calculateTotal` is a pure function. Same inputs, same outputs. No temporal coupling.

---

## Quick Checklist

- [ ] **SRP:** Does each class have one reason to change? Do things that change for different reasons live in different classes?
- [ ] **OCP:** Can behavior be changed by injecting different implementations rather than editing existing code?
- [ ] **LSP:** Does every implementation honor the full behavioral contract of its interface -- including implicit promises?
- [ ] **ISP:** Does each interface contain only the methods its consumers actually use? Are large interfaces split into focused ones?
- [ ] **DIP:** Do high-level modules depend on interfaces, not concrete implementations? Is all wiring done at the composition root?
- [ ] **No private methods:** Are there zero private methods? Is every helper extracted into its own injectable service?
- [ ] **No singletons:** Are there zero singletons or static methods with business logic? Is everything injectable?
- [ ] **Immutable members:** Are all class fields set in the constructor and never mutated? Are members only config values or injected services?
- [ ] **Methods take value types:** Do methods receive data as parameters (not stored in fields) and return data as results?
- [ ] **Visible dependencies:** Can you see every dependency by looking at the constructor signature, without reading method bodies?
- [ ] **Fixed references:** Do dependencies remain unchanged after construction?
- [ ] **No temporal coupling:** Does the order of method calls not matter? Are objects ready to use after construction?

---

## Related Articles

- [Software Design Philosophy](../software-design-philosophy/index.md) -- the foundational "why" behind all principles
- [Functional Practices](../functional-practices/index.md) -- immutability, pure functions, total functions, and railway oriented programming
- [Domain-Driven Design](../domain-driven-design/index.md) -- how to model the domain
- [Three-Layer Architecture](../three-layer-architecture/index.md) -- how to structure layers and boundaries
- [Stateless OOP and Dependency Injection](../stateless-oop-di/index.md) -- how to structure services and wire dependencies

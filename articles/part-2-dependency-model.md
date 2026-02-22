# The Dependency Model

**Part 2 of 8: The AtomiCloud Engineering Series**

_[Part 1](./part-1-software-design-philosophy.md) established locality as the goal -- keeping related things together, unrelated things apart. Dependencies are what connect code. This part introduces a model for thinking about dependencies: two dimensions that determine whether a dependency helps or harms locality._

1. [Software Design Philosophy](./part-1-software-design-philosophy.md)
2. **The Dependency Model** (you are here)
3. [SOLID Principles](./part-3-solid-principles.md)
4. [Functional Thinking](./part-4-functional-thinking.md)
5. [Domain-Driven Design](./part-5-domain-driven-design.md)
6. [Three-Layer Architecture](./part-6-three-layer-architecture.md)
7. [Wiring It Together](./part-7-wiring-it-together.md)
8. [Testing and Testability](./part-8-testing-and-testability.md)

---

## Two Dimensions of Dependencies

Every dependency has two properties worth thinking about:

1. **Explicitness** -- Is the dependency declared in the interface, or buried inside the implementation?
2. **Flexibility** -- Can you change the dependency's behavior from outside, or is it locked in?

These are mostly independent. As we will see, one particular combination turns out to be impossible in practice, which reveals something deeper about why these properties matter.

---

## Implicit vs. Explicit

An implicit dependency is one you cannot see by reading the signature. You discover it by reading the implementation -- or when something breaks.

```
function processOrder(order):
  Logger.log("Processing order")    // implicit: Logger not in signature
  result = Database.query(...)      // implicit: Database not in signature
  return result
```

The signature says `processOrder(order)`. But the function also depends on `Logger` and `Database`. These dependencies are real -- the function cannot work without them -- but they are invisible to callers.

An explicit dependency, by contrast, appears in a signature -- either the constructor or the method parameters. The user is _forced_ to provide it. There is no way to construct the object without knowing what it needs.

```
class OrderService:
  private readonly repo: IOrderRepository
  private readonly logger: ILogger

  constructor(repo: IOrderRepository, logger: ILogger):
    this.repo = repo
    this.logger = logger

  process(order: Order): Result<Order, OrderError>
```

The key is not merely that you _can_ see the dependency -- it is that the dependency is _required at construction_. The user must provide a repository and a logger. There is no way to accidentally forget one. Even if a dependency does not appear in a method signature, if the constructor forces the user to choose it, it is still explicit.

This creates locality in both directions. From the outside looking in: when you use a class, you know exactly what it needs. Read the constructor, and every collaborator is right there. You do not need to open the implementation to hunt for hidden dependencies. From the inside looking out: when you read the implementation, you do not need to know who is using this code. All dependencies are declared, so you can understand the service in isolation without tracing callers to figure out what globals they might have set up.

Both directions matter. The first protects the person _using_ the code. The second protects the person _reading_ the code. Together, they are what locality looks like in practice.

---

## Fixed vs. Flexible

A fixed dependency is hardcoded. The code decides exactly what to use, and nothing outside can change that decision.

```
class OrderService:
  calculateTotal(order):
    return new TaxCalculator().apply(order)  // fixed: always TaxCalculator
```

`OrderService` creates its own `TaxCalculator`. No other code can provide a different implementation. If you want different tax logic, you must edit this class. Intercepting this would require monkey-patching or reflection -- hacks that work around the design rather than with it.

A subtler form of fixedness is the immutable singleton:

```
Global.TaxCalculator = new USTaxCalculator()   // set once, never changed

class OrderService:
  calculateTotal(order):
    return Global.TaxCalculator.apply(order)   // fixed via immutable global
```

The global is immutable, so the dependency cannot be swapped at runtime. You _could_ change it by mutating the global -- but that introduces mutable global state, which is worse (we will get to that). If the global is truly immutable, the dependency is fixed. Either way, it locks in decisions: the code that uses a dependency also decides which dependency to use.

A flexible dependency can be changed from outside. The code receives its dependency rather than creating it.

```
class OrderService:
  private readonly taxCalculator: ITaxCalculator

  constructor(taxCalculator: ITaxCalculator):
    this.taxCalculator = taxCalculator

  calculateTotal(order):
    return this.taxCalculator.apply(order)
```

Now `OrderService` does not decide which calculator to use. The caller decides. Pass a `USTaxCalculator` for US orders, a `UKTaxCalculator` for UK orders, a `MockTaxCalculator` for tests. The code that uses the dependency is separated from the code that selects it.

---

## Three Combinations, Not Four

You might expect four quadrants from two binary dimensions. But one combination does not exist in practice.

|              | Fixed                                  | Flexible                                |
| ------------ | -------------------------------------- | --------------------------------------- |
| **Implicit** | Worst: Cannot see it, cannot change it | Dangerous: Can change it, cannot see it |
| **Explicit** | _(does not exist)_                     | **Goal**: Can see it, can change it     |

**Implicit and fixed** is the worst case. You cannot see `Logger` or `Database` in the signature, and you cannot swap them. This is the breeding ground for fragility -- hidden connections that break unexpectedly.

**Implicit and flexible** is what you get with mutable globals. You can change `config.retries` at runtime, so the dependency is flexible. But you cannot see that `makeRequest` depends on `config` by reading its signature. Any code anywhere can modify `config`, and the function's behavior depends on what happened before the call. This can actually be worse than the fixed case -- you have the illusion of flexibility without any clarity about what depends on what.

**Explicit and fixed** does not exist. Think about it: if a dependency is explicit -- it appears in the constructor signature -- then the caller _provides_ it. And if the caller provides it, they can provide different things. That is flexibility by definition.

```
class OrderService:
  constructor(calculator: TaxCalculator):  // explicit...
    this.calculator = calculator

// But now the caller can provide anything:
service1 = new OrderService(new USTaxCalculator())
service2 = new OrderService(new UKTaxCalculator())
```

Even if the constructor takes a concrete type instead of an interface, the caller still chooses _which instance_. The moment you force the user to provide a dependency, you have made it flexible. This is why there are only three meaningful combinations.

**Explicit and flexible** is the goal. The dependency appears in the constructor. The implementation is received rather than created. You can see it, mock it, swap it. This is what dependency injection achieves.

---

## Why Two Properties If One Implies the Other?

If explicitness implies flexibility, why bother talking about two separate properties? Because the argument _for_ each one lands differently, and the path from flexibility to explicitness is not as obvious as it seems.

**Explicitness is the weaker argument.** Many developers will push back. "Why should I care what database the service uses? That is an implementation detail. Hide it. Encapsulate it." This is the traditional OOP encapsulation argument, and it sounds reasonable on the surface. Plenty of experienced engineers will tell you that good code _hides_ its dependencies, not exposes them.

**Flexibility is the stronger argument.** Almost no one argues against the ability to swap implementations. "I want to test this without a real database." "I want to use a different payment processor in staging." "I want to mock this for local development." These are practical needs that everyone understands and agrees with.

So start with flexibility. Everyone wants it. The question is: how do you get it?

There are two roads to flexible dependencies. The first is mutable globals:

```
var emailClient = new SmtpClient()

function sendWelcome(user):
  emailClient.send(user.email, "Welcome!")

// In tests:
emailClient = new MockEmailClient()    // swap it out
sendWelcome(testUser)
```

This works. The dependency is flexible -- you can swap `emailClient` before calling `sendWelcome`. You can use a real SMTP client in production and a mock in tests. Flexibility achieved.

But now you have mutable global state. Any code anywhere can reassign `emailClient` at any time. The function's behavior depends on what happened to the global _before_ the call. You are back to temporal coupling -- the combinatorial explosion from [Part 4](./part-4-functional-thinking.md). In a real codebase, this leads to test pollution (one test swaps the global, forgets to reset it, the next test fails mysteriously), race conditions in concurrent code, and "who changed this?" debugging sessions.

[Part 4](./part-4-functional-thinking.md) makes the case that **immutability** is a property we need -- references should not change after they are set. If you accept that, then mutable globals are off the table. The global-swap route to flexibility is closed.

What is left? The only way to get flexible dependencies _without_ mutable state is to provide them at construction time:

```
class WelcomeService:
  private readonly client: IEmailClient

  constructor(client: IEmailClient):
    this.client = client

  sendWelcome(user):
    this.client.send(user.email, "Welcome!")
```

The dependency is flexible -- the caller chooses which client to provide. The reference is immutable -- it is set once in the constructor and never changes. And look: the dependency is now explicit in the constructor signature. You did not set out to make it explicit. You set out to make it flexible without mutable state, and explicitness was the inevitable result.

This is why we talk about two properties even though one implies the other. The _motivation_ is flexibility and immutability -- properties that everyone already wants. Explicitness is not a separate goal you must argue for. It is a _consequence_ of pursuing the other two. The developers who resist explicitness on principle will still end up with it if they pursue flexibility and immutability consistently.

---

## Quick Checklist

**Explicitness:**

- [ ] All collaborators appear in constructor signatures
- [ ] All per-call data appears in method parameters
- [ ] No implicit reads from globals, singletons, or static state
- [ ] Reading a constructor tells you everything a class needs
- [ ] Users of the class know all dependencies without reading implementation
- [ ] Implementers know all dependencies without knowing who calls them

**Flexibility:**

- [ ] Services depend on interfaces, not concrete implementations
- [ ] Dependencies are received, not created (no `new` in methods)
- [ ] No static method calls to access collaborators
- [ ] No singletons accessed globally

---

## What Comes Next

We have a model for thinking about dependencies. But how do we organize code so that dependencies are placed well? What belongs together? What belongs apart?

[Part 3: SOLID Principles](./part-3-solid-principles.md) gives us the rules. SOLID is not arbitrary -- each principle addresses a specific aspect of placing dependencies well. Single Responsibility governs cohesion. Dependency Inversion enables flexibility. Interface Segregation ensures explicitness is meaningful.

---

_Previous: [Part 1: Software Design Philosophy](./part-1-software-design-philosophy.md) | Next: [Part 3: SOLID Principles](./part-3-solid-principles.md)_

# Wiring It Together

**Part 7 of 8: The AtomiCloud Engineering Series**

_We have the architecture: three layers, mappers, pure domain. Now we need to actually build the thing. This part shows how services are constructed, how dependencies flow, and how the entire application comes together at a single point -- the composition root._

1. [Software Design Philosophy](./part-1-software-design-philosophy.md)
2. [The Dependency Model](./part-2-dependency-model.md)
3. [SOLID Principles](./part-3-solid-principles.md)
4. [Functional Thinking](./part-4-functional-thinking.md)
5. [Domain-Driven Design](./part-5-domain-driven-design.md)
6. [Three-Layer Architecture](./part-6-three-layer-architecture.md)
7. **Wiring It Together** (you are here)
8. [Testing and Testability](./part-8-testing-and-testability.md)

---

## Services as Stateless Objects

In [Part 5](./part-5-domain-driven-design.md), we established that there are two kinds of things: services (behavior) and structures (data). Now we need to talk about how services are actually built.

A service is a class with two kinds of members:

1. **Injected collaborators** -- interfaces to other services, repositories, clients
2. **Configuration** -- immutable values like timeouts, endpoints, feature flags

Both are set in the constructor and never changed. The service holds no mutable state.

```
class OrderService:
  private readonly repo: IOrderRepository
  private readonly pricing: IPricingService
  private readonly logger: ILogger
  private readonly maxItems: int

  constructor(repo: IOrderRepository, pricing: IPricingService, logger: ILogger, maxItems: int):
    this.repo = repo
    this.pricing = pricing
    this.logger = logger
    this.maxItems = maxItems

  create(record: OrderRecord): Result<Order, OrderError>:
    if record.items.length > this.maxItems:
      return Err(OrderError.TooManyItems)
    // ...
```

All state flows through method parameters and return values. The instance itself is frozen at construction.

This is the synthesis of OO structure and functional thinking from [Part 4](./part-4-functional-thinking.md): services are objects for **organization**, but their methods behave like pure functions that happen to have access to injected collaborators. You get the navigability and discoverability of OOP with the predictability of functional code.

---

## The Big Bang

Think about the universe. At the very beginning, there was a single moment -- the big bang -- where all the fundamental forces and particles came into existence. After that initial moment, the universe just... runs. Particles interact, stars form, galaxies emerge. The laws of physics do not change after the big bang; they were all established in that first instant.

The composition root is your application's big bang.

It is a single point -- `main()`, the application bootstrap, a DI container configuration -- where **every service in the system is created, wired together, and frozen**. After this moment, no new services are created. No dependencies change. The structure of the universe is set.

```
function main():
  // Layer 0: Infrastructure — the raw materials
  db = new PostgresDatabase(config.connectionString)
  httpClient = new HttpClientAdapter()
  logger = new ConsoleLogger()

  // Layer 1: Repositories — the outward layer takes shape
  userRepo = new UserRepository(db)
  orderRepo = new OrderRepository(db)

  // Layer 2: Domain services — the core comes to life
  userService = new UserService(userRepo, logger)
  orderService = new OrderService(orderRepo, userService, logger, config.maxItems)

  // Layer 3: Controllers — the inward layer connects to the outside
  userController = new UserController(userService)
  orderController = new OrderController(orderService)

  // Ignition — the universe starts running
  app = new Application(userController, orderController)
  app.run()
```

Read it top to bottom. Infrastructure first, then repositories, then services, then controllers. Each layer receives its dependencies from the layers above it. And then, at the very end, `app.run()` -- the moment the universe starts.

After that, **events drive everything**. An HTTP request arrives. The framework routes it to a controller. The controller calls a domain service. The service calls a repository. Data flows through the tree of services that was established at the big bang. Nothing is created on the fly. Nothing is resolved lazily. The entire structure was determined at startup.

This is powerful because it means the application's behavior is predictable. There are no surprises hidden in factory methods or service locators. No "oh, this service gets created the first time someone calls it, and depending on when that happens, it might get a different configuration." The entire dependency tree is visible, explicit, and frozen.

### Why a Single Point

The composition root is the **only place** that knows about concrete types. Everything else depends on interfaces. This gives you:

- **Visibility** -- the dependency graph is readable in one place
- **No hidden wiring** -- no `new` calls scattered through the codebase
- **Easy swapping** -- changing an implementation means changing one line here
- **Testability** -- tests can replace any layer by constructing a different tree

### Trees, Not Graphs

With this approach, the dependency graph is a **tree** rooted at the entry point. Each service receives its dependencies once, at construction, and those references never change. No lazy initialization. No conditional resolution. No ambient context.

Compare this to traditional OOP where object A creates object B inside a method, B grabs C from a static factory, C reads config from a global singleton. The dependency graph becomes a tangled web that you discover only by stepping through debuggers. Here, the entire tree is visible in `main()`.

### Laws and Matter

The physics analogy goes deeper than just the big bang moment. Think about what the universe actually contains after that initial instant.

There are **laws** -- gravity, electromagnetism, the strong and weak nuclear forces. These were established at the big bang and have not changed since. They are immutable. They govern how everything interacts -- how particles attract and repel, how energy transfers, how matter behaves -- but the laws themselves never change.

And there is **matter and energy** -- particles, atoms, molecules, radiation. These flow through the universe, constantly changing form. Hydrogen fuses into helium inside stars. Energy radiates outward as light. Molecules combine into complex structures and break apart again. Matter and energy are never created from nothing and never destroyed into nothing. They transform, rearrange, and recombine into endlessly new configurations -- all governed by the unchanging laws.

Our system works the same way.

**Services are the laws.** Established at the composition root, immutable thereafter. They define _how_ things interact -- validation rules, business logic, orchestration patterns, data transformations. A `PostService` always validates titles the same way. An `OrderService` always enforces the item limit the same way. They do not change during the lifetime of the application. They do not acquire new dependencies. They do not mutate their configuration. They simply _are_, and they govern.

**Data structures are the matter.** They flow through the system, constantly being transformed. An HTTP request body enters the system as raw JSON. The controller mapper shapes it into a domain Record. The service validates it, enriches it, runs it through business rules. The repository mapper reshapes it into a data model. It lands in a database as a row. At no point did a service conjure this data from nothing -- it arrived from the outside world and was transformed at every boundary, governed by the services it passed through. And when data leaves (as an API response, a notification, a log entry), it is the same information, reshaped once more for its destination.

After the big bang, the laws are set. Then events introduce matter into the system -- an HTTP request arrives, a message appears on a queue, a cron job fires. That data flows through the tree of services, being shaped and transformed at each node, until it reaches its final form. New requests bring new data. The services process it the same way every time, because the laws do not change. The complexity of the system comes not from the services themselves -- each one is simple -- but from their composition, the way data flows through many simple transformations to produce complex outcomes. Just as the staggering complexity of the physical universe emerges from a handful of unchanging laws applied to matter over time.

---

## Manual vs. Container

Some languages provide DI containers that automate wiring. You register interfaces and implementations, and the container resolves the dependency graph for you.

This is fine. The principle is the same: construct everything once, up front, at the root. The container is a more declarative way to express the same tree.

What matters is that the graph is **static, visible, and assembled before business logic runs**. Whether you write `new` calls yourself or let a container do it is a stylistic choice. Some teams prefer the explicitness of manual wiring (you can read the dependency tree like a story). Others prefer the convenience of containers (less boilerplate, automatic lifetime management). Both work.

The one thing to watch out for with containers is **magic**. If the container silently resolves dependencies through reflection and you cannot tell, by reading code, what gets injected where -- you have traded explicit wiring for implicit wiring, which undermines the whole point. A good container configuration should read almost as clearly as manual wiring.

---

## Quick Checklist

| Concern             | Check                                                   |
| ------------------- | ------------------------------------------------------- |
| Service members     | Only readonly members (injected collaborators + config) |
| Mutable state       | No mutable instance state on any service                |
| Composition root    | All services constructed at a single point              |
| Dependency graph    | A tree, visible in one place                            |
| Initialization      | No lazy initialization or conditional resolution        |
| After the big bang  | Events drive behavior; the service tree is frozen       |
| Framework isolation | Framework types isolated behind interfaces              |

---

## What Comes Next

The machine is built. All layers wired. The composition root assembles everything and the engine runs. Events flow in, data flows through, results flow out.

Now the question: how do you know it works?

[Part 8: Testing and Testability](./part-8-testing-and-testability.md) shows how the architecture we have built makes testing straightforward. The properties that make code testable are the same properties that make it changeable. This entire series has been building toward code that is easy to test -- not as an afterthought, but as the proof that the design works.

---

_Previous: [Part 6: Three-Layer Architecture](./part-6-three-layer-architecture.md) | Next: [Part 8: Testing and Testability](./part-8-testing-and-testability.md)_

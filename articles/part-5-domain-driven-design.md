# Domain-Driven Design

**Part 5 of 8: The AtomiCloud Engineering Series**

_We have principles for managing dependencies and patterns for writing predictable code. Now we pick up the actual material: your business domain. This part shows how to model domain concepts as code -- structures that speak the language of the business and remain pure from infrastructure._

1. [Software Design Philosophy](./part-1-software-design-philosophy.md)
2. [The Dependency Model](./part-2-dependency-model.md)
3. [SOLID Principles](./part-3-solid-principles.md)
4. [Functional Thinking](./part-4-functional-thinking.md)
5. **Domain-Driven Design** (you are here)
6. [Three-Layer Architecture](./part-6-three-layer-architecture.md)
7. [Wiring It Together](./part-7-wiring-it-together.md)
8. [Testing and Testability](./part-8-testing-and-testability.md)

---

## Start with the Domain

Imagine you are building a chess game.

The instinct -- especially if you have been coding for a while -- is to jump straight into the weeds. What GUI library? What framework? Should the board be a 2D array or a hashmap of coordinates? Do we need WebSockets for multiplayer? Should we use SQLite to persist game state?

Stop. None of that matters yet.

Think about what chess actually _is_. A board -- eight by eight squares, alternating colors. Pieces -- each type with its own movement rules. The knight jumps in an L-shape. The bishop slides diagonally. The rook moves in straight lines. There are special moves that trip up even experienced players: en passant, castling, pawn promotion. There is a turn system -- white moves first, then alternating. There is check, checkmate, stalemate, draw by repetition, the fifty-move rule.

All of this is pure logic. You can write it in code right now. You can build the data structures for the board, the pieces, the movement validation. You can write exhaustive tests for every edge case -- does castling work when the king has moved? Does en passant expire correctly? Does pawn promotion let you pick any piece? And you will have done all of this _without deciding a single thing about technology_. You will not know if this is a mobile app, a CLI tool, a web application, or a desktop app. You will not know if game state lives in memory, in SQLite, or in localStorage on the browser. You will not know if it is single-player, local multiplayer, or played over the network.

You do, however, have to commit to a programming language. That is the only technology decision the domain requires.

This is what "start with the domain" means. The domain is the logic -- the part that changes when the _requirements_ change, not when the infrastructure changes. Everything else is detail. Plugins. They can be decided later and swapped later.

Now, you might push back: "That is unrealistic. Of course I care about the database and the GUI framework. I need to make those decisions to build anything." And you are right -- you do care. But the point is not to _ignore_ those decisions. It is to design the domain so that those decisions do not leak into the core logic. When the PM says "we need to add a chess timer," that is a domain change -- you modify the domain code. When the DevOps team says "we are migrating from PostgreSQL to CockroachDB," that is an infrastructure change -- the domain should not know or care.

What you get from this discipline:

1. **Testability** -- domain logic tested with plain unit tests, no containers, no mocking of HTTP clients, no database setup
2. **Portability** -- the same domain can be served over REST today and gRPC tomorrow without touching a line of business logic
3. **Clarity** -- stakeholders can read the domain model and recognize their own concepts, because the code speaks the language of the business, not the language of the framework

---

## Ubiquitous Language

Every concept in your system deserves a precise name. Vague words breed bugs -- not the kind your linter catches, but the kind where two developers build the same feature differently because they understood the word differently.

Consider the word "user." In a platform that has both consumers and administrators, calling everyone "user" forces every developer to rely on context. The function signature says `user: User` and the reader has to guess which kind. Worse, sometimes they do not even realize they should guess -- they just assume, and they assume wrong.

Rename them. **ToolUser** and **EndUser**. Or **Admin** and **Customer**. Now the code is self-documenting. The compiler enforces the distinction. And the next person to join the team does not have to ask "which user do you mean?"

The rule is simple: **if two developers could reasonably disagree about what a name means, rename it.**

This goes deeper than you might expect. What does "staging" mean in your company? Is it the pre-production environment, or the QA environment? What does "graph" mean in your project -- nodes and vertices, or charts and visualizations? What are "chips" in your domain -- french fries or silicon? These ambiguities feel silly in isolation, but in a codebase with fifty contributors, they cause real confusion and real bugs.

Here is a trick that has served me well: for things like projects, environments, and infrastructure, **choose arbitrary names that carry no baggage**. I name my projects after atoms (Hydrogen, Helium, Lithium) and my environments after pokemon (Pikachu, Charmander, Bulbasaur). Why? Because projects change course and direction. A project called "Marketplace" that pivots to a subscription platform will confuse every new hire who wonders where the marketplace code went. A project called "Sulfur" never misleads because it never described anything in the first place. The name is a handle, not a description.

Ubiquitous language should be established hand-in-hand with the domain design phase and embedded directly in the code -- not in a wiki that nobody reads, but in the type names, function names, and module names that developers touch every day.

---

## Bounded Contexts

A bounded context is a sub-module -- a closed ecosystem where names have consistent meaning and the internals are hidden from the outside world. Inside the boundary, everyone agrees on what "Order" means. Outside, the same word might mean something completely different, and that is fine.

You can think of bounded contexts as **larger-scale versions of the classes we design with SOLID**. The same principles apply, just at a bigger scale:

| OOP Class                    | Bounded Context             |
| ---------------------------- | --------------------------- |
| Single responsibility        | Single business capability  |
| Dependencies via constructor | Dependencies via interfaces |
| No hidden globals            | No shared database tables   |
| Testable in isolation        | Testable in isolation       |

### The Mistake: Sharing Too Much

Here is where people get it wrong. Imagine an e-commerce system. Someone -- with the best intentions -- creates a single `Order` class and shares it across the entire codebase:

```
class Order:
  id: UUID
  customer: Customer
  items: OrderItem[]
  shippingAddress: Address
  paymentMethod: PaymentMethod
  total: Money
  tax: Money
  discount: Money
  status: OrderStatus
  trackingNumber: string?
  invoiceNumber: string?
```

Looks reasonable, right? One source of truth for what an order is. DRY. Clean.

Except this `Order` changes for many reasons:

- Marketing wants to add promotional codes
- Warehouse needs custom packaging options
- Finance needs tax breakdowns by jurisdiction
- Customer support needs cancellation reasons

Every change to any of these concerns forces a change to the `Order` class. You have high coupling at the architecture level -- the very thing we have been fighting against since Part 1.

### The Fix: Draw Boundaries

Split into bounded contexts, each with its own view of what an "order" is:

```
Billing Context:
  Order = { id, items, total, tax, discount, paymentMethod, invoiceNumber }

Shipping Context:
  Order = { id, items, shippingAddress, trackingNumber, packagingNotes }

CustomerSupport Context:
  Order = { id, status, cancellationReason, refundStatus }
```

Each context has its own `Order` type. They share the `id` for cross-referencing, but they do not share the full structure. A change to billing's `Order` does not affect shipping's `Order`. In modern systems, these might even be separate microservices owned by different teams.

### The Test: Can a Team Own It?

A practical test for whether your boundaries are right: **can you assign a single team to own this context?**

- **Billing** -- yes, the finance team owns this.
- **Shipping** -- yes, the logistics team owns this.
- **OrderManagement** -- maybe, but does it justify a separate team?

If you cannot name a team that would own a context, the boundary might be wrong. Bounded contexts should align with organizational boundaries. This is Conway's Law working in your favor instead of against you.

---

## Two Kinds of Things

Before we get into domain data modeling, we need to establish a fundamental distinction. In our system, there are exactly two kinds of things in code:

1. **Services** (objects with behavior)
2. **Structures** (pure data)

Services have behavior -- they orchestrate, they validate, they call other services. Structures are just data -- they carry information, they get passed around, they get transformed. The key rule is:

- **Services** depend on other services (via injection) and on configuration
- **Service methods** take structures as input and return structures as output

Think of it like a universe. You create all the services at the start, wiring them into each other -- the big bang moment (we will see this play out in detail in [Part 7](./part-7-wiring-it-together.md)). Once the universe is set up, you kick-start the engine. The services call each other, orchestrating the structures -- making the data move and dance through the system.

Why does this matter? In traditional OOP, objects bundle state and behavior together. A `User` object holds the user's data _and_ has methods that operate on it. This creates an unpredictable graph -- objects referencing objects, mutating each other's state, triggering cascades of side effects. You can never be sure what calling `user.updateEmail()` will do because it might reach into other objects and change their state too.

In our approach, services are immutable. Their members are set at construction and never change. They form a **tree**, not a graph. Service A uses service B and service C, and that relationship is fixed from the moment the application starts. Data flows through method parameters and return values, never stored on the service itself.

This distinction -- services orchestrate, structures flow -- shapes everything that follows.

---

## Records, Principals, and Aggregate Roots

Now we get to the domain data model. Traditional DDD gives us Value Objects, Entities, and Aggregate Roots. These are good concepts, but the original definitions get confusing in practice (especially "entities" -- in the data world, everything is an "entity"). More importantly, they were designed for domains with deep invariants. Most of what we build does not have deep invariants. Most of what we build has forms that create records, lists that display records, and relationships between records.

So we adapt the concepts and give them clearer names.

### The Original Concepts (Briefly)

In traditional DDD:

- **Value Objects** are defined by their attributes. Two `Money(10, USD)` objects are equal because they represent the same value. They have no identity.
- **Entities** have identity that persists across state changes. User #42 is still User #42 after they change their email.
- **Aggregate Roots** are consistency boundaries. An `Order` aggregate contains `OrderItem` entities. You never modify an `OrderItem` directly; you go through the `Order` aggregate root, which enforces invariants like "total must equal sum of items."

This works beautifully for complex domains. A banking system needs aggregate roots to enforce that debits and credits balance. A shipping system needs them to enforce that items cannot be added to a shipped order.

But let us be honest: most CRUD applications do not have invariants like that. They have forms, lists, and detail pages. For these, traditional aggregate roots add ceremony without payoff.

### What We Actually Need

Think about what a typical CRUD operation requires:

1. A type for **creation** that does not include the ID (the system generates it -- the user should not have to provide one)
2. A type for **updates** that excludes the ID (the ID identifies _which_ entity to update, it cannot be changed)
3. A type for **search results** that is cheap (single table, no joins -- you are listing potentially hundreds of results)
4. A type for **detail views** that includes related data (the full picture, with joins, for a single entity)

This leads us to three types: **Records**, **Principals**, and **Aggregate Roots**.

### Records (Pure Data, No Identity)

A Record is pure data with no identity. It contains every field that a create or update form would ask for.

```
PostRecord:
  title: string
  description: string
  tags: string[]

AuthorRecord:
  name: string
  dateOfBirth: date
```

Why no ID? Because at creation time, the ID does not exist yet. At update time, the ID is passed separately -- you are saying "update _this_ entity with _this_ data." The ID is not data you change; it is something you reference.

A good heuristic: **a Record contains every field that would appear on a create/update form.** The `id` is never on the form because the system assigns it.

Records also allow us to partition an entity into multiple segments with different update routes. You might have a `UserProfileRecord` for mutable profile data and a `UserSettingsRecord` for preferences -- both belonging to the same entity but changing at different rates and for different reasons.

### Principals (Records with Identity)

A Principal is a Record with identity -- the combination of an ID and the record data.

```
PostPrincipal:
  id: uuid
  record: PostRecord

AuthorPrincipal:
  id: uuid
  record: AuthorRecord
```

Post #42 is still post #42 after you edit the title. The identity persists across state changes. Principals map directly to database tables -- the primary key is the `id`, the columns come from the Record.

Sometimes you need more than just an `id` for identity -- maybe a `version` for optimistic concurrency, or a `createdAt` for audit purposes. The Principal is where those live. But the `id` is the baseline.

### Aggregate Roots (Assembled Views)

An Aggregate Root is a view that assembles a Principal with its related Principals. This is where relationships live.

```
Post:
  principal: PostPrincipal
  author: AuthorPrincipal

Author:
  principal: AuthorPrincipal
  posts: PostPrincipal[]
```

Notice that `Post` and `Author` are different aggregate roots that reference each other's principals. They are _views_ -- shaped by what the consuming service needs, not by some canonical structure. Different services might define different aggregate roots for the same principal.

This departs from traditional DDD where aggregate roots are consistency boundaries. In most CRUD applications, aggregate roots are **read models**. They assemble related data into useful shapes for specific use cases.

You might push back: "Isn't this just a DTO? Just a view model?" Honestly, yes -- but with a specific structure and naming convention that makes the entire team consistent. When someone says "the Post aggregate root," everyone knows it means the post principal plus its related data. That consistency has value.

---

## CRUD Mapping

With these three types defined, the standard CRUD operations fall out naturally. And the mapping is not arbitrary -- each choice has a specific reason rooted in what the operation actually does.

**Search returns Principals.** When you are listing posts -- showing 50, 100, maybe 500 results -- you do not need every related entity. You need the post's own data: title, description, maybe a tag count. That is a single-table query, fast and cheap. Returning full aggregate roots would mean joining against the author table for every single result. For a search page, that is unnecessary and expensive.

```
search(params: PostSearch) => PostPrincipal[]
```

**Get returns an Aggregate Root.** When you are viewing a single post, you want the full picture: the post itself, its author, maybe its comments. This is a detail view, and a few joins for one entity are perfectly fine. This is where the aggregate root earns its keep.

```
get(id: uuid) => Post?
```

**Create takes a Record.** The user does not know the ID at creation time -- the system assigns one. So the input is just the data: title, description, tags. You get back an Aggregate Root so the UI can immediately display the newly created post with all its context, without needing a second round-trip.

```
create(record: PostRecord) => Post
```

**Update takes an ID and a Record separately.** Why separate? Because the ID identifies _which_ entity to update, and the Record is _what_ to update it with. The ID is immutable -- you cannot change which post you are editing mid-update. By keeping them separate, the contract makes this explicit. And since the entire Record is replaced, there is no ambiguity about partial updates.

```
update(id: uuid, record: PostRecord) => Post?
```

**Delete takes an ID.** That is all you need. Nothing to return.

```
delete(id: uuid) => void
```

### The Summary Table

| Operation  | Input          | Output          | DB Cost                  | Why                                    |
| ---------- | -------------- | --------------- | ------------------------ | -------------------------------------- |
| **Search** | Search params  | `Principal[]`   | Single table, no joins   | Lists need volume, not detail          |
| **Get**    | `id`           | `AggregateRoot` | Joins (one entity)       | Detail view needs full picture         |
| **Create** | `Record`       | `AggregateRoot` | Insert + read-back joins | No ID at creation time                 |
| **Update** | `id`, `Record` | `AggregateRoot` | Update + read-back joins | Identity is immutable, data is mutable |
| **Delete** | `id`           | `void`          | Single table delete      | Nothing to return                      |

### Why This Lands Well with Relational Databases

This is not just a clean API design -- it maps beautifully to how relational databases actually work.

Principals map directly to tables. A `PostPrincipal` is a row in the `posts` table: primary key is the `id`, columns come from the Record fields. An `AuthorPrincipal` is a row in the `authors` table. One entity, one table. Clean.

Aggregate Roots map to joins. The `Post` aggregate root (post + its author) is a `SELECT ... JOIN authors ON ...`. The `Author` aggregate root (author + their posts) is the reverse join. Different aggregate roots are just different join queries over the same underlying tables.

Records map to inserts and updates. Since a Record has no ID, `INSERT INTO posts (title, description, tags) VALUES (...)` is a direct mapping -- the database generates the ID. For updates, `UPDATE posts SET title = ?, description = ?, tags = ? WHERE id = ?` is equally direct -- the ID in the WHERE clause, the Record fields in the SET clause.

And here is where performance comes in. Search returns Principals -- that is a single-table query with no joins. When you are listing 100 posts on a search page, you hit one table, one index scan. Fast. If search returned Aggregate Roots instead, you would be joining against `authors` (and possibly `comments`, `tags`, etc.) for every single row. For a list page, that is wasted work.

Get returns an Aggregate Root -- but only for one entity. A few joins to assemble one post with its author is trivial for any relational database. The cost is constant, not proportional to result count.

This split -- cheap queries for lists, rich queries for detail views -- is exactly how relational databases are designed to be used. The domain model and the database model are not fighting each other; they are working together.

### The Service Interface

Putting it all together:

```
interface PostService:
  search(params: PostSearch): Result<PostPrincipal[], PostError>
  get(id: uuid): Result<Post?, PostError>
  create(record: PostRecord): Result<Post, PostError>
  update(id: uuid, record: PostRecord): Result<Post?, PostError>
  delete(id: uuid): Result<void, PostError>
```

Once you have seen this pattern for one entity, you have seen it for all. `UserService`, `ConfigurationService`, `HabitService` -- they follow the same shape. A new team member learns the pattern once and can navigate any module in the codebase.

We do not _have_ to do it this way. Some domains genuinely need different patterns -- event sourcing, CQRS, complex workflows with state machines. But for the vast majority of CRUD web applications, this makes things consistent, performant, and predictable. And consistency, it turns out, is one of the most underrated features of a codebase.

---

## Quick Checklist

| Concern                | Check                                                                                        |
| ---------------------- | -------------------------------------------------------------------------------------------- |
| Domain isolation       | Zero imports from HTTP, database, or framework packages                                      |
| Ubiquitous language    | Every concept has a precise, unambiguous name                                                |
| Bounded contexts       | Modules own their types, no cross-imports of internals, boundaries align with team ownership |
| Two kinds of things    | Services have behavior, structures are pure data                                             |
| Records                | Every entity has a Record with updateable fields (no ID)                                     |
| Principals             | Every entity has a Principal with identity + Record                                          |
| Aggregate roots        | Views assemble related Principals for specific use cases                                     |
| CRUD mapping           | Search returns Principals; Get/Create/Update return Aggregate Roots                          |
| No identity in Records | `id` lives in Principal only                                                                 |

---

## What Comes Next

The domain is designed. We have Records, Principals, Aggregate Roots, and service interfaces that speak the language of the business. The domain is pure, testable, and unaware of the outside world.

But it is also useless on its own. A chess engine that cannot display a board or save a game is just an exercise. We need to connect the domain to reality -- databases, APIs, user interfaces -- without compromising its purity.

[Part 6: Three-Layer Architecture](./part-6-three-layer-architecture.md) shows how to wrap the domain in layers that handle the messy world while keeping the core clean.

---

_Previous: [Part 4: Functional Thinking](./part-4-functional-thinking.md) | Next: [Part 6: Three-Layer Architecture](./part-6-three-layer-architecture.md)_

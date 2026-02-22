# Domain-Driven Design

We adopt DDD's proven tactical patterns while discarding the ceremony. You will not find event-sourcing sagas, domain events, or specification objects here. What you will find is a practical, opinionated structure for modelling your domain that keeps code clean, testable, and easy to change.

This article builds on the foundation laid by [Software Design Philosophy](../software-design-philosophy/index.md), [SOLID Principles](../solid-principles/index.md), [Functional Practices](../functional-practices/index.md), [Stateless OOP with Dependency Injection](../stateless-oop-di/index.md), and [Three-Layer Architecture](../three-layer-architecture/index.md). Read those first if you have not already.

---

## Start with the Domain

Before you choose a framework, before you pick a database, before you draw an API schema -- design your domain in pure code.

Imagine you are building a chess game. You would start by defining the board, the pieces, the rules of movement, the turn system, and the scoring logic. All of this can be written in code and tested without ever deciding whether the game runs as a mobile app, a CLI, or a web application. You do not need a database to know that a bishop moves diagonally.

This is the principle: **commit to a programming language, but do not let the domain assume infrastructure.** The domain layer should contain zero references to HTTP, SQL, file systems, or any external service. It is pure logic operating on pure data.

When you design domain-first, you get three things for free:

1. **Testability.** Domain logic is exercised with plain unit tests -- no containers, no mocking frameworks, no network calls.
2. **Portability.** The same domain can be served over REST today and gRPC tomorrow. It can persist to PostgreSQL or DynamoDB. The domain does not care.
3. **Clarity.** Stakeholders can read the domain model and recognise their business concepts without wading through serialisation annotations and ORM decorators.

---

## Ubiquitous Language

Every concept in your system deserves a proper noun. Vague words breed confusion and subtle bugs.

Consider the word "user." In a platform that has both end-consumers and tool-administrators, calling both "user" forces every developer to rely on context to guess which one a piece of code refers to. Rename them: **ToolUser** and **EndUser**. Now the code is self-documenting. A function that accepts a `ToolUser` cannot accidentally receive an `EndUser`, and every code review becomes clearer.

Ubiquitous language extends beyond domain types. AtomiCloud uses arbitrary names for cross-cutting concepts precisely to avoid overloaded terms:

- **Chemical elements** for projects (hydrogen, helium, lithium)
- **Pokemon** for environments (pikachu, charmander, squirtle)

These names carry no pre-existing baggage. Nobody confuses "pikachu" with the word "production" -- and that is the point. When a name has exactly one meaning in your codebase, ambiguity disappears.

**The rule:** If two developers could reasonably disagree about what a name means, rename it.

---

## Bounded Context: Bigger OOPs

A bounded context is a sub-module that operates as a closed ecosystem. Inside its boundary, the ubiquitous language is consistent and unambiguous. Outside, the same word may mean something different entirely.

Think of bounded contexts as **larger-scale versions of the classes we write in OOP**. The same principles apply:

| OOP Class                    | Bounded Context             |
| ---------------------------- | --------------------------- |
| Single responsibility        | Single business capability  |
| Dependencies via constructor | Dependencies via interfaces |
| No hidden globals            | No shared database tables   |
| Testable in isolation        | Testable in isolation       |

### The Mistake: Sharing Too Much

Imagine an e-commerce system. Someone creates a single `Order` class used by everything:

```
// The monolithic Order
class Order
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

The `Order` changes for many reasons:

- Marketing wants to add promotional codes
- Warehouse needs custom packaging options
- Finance needs tax breakdowns by jurisdiction
- Customer support needs cancellation reasons

Every change to any of these concerns forces a change to the `Order` class. This is **high coupling** at the architecture level.

### The Fix: Draw Boundaries

Split into bounded contexts:

```
Billing Context:
  Order = { id, items, total, tax, discount, paymentMethod, invoiceNumber }

Shipping Context:
  Order = { id, items, shippingAddress, trackingNumber, packagingNotes }

CustomerSupport Context:
  Order = { id, status, cancellationReason, refundStatus }
```

Each context has its own `Order` type. They share the `id` (and perhaps reference each other), but they do not share the full structure. A change to billing's `Order` does not affect shipping's `Order`.

### The Challenge: Where Do You Draw the Line?

Here is a test: can you assign a single team to own this context?

- **Billing** -- yes, the finance team owns this.
- **Shipping** -- yes, the logistics team owns this.
- **OrderManagement** -- maybe, but does it justify a separate team?

If you cannot name a team that would own a context, the boundary might be wrong. Bounded contexts align with organizational boundaries. This is Conway's Law working in your favor.

### Positive Example: Clear Boundaries

```
UserService:
  - Owns user identity, authentication, preferences
  - Database: users table
  - API: /users/*

NotificationService:
  - Owns email, push, SMS sending
  - Database: notifications, templates tables
  - API: /notifications/*
  - Depends on: UserService (to look up contact info)
```

Two teams, two databases, two deployable units. A bug in notifications does not affect user login.

### Negative Example: Leaky Boundaries

```
OrderService:
  - Owns orders
  - Database: orders, order_items, shipping_addresses, invoices, payments

PaymentService:
  - Owns payments
  - Database: payments (with foreign key to orders!)
  - Directly queries orders table for status
```

This is a distributed monolith. A schema change to `orders` breaks both services. You have not achieved independence; you have achieved complexity without benefit.

---

## Two Classes of Things

Everything in a codebase falls into one of two categories:

| Category       | Also Known As | Has Behaviour? | Has Identity?  | Injected?               |
| -------------- | ------------- | -------------- | -------------- | ----------------------- |
| **Objects**    | Services      | Yes            | No (stateless) | Yes, via constructor    |
| **Structures** | Data, Models  | No             | Sometimes      | No, passed as arguments |

**Objects** are services. They contain behaviour -- business logic, orchestration, validation. They receive other services (and configuration) through constructor injection. They are stateless: no mutable fields, no hidden state.

**Structures** are pure data. They carry properties but no behaviour. They are immutable containers that flow through the system as method arguments and return values.

The contract is simple: **service methods take structures as input and return structures as output.** Services never accept other services as method arguments -- those come through the constructor. Structures never depend on services -- they are inert data.

This separation is what makes the entire architecture testable and composable. Services can be swapped via dependency injection. Structures can be compared, serialised, and asserted against.

See [Stateless OOP and Dependency Injection](../stateless-oop-di/index.md) for the full treatment of this distinction.

---

## Records, Principals, and Aggregate Roots

With the two-class distinction established, we now define three levels of structure that appear in every CRUD-oriented domain. These correspond loosely to DDD's value objects, entities, and aggregate roots -- but with important differences.

### The Original DDD Concepts

In traditional Domain-Driven Design:

- **Value Objects** are defined by their attributes. Two `Money(10, USD)` objects are equal because they represent the same value. They have no identity.
- **Entities** have identity that persists across state changes. User #42 is still User #42 after they change their email.
- **Aggregate Roots** are consistency boundaries. An `Order` aggregate contains `OrderItem` entities. You never modify an `OrderItem` directly; you go through the `Order` aggregate root, which enforces invariants.

This model works beautifully for complex domains with deep invariants. A banking system needs aggregate roots to enforce that debits and credits balance. A shipping system needs aggregate roots to enforce that items cannot be added to a shipped order.

### Why We Departed

Most CRUD applications do not have deep invariants. They have:

- Forms that create and update records
- Lists that search and display records
- Relationships between records that are queried independently

For these use cases, traditional aggregate roots add ceremony without benefit. What we do need is:

1. **A type for creation that excludes the ID** (the ID is generated by the system)
2. **A type for updates that excludes the ID** (the ID cannot be changed)
3. **A type for search results that is cheap** (single table, no joins)
4. **A type for detail views that includes related data** (joins, full picture)

This leads us to a different three-type model: **Records, Principals, and Aggregate Roots**.

### Records (Updateable Data)

A Record is a structure with no identity. It contains every field that a Create or Update form would ask for.

```
PostRecord:
  title: string
  description: string
  tags: string[]

AuthorRecord:
  name: string
  date_of_birth: date
```

Records deliberately exclude the identifier because:

- **At creation time**, the ID does not exist yet
- **At update time**, the ID is passed separately (it cannot be changed)
- **Identity is not data you change -- it is something you reference**

### Principals (Records with Identity)

A Principal is a Record with an ID. It represents the entity as stored in a database.

```
PostPrincipal:
  id: uuid
  record: PostRecord

AuthorPrincipal:
  id: uuid
  record: AuthorRecord
```

The identity makes a Principal unique even when its record data changes. Post #42 is still post #42 after you edit the title. This is the fundamental distinction between a Record and a Principal.

Principals are the **primary unit of storage and retrieval**. A database table maps directly to a Principal: the primary key is the `id`, and the remaining columns come from the Record.

### Aggregate Roots (Assembled Views)

An Aggregate Root is a view that shows a Principal together with its related Principals. It represents the **full picture** of a concept as needed by a particular use-case.

```
Post:                    // Aggregate root for viewing a post
  principal: PostPrincipal
  author: AuthorPrincipal

Author:                  // Aggregate root for viewing an author
  principal: AuthorPrincipal
  posts: PostPrincipal[]
```

Notice that `Post` and `Author` are two different aggregate roots that reference each other's principals. They are **views** -- shaped by what the consuming service needs.

### Why This Split Works

| Operation  | Input          | Output          | Why?                                               |
| ---------- | -------------- | --------------- | -------------------------------------------------- |
| **Search** | Search params  | `Principal[]`   | Single table, no joins, fast for lists             |
| **Get**    | `id`           | `AggregateRoot` | Full view with related data                        |
| **Create** | `Record`       | `AggregateRoot` | No ID needed -- system generates it                |
| **Update** | `id`, `Record` | `AggregateRoot` | ID is separate because identity cannot be replaced |
| **Delete** | `id`           | `void`          | Nothing to return                                  |

**Search returns Principals** because lists do not need related data. Returning Principals keeps search fast with single-table queries.

**Get returns an Aggregate Root** because detail views need the full picture: the post and its author, the order and its line items.

**Create takes a Record** because at creation time, the entity has no identity. The system assigns one.

**Update takes ID and Record separately** to make the contract explicit: identity is immutable, data is mutable.

---

## CRUD Mapping (Blessed Path)

With three structure types defined, we can map the five standard CRUD operations to the types they consume and produce.

### Service Interface Example

```
interface PostService:
  search(params: PostSearch): Result<PostPrincipal[]>
  get(id: uuid): Result<Post?>
  create(record: PostRecord): Result<Post>
  update(id: uuid, record: PostRecord): Result<Post?>
  delete(id: uuid): Result<void?>
```

And the corresponding repository interface follows the same shape:

```
interface PostRepository:
  search(params: PostSearch): Result<PostPrincipal[]>
  get(id: uuid): Result<Post?>
  create(record: PostRecord): Result<Post>
  update(id: uuid, record: PostRecord): Result<Post?>
  delete(id: uuid): Result<void?>
```

The service orchestrates business rules; the repository handles persistence. Both speak the same language of Records, Principals, and Aggregate Roots. See [Three-Layer Architecture](../three-layer-architecture/index.md) for how these layers connect.

---

## Quick Checklist

Before calling a domain complete, verify:

- [ ] **Domain isolation.** The domain module has zero imports from HTTP, database, or framework packages.
- [ ] **Ubiquitous language.** Every concept has a precise, unambiguous name. No overloaded terms.
- [ ] **Bounded contexts.** Each module owns its types. No cross-module imports of internal models. Boundaries align with team ownership.
- [ ] **Two classes.** Services have behaviour and receive dependencies via constructor. Structures are pure data passed as arguments.
- [ ] **Records defined.** Every entity has a Record containing its updateable fields (no ID).
- [ ] **Principals defined.** Every entity has a Principal combining its identity with its Record.
- [ ] **Aggregate roots defined.** Every entity that needs related data has an Aggregate Root assembling the relevant Principals.
- [ ] **CRUD mapping followed.** Search returns Principals. Get/Create/Update return Aggregate Roots. Delete returns nothing.
- [ ] **No identity in Records.** The `id` field lives in the Principal, never in the Record.
- [ ] **Aggregate roots as views.** Different services may define different aggregate roots for the same Principal, each shaped to its needs.

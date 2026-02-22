# Goal as a Software

The most important thing about software is the ability to be easy to change. Pure-hardware and other automations can also perform the same thing, what makes software so much better and so much lucrative is due to the fact that its EASY TO CHANGE. it allows growth and evolution in a fast pace.

## High Level Goals

### Low Couple High Cohesion

SOLID's main goal is to achieve Low Coupling and High Cohesion. These two properities and the main tension when writing software, on making it "how easy to change" it is. at glance, it might seem like they are contradictary, but in actual fact they work together

Low coupling reduce fragility (you want to change something, many similar things are accidentally changed because they are coupled), but it also if the coupling is too low, then it also duplicates logic (1 change need to be propagate many places), which is error prone too

High Cohesion reduces rigidity (you want to change something, but need to change in 10 different places), because things that are related strictly should change at the same rate.

### Dependencies

The source of all problem are dependencies - everything is an dependency (variables, function calls, arguments). If function A uses function B, then function A depends on function B. This couple A with B, whether you like it or not. or god forbids function A uses a global variable, and somewhere else, function Z also uses the global variable, and now, function A and function Z are linked together (they affect each other)!

To achieve low cohesion and high coupling, we need to manage dependency. To deoucple all dependency, like mentioned previously, it unfeasible, it will make the system tiresome and cubersome, and defeats the goal of software itself.

To merge all these concepts together, we need to correct group and manage dependencies to achieve the highest cohesion and lowest coupling. These rules can be used as a rule of thumb to achieve it.

## SOLID Principles

### S - SRP

Reason to change is defined as cause of change. Another metric for a single "responsibility" is the rate of change (they change at the same rate, then you group them together). SRP governs what is "high-cohesion" -- when do you put things together in a service? the answer is, if they mostly change at the same rate, or same external reason, then its a single class. For example, lets say we have "create", "delete" and "get" customer from a class, and this is used in CLI to perform CRUD customer into JSON file. the get should not return the ASCII format, since that will have too much work in get, so we return a generic structure of what a custom is, and have a`render` function:

```
class CustomerService {
	get(id) -> Cus;
	delete(id) -> void;
	create(details) -> Cus;
	render(cus) -> string;
}
```

In this case, get, delete and create change the same rate, usually when i change one, i will change the other. but render changes at different rate (and reason). The reason why we change get/delete/create has to do with the domain lifecycle of customers, but the reason why we change render is due to how we want to see the customer data. As such, this should be split into CustomerService and CustomerRenderer.

The corollary is that is abit far out is that we no longer private methods, all methods should be public (SRP Corollary). The reason for this is that the idea of private is encapsulation, its to break down complex into smaller hidden function that the main system exposes. in this for example, the typical usage of private is as such:

```
public class Complex {
	public complexFunc() {
		...
		...
		...
	}
}
```

is typically broken down into:

```
public class Complex {
	public compelxFunc() {
		simpleA();
		simpleB();
	}

	private simpleA() {
	}
	private simpleB() {
	}
}
```

this allows user to "encapsulate" the complexity and hide it. but private causes many issues, include hiding from test, hard to breakdown etc.

follow SRP, simpleA and simpleB will technically be another object, injected into complex, with them as public method, re-worked to be generic and fulfil its class purpose's purpose.

for a detailed example

```
public class passwordchecker {

	public isValid(password) {
		const hasAlpha = this.hasAlpha(password);
		const hasSpecial = this.hasSpecial(password);
		return hasAlpha && has Special;
	}
	...
}
```

technically, you can put hasAlpha and hasSpecial into a "StringHelper" or "StringChecker" class, which objects of it will provide the function. this brings in even more benefits of being able to optimize them by subsituting the object (without breakin the passwordchecker). for example, and original one that uses regex, but the in future, someone thought of a token-based parser, which makes it faster, can swap it in without ever touching passwordchecker class and tests (since the stringchecker class would be mocked). This ties in closely with OCE and DIP

### OCE - Open Close Principle

Open to extension, close to modification. This is pertains specifically to low coupling -- open close principle means to allowing changing the behaviour of an peice of code without changing the piece of code. This can change from very simple to very complex examples. The simplest example is an function or method argument. Consider:

```
function addClosed(a: number): number {
	return a + 5;
}

function addOpened(a: number, b: number): number {
	return a + b;
}
```

In the above example, `addOpen` is more open to than close to extension, because now we can change the behaviour MORE, without changing the function itself, relative to `addClosed`. To bring is idea further, we can use higher order function to make addOpened even more opened:

```
function addEvenMoreOpened(a: number, b: number, add: (number,number)=>number): number {
	return add(a,b);
}
```

This allows us to modify how the add is performed, without changing the code even! do note that there are limits to this, else the addEvenMoreOpened function just becomes a language. It is indeed an art to decide how much to open it up, and how much to seal it. This ties in completely with SRP -- this is the final part of the trick -- how much do we actually move to arguments?

OOP's class-style and interface gives us a good tool and standard to operate as opposed to functional-styled writing. while typically functionally style writing allows for higher quality code, it is TOO powerful and too free. arguments can be functions of function of higher order types or functions, which allows anyone to do anything, resulting in thousands of layers in any order they deem fit. OOP provides a more restricted framework, which we can leverage as a guideline on "what to open up": interfaces.

This is what makes up a class, consider writing a git wrapper:

```
git_add(git_binary: string, repo_path: string, target: string) {
 ...
}

git_rm(git_binary: string, repo_path: string, target: string) {
 ...
}

git_commit(git_binary: string, repo_path: string, commit_msg: string) {
 ...
}

```

this is pretty cumbersome, to allow users to be able to change the `git_binary` and `repo_path`, we are looking at making the library more "open" to extension! but this is tiring, each time we call, we have to make sure we use the same variable.

What we can do, it group them together -- and thus an object in born. unlike traditional OOP, we should treat class members either as config or DI containers -- it MUST be immutable:

```
class Git {
	git_binary: string
	repo: string

	add(target: string) {
	    ...
	}

	rm(target: string) {
		...
	}

	commit(msg: string) {
		...
	}
}
```

in OCE, what is important is we control at which stage, do we allow the extension. in this example, relating to SRE, since all of them will be working on the same repo and binary, we should, then group them together into 1 class, since they change for the same reason AND rate.

if we want to take it seriously, there should be two classes, Git and GitRepo, where git holds the git binary, and git repo, takes in Git and repo string.

lastly, injection needs to be swappable. for typical static structs/configs, it simple. Injecting functions comes with a neat feature, as long as function signature match, we can always swap it out. but what about objects in a strongly, non-structurally typed system? Interfaces are need.

In this case, be it injected in method behaviour or constructor, the asker should always ask for an interface, the contract itself. this allow users of the class or function to change out the implementation without modifying the class or function, achieving OCE practically.

OCE is about dependency injection -- this can be injected at constructor, as higher order functions, arguments etc, but the true principle here is knowing WHEN and WHERE to inject, with interfaces abstracting dependency and follow SRP to group dependencies from methods to classes.

In my opinion, using higher order function, while powerful, complicates analysis. methods should always take is value-types, if it wants to take in behaviour type, its better if the constructor takes in another object, and we use that object that way.

### LSP - Liskov Substitution Principle

LSP is more of a constraint and warning than a principle, to help us out in this whole system. In essence, all the other principles rely alot on interfaces, and underneath it, being substitutable. LSP essentially states that anything that are substitutable should not break the contract of the interface.

This can materialize in lots of ways - the most typical example is sub-classing (Extend) and this is highly discouraged. by overriding parent's behaviour, the chance of voilating LSP is high.

One important concept for LSP is the idea of runtime hierarchy and design time hierarchy. This is one of the most confusing concept and the primary violation of LSP.

class/interfaces/types are ideas/concepts, and technically don't exist at runtime. with inheritance and interface implementation, and union types, we can build a hierarchy or graph around the types. This graph governs how do the concepts relate to each other.

objects, on the other hand are real, and interact with other objects at runtime. they call each other, hold reference to each other. we can also build a hierarchy or graph over the runtime objects. for those that can't imagine this difference, you can view it as how a dog and a human's (they often live together, and humans directly take care of dogs) relation in reality differs when we are analyzing the difference between the concept of a dog and a concept of a human (they have no direct relationship, but share a common evolution ancestor).

a classic example from uncle bob with square and rectangle can be used to illustrate the problem that result in ISP violations:

```
class Rect {
	number length;
	number width;

	area() {
		return length * width;
	}

	setLength(l) {
		length = l
	}

	setWidth(w) {
		width = w
	}
}

class Square extends Rect {
	@override
	setLength(l) {
		length = l;
		width = l;
	}

	@override
	setWidth(w) {
		length = w;
		width = w;
	}
}

```

this classic example shows you how LSP breaks, since Square is a subtype of Rect, it should, replace Rect without any issues, completely agree-ing and implementing all the contract that Rect promises.

When looking at the design of the class, if using real-life logic on "a square is rectangle with equal sides!" idea, the class seems to make sense, and it embodies that within the code arguably elegantly.

Consider this usage that shows how it breaks:

```
const r = factory.newRectOrSquare();

r.setLength(5);
r.setWidth(8);

r.area(); # this should print 40. but if the "r" is a square, the result would be 64! this completely violates LSP as a square results in a different expected behaviour fromm when we mean a "sqaure" is a "rect"

```

Skipping on other glaring error of the design of the rectangle class (such as it being mutable, have void return types, having implicit behaviour etc), there are 2 key take aways, one is more straight forward and the other more nuanced, allowing us understand the crux of LSP constraint in OOP systems:

1. LSP is about what the interface/supertype promises, including implicit behaviour (what happened here, it is implied that setLength and setWidth will affect area). As such, we need to be clear when we define the interface, and ensure nothing below will be leaked up. This is typical good software engineering practice, like no globals, no mutable states etc when designing the interface, allowing sub-types to be easily swapped in
2. The reason why the class, although it seems to make sense intuitively, broke, it because we were conflating the relationship. Classes are concept. The concept of a square is NOT a concept of a rectangle. The concept of the square is 4 right angles, 2 sets of parrallel sides, 4 straight equal sides. The concept of a rectangle is 4 right angles, 2 sets of parrallel sides, and 4 straight sides. they are both overlapping but not strictly overlapping concepts. In reality, a square is always a rectangle, but the concept of a square is never the concept of a rectangle. much like how dogs and humans interact directly in realife, and its "basically family", the the concept of a dog and concept of humans are far apart.

### ISP - Interface Segregation Principle

From OCE and SRP, we discuss about high cohesion and low coupling, and those hinged on interface alot. ISP is one of the things that is about interfaces. Interfaces are generally on the designed on how the user use it. a object doesn't only implement 1 interface, it can implement multiple interfaces, and 1 interface is 1 way to see the class itself.

> ISP can be seen as similar to SRP for interfaces; but it is more than that. ISP generalizes into: “Don’t depend on more than you need.” SRP generalizes to “Gather together things that change for the same reasons and at the same times.”
>
> Imagine a stack class with both push and pop. Imagine a client that only pushes. If that client depends upon the stack interface, it depends upon pop, which it does not need. SRP would not separate push from pop; ISP would.

ISP is important as we design interfaces first and a separate rule from SRP because it highlights the difference between usage (interface) and implementation (classes).

### DIP - Dependency Inversion Principle

While this is the last, its the core principle that binds everything together. From the start, I have mentioned that dependencies is the root of all evil - to manage them, we can get cleaner code. DIP is the core tenet that brings that to life.

Previously, I mentioned that when function A calls function B, function A depends on function B. this means that A is coupled to B, and when B changes, it in evitably changes A (even if you don't want to), and wanting to change A, you may have to change B. This coupling make it as if you might as well put them into 1 function.

This is especially troublesome when A uses B and C uses B. If B changes for a new things A needs, C is impacted. If C needs a change on B, we need to consider how it impacts A. This is the core problem of dependency.

To fix this problem, the code itself doesn't really change at small scale. dependency inversion simply adds a layer/interface (lets call it X) between the two function. Instead of A depending on B, A now depends on the interface X and B fulfils the interface X. this way, even if C wants to use B, it needs to create an interface Y, and B needs to fulfil both interface X and Y. if it can't we can split the underly function into 2, and A and C won't be impacted.

You can see that the dependency inverted:

```
A => B

to

A => X <= B
```

This then spawns the need for ISP and LSP, and how OCE can be implemented, and how SRP can be achieved.

## Domain Driven Design

With the goals and generic software principle marked down we can apply it to typical business apps. Previously, all rules are abstract, and apply generally true to most software. Domain Driven Design (DDD) brings in how it works with business and non business teams. In the context of business software, we can add rules, build frameworks and allow us to build quickly without thinking of what is good code by having general rule of thumbs.

The full idea is dated and complex, and in my opinion does not benefit much, but we can distill and extract certain concepts and ideas to help us out. The key concepts that are important are:

1. Start with the Domain
2. Ubiquitous Language
3. Bounded Context
4. Entities, Value Objects, and Aggregates (implementing)

## Start with the Domain

When designing, we design the domain. This means we look at the logic agnostic to technology. A good example will be a chess game. Traditional software will just get into the weeds and start with the chess board graphics, movement rules, and board state. In Domain driven design, those are details. The domain is the chess game -- it doesn't even have to be in code! It can exist anywhere. As such, we should map out a pure domain that doesn't assume anything about the technology its going to run on.

This should include:

- Data structure of chess
- Movement logic
- Scoring Logic
- Turn mechanics

We can have all of these in code (with test), without even being able to play it! without knowing is it a mobile app, a CLI app, multiplayer, over the server, webapp or desktop app. Without knowing if we are storing the chess piece in memory, or in sqlite, or on localstorage in the web.

We do however, have to commit to a programming language. This is the **domain**. We start with the domain because that changes with requirements/business and needs. everything else is details, and we can decide and try/plugin later.

This not to say we don't care or know what database or GUI system we are using, but we should design it such that it doesn't matter.

### UL

Ubiquitous language is an idea that I liked, where we define the langauge we are going to use and give names a special meaning. Names that are generic and thrown around alot gets confusing. What is "staging" (is it pre-prod, or QA or)? What is a "graph"(like node+vertices or charts)? What are "chips" (fries or actual chips)? What is a "user" (our user, or our user's user)?

We should give every important concept a proper noun, and refer to it as such. This eliminate confusion. For example, if we are developing a site-builder, we have 2 layer of users, our direct user who wants to usse our tool to build sites, and the users that uses the actual sites that our tool eventually builds. Using "user" in code or in discussion just confuses everyone. We can make it "ToolUser" and "EndUser".

To take this further, depending on the context, for things like tools, libraries, environments and projects, you might take it even further, you should choose artibrary names that has no baggages. For example, I name my projects over atoms, and my environment over pokemons. The reason for that is project change course and directions, if the name is describing the old project, it will become confusing for users.

UL should be hand-in-hand of the domain design phase, and should go into the lib.

### Bounded Context

This is kind-of like microservice. To think of it as sub-modules with a bunch of classes that work together to achieve the effect, the bounded context is a closed ecosystem, exposing small amount of endpoint to interact with other bounded context. When designing, we can clearly highlight all the different boundaries, and then individually.

For example, in a e-commerce site, we have multi usecases that works together and a big engine. This is a divide-and-conquer solutiuon, where we split the app into smaller apps, and design them as such. For example, we will have BillingContext (containing invoice, payment, subscription etc), Shipping Context (Shipment, address, carriers etc), Inventory Context (product, stocklevel, warehouse etc).

In modern systems, we might just split them into different teams and microservices.

### Entities, Value Objects, and Aggregates

These are tactical building blocks of DDD. The core idea of the separate is great, but the original usage is dated. In the stateless OOP (later), we will see this work correctly with DI and SOLID principles.

There should be two class of "things" in code:

- Objects (or services)
- Structures (or data-types)

The key differences is objects have behaviour and structures are pure data. In stateless OOP, and also in this segment, the key idea is:

- Services should DI other services or configs
- Service methods should only take is structures and return structures

It becomes kind of like a universe, wheere you create all the services at the start, injecting into each other (much like big bang), and on the final service, you kick start the whole engine, which the service will call other service and orchestrate and make the data structure move and dance. The traditional view of this is actually not a good idea, since they bundle state and behaviour into the object, it becomes an unpredictable graph. In stateless OOP (and this sgement), since our class have immutable members and its typically contain other services, it acts more like a tree, where service A will use service B and service C, and so on and so forth, and they don't change, since its determined at the big bang level.

Now for structures, we can have 3 types: Aggregate Roots, Entities and Value Objects. I will change the original definition of it since entities are confusing, and we can map these 3 types to databases. The reason why its confusing is that in data or serialzied layer, there isn't really a "reference" but in OOP languaages, there ARE references, which cause comparison to be complicated.

For this segment, pointers and references are implementation detail, while they ARE identity, we do not treat it as such. Within my projects, i call them slightly differently. AggregateRoots are just the domain itself, Entities are principals and Value Objects are Records. This lands nicely with relational and graph DBs especially. So here it is:

1. Value types (Records) have no identity. They are just data.
2. Entities (Principals) are value types with identity. The uniquely identify a instance
3. Aggregate Root are show relationship. They contain their principals, and other related principals.

Lets map it out here with an example, and why this is good:

given the domain of an Author and his Posts (like facebook post) in the Wall Context, we can have:

```
// Post AggregateRoot
class Post {
	PostPrincipal   Principal
	AuthorPrincipal Author
}

// Post Entity
class PostPrincipal {
	string     Id
	PostRecord Record
}

// Post Value Object
class PostRecord {
	string   Title
	string   Description
	string[] Tag
}

// Author AggregateRoot
class Author {
	AuthorPrincipal Principal
	PostPrincipal[] Posts
}

// Author Entity
class AuthorPrincipal {
	string       Id
	AuthorRecord Record
}

// Author Record
class AuthorRecord {
	string    Name
	Date      DateOfBirth
}
```

When we look at aggregateroot, we are look at a specific group of data, grouped in a certain way, and it includes their relationship with other entities. In this example, when re want to get all the information about the Post (post aggregate root), we give it the post principal (itself) and its author (author principal). This includes data and relationship to multiple data. We can always have more complex aggregate roots, or simpler aggregate roots when build it, it should be tuned to what the service specifically request for.

When we look at Entities (principal), this is the center of the domain. we care mainly about their identity and their related data. Aggregate roots can change based on demands and "views", and entities should hold their group as long as the domain doesn't change. 1 Entity can hold multiple value types (records) if needed, and can have more than just Id as identity (sometimes this includes version etc). This is the basic unit to be orchestrated. Commonly, the different records/value-types are split based on update rate, for example, we have a value object that is "mutable" (as in can change), one that is only on init, and readonly thereafter, or even derived.

When we look at value types, we generally need them to not include identity for various reasons:

- comparison
- Update/creation
- Mapping
  For example, when i want to create a new post, should the create interface require user to provide an ID? it should not! we should then just use the record itself. It also also us to partition the entity into multiple segments and multiple update routes.

Now, we can neatly map this into CRUD apps super well, especially with relational database for optimal performance.

Generally, a CRUD has 5 main functions:

1. Search
2. Create
3. Update
4. Get (one)
5. Delete

Due to how its defined, AggregateRoots are expensive (since we need many joins), and Principals are cheap and usually single-tabled. Value objects are easily passed around, which results in:

1. Search (search params) => Principals[]
   1. since we need alot, we should only return the table itself, and not its joins
2. Create(record) => AggregateRoot
   1. since its only 1 entry, we can afford to return the whole root
   2. users don't know the ID at create time, so they js need give use the value type
3. Update(id, record) => AggregateRoot
   1. since its only 1 entry, we can afford to return the whole root
   2. we need to mentiond the record and the ID to update. since the whole record is replaced, ID should be split out, since ID can't be replaced!
4. Get(id) => AggregateRoot
   1. Since its only 1 entry, we can afford to return the whole root
5. Delete(id) => None
   1. we only need the ID to delete it

Services can generally look like this, and this allows a consistent, highperformance, blessed path for writing highly relational CRUD and even more than CRUD applications. It lands itself very well to relational DB too, since we can map Entities into DBs.

We don't HAVE to do it this way, but for typical CRUD web applications, this makes things neat and nice.

## 3-Layer, N-Layer, Hexagonal

with the principles + domain designed, we need a structured way to present this application into reality. This allow us to architect end-to-end application, extending SOLID principles and DDD.

The core idea of 3-layer/hexagonal achitecture is simple -- the domain is pure, and everything else is a plug-in. In this case, the side-effects/impure parts are generally grouped into 2 segment (layers): inwards and outwards layer.

The inwards layer, also known as controller, api layer etc, are events and instructions call and pass values into the domain ecosystem. They USE the domain (like a library). Its mostly wiring.

The outwards layer, also known as repository, external or data layer, are implementaions of calls that the domain assumed. For example, if the domain needed to save their data, they will have a XRepository. the domain can't actually know how this is done as they will force the domain to know what's the implementation. As such, we can plug in our adapters (say we use SQLite), we can implement a SQLite adapter to make sure it fulfils the XRepository interface. This allows us to fully test the domain (since it has no side effects) and allow us to swap implementation detail (move from CLI app to web app, move from mongodb to mysql db) without breaking the core logic at all.

Typically both layers will have thier own corresponding model for their usecase, and have mappers to translate over the boundary.

```

<--Req/Res model--> API Controller <---mapper
										 |
										 |
										 |
										 V
									 Domain
                                         ^
										 |
										 |
										mapper---> Repo <--Data Model--> DB/API


```

Controller wiull have Req/Res models, as request and resposne might be different and it has different structure than the domain. The domain can have complex types like trees and graphs, but the controller can only use network-friendly models. It also needs to be validated, marked on how the serialization can be done (annotations). The mapper then converts these Req/Res into domain models, for the domain service to consume.

The domain doesn't know about how the data is structure. multiple tables? non-relationalDB? the repository will convert the domain into highly-optimized data structure using a mapper before running it against it the external layer

Together this whole system orchestrates into a a 3-layer system.

# Functional Practices

Its always good to have functional practices. The reason for this most property of functional code reduce complexity by constraining the system.

## Immutability

Immutability eliminates a whole class of bugs. imginae we have a couple of nested functions, A, B and C, that needs to be called in a script, where they can be called in any order:

```
a = A(input)
b = B(a)
c = C(b)
```

the final result, `c` depends on two things, 1 order of A, B, C ( in this case A => B => C), and dependent on WHERE this code is used. this makes the complexity quadratic: order \* WHERE/WHEN (if its used at thet start of the code, middle of the code base or end of code base).

to map it out, the test cases we can have that its behavior is different is:

1. A => B => C (start of script)
2. A => B => C (middle of script)
3. A => B => C (end of script)
4. A => C => B (start of script)
5. A => C => B (middle of script)
6. A => C => B (end of script)
7. B => A => C (start of script)
8. B => A => C (middle of script)
9. B => A => C (end of script)
10. B => C => A (start of script)
11. B => C => A (middle of script)
12. B => C => A (end of script)
13. C => A => B (start of script)
14. C => A => B (middle of script)
15. C => A => B (end of script)
16. C => B => A (start of script)
17. C => B => A (middle of script)
18. C => B => A (end of script)

A total of 18 combination we have to consider. Why does the position of script matter? Because of mutability. If the function A B or C depend on an external mutable variable, say:

```
func A(input) {
	return input * 2 * global
}
```

And since global can change, if we change the position of A, it will drastically change how it performs!

By making it immutable, we reduce from 18 => 6 cases. In reality, the number of possition is way more than 3, in the thousands, which will reduce from 6000 cases => 6 cases, making debuggin simple. we can plug out a script and know that exactly how it performs, with locality, withou needing to know how it perform else where.

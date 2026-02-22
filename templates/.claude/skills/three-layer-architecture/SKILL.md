---
name: three-layer-architecture
description: Three-layer architecture with mappers (Controller → Domain → Repo). Use when designing application architecture, adding new endpoints, or implementing data persistence.
invocation:
  - architecture
  - layers
  - three-layer
  - layer
---

# Three-Layer Architecture

## Quick Reference

```
Controller → Domain → Repository
     ↓            ↓           ↓
    DTO      Domain Model   Data Model
```

- **Controller Layer**: Handle IO from user/client (TUI, CLI, Socket)
- **Domain Layer**: Pure business logic, source of truth, NO IO
- **Repository Layer**: Handle IO to external systems (DB, files, APIs)

## Core Principles

1. **Layer Separation** - Each layer has single responsibility, isolated from others
2. **Layer-Specific Models** - DTO (Controller), Domain Model (Domain), Data Model (Repo)
3. **Mappers Between Layers** - Controller Mapper (DTO ↔ Domain), Repo Mapper (Domain ↔ Data)
4. **Domain is Source of Truth** - Pure, testable, interface-based, no IO

## Language Support

| Language       | Domain Location      | Controllers                 | Repositories                  |
| -------------- | -------------------- | --------------------------- | ----------------------------- |
| TypeScript/Bun | `src/lib/{domain}/`  | `src/adapters/controllers/` | `src/adapters/repos/`         |
| C#/.NET        | `Modules/{feature}/` | `Modules/{feature}/API/`    | `Infrastructure/Persistence/` |
| Go             | `lib/{domain}/`      | `adapters/controllers/`     | `adapters/repos/`             |
| Rust           | `src/{domain}/`      | `adapters/controllers/`     | `adapters/repos/`             |

## Benefits of Mappers

| Benefit            | Without Mappers    | With Mappers            |
| ------------------ | ------------------ | ----------------------- |
| Swap controller    | Break domain tests | Just change DTO mapper  |
| Swap repo          | Break domain tests | Just change data mapper |
| Add new controller | Modify domain      | Add new DTO + mapper    |
| Change DB schema   | Touch all layers   | Only repo mapper        |

## See Also

📖 **Full Documentation**: [three-layer-architecture/](../../../docs/developer/standard/three-layer-architecture/)

Related skills:

- [`/stateless-oop-di`](../stateless-oop-di/) - For testable domain services
- [`/testing`](../testing/) - For testing pure domain logic with mocks

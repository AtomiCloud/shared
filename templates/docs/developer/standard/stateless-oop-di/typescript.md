# Stateless OOP in TypeScript/Bun

## Structures (Data)

```typescript
// Interface for pure data
interface User {
  id: string;
  name: string;
  email: string;
}

// Type alias for domain primitives
type TaskId = string & { readonly __brand: unique symbol };
type TaskName = string & { readonly __brand: unique symbol };

// Factory functions for type safety
const TaskId = {
  fromString: (s: string): TaskId => s as TaskId,
  validate: (s: string): TaskId | null => (s.length > 0 ? (s as TaskId) : null),
};
```

## Objects (Stateless Services)

```typescript
// Service with injected dependencies
class TaskService {
  constructor(
    private readonly repo: ITaskRepository, // readonly = won't reassign
    private readonly logger: ILogger,
  ) {}

  // Stateless method - takes data, returns data
  async create(input: CreateTaskInput): Promise<Task> {
    this.logger.log(`Creating task: ${input.name}`);

    // Pure business logic - no side effects here
    const task: Task = {
      id: TaskId.fromString(crypto.randomUUID()),
      name: input.name,
      status: 'pending',
      createdAt: new Date(),
    };

    // Side effect delegated to dependency
    await this.repo.save(task);
    return task;
  }
}
```

## Immutability Patterns

```typescript
// Spread operator for shallow copy
const updated = { ...user, name: 'Alice' };

// Map instead of forEach with push
const results = items.map(item => transform(item));

// Filter instead of splice
const active = items.filter(item => item.active);

// Reduce instead of manual accumulation
const total = items.reduce((sum, item) => sum + item.value, 0);
```

## Entry Point Wiring

```typescript
// cli.ts
async function main() {
  // Adapters first
  const fs = new FilesystemAdapter();
  const console = new ConsoleAdapter();
  const clock = new ClockAdapter();

  // Services with dependencies
  const configService = new ConfigService(fs);
  const taskService = new TaskService(fs, clock);
  const runService = new RunService(fs, console);

  // Wire into CLI
  const program = new Command()
    .command('init', createInitCommand(configService))
    .command('run', createRunCommand(taskService, runService));

  await program.parseAsync();
}
```

## Folder Structure

```
src/
├── lib/                    # Pure domain code
│   ├── task/
│   │   ├── models.ts       # Task, TaskStatus types
│   │   ├── interfaces.ts   # ITaskRepository
│   │   └── service.ts      # TaskService
│   └── index.ts            # Re-exports
└── adapters/               # Impure code
    ├── filesystem.adapter.ts
    └── console.adapter.ts
```

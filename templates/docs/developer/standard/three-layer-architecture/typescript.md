# Three-Layer Architecture in TypeScript/Bun

## Directory Structure

```
src/
├── lib/                          # Domain (pure)
│   ├── task/
│   │   ├── models.ts             # Task, TaskStatus
│   │   ├── interfaces.ts         # ITaskRepository
│   │   ├── service.ts            # TaskService
│   │   └── mappers/
│   │       ├── controller.mapper.ts  # DTO ↔ Domain
│   │       └── repo.mapper.ts        # Domain ↔ Data
│   └── shared/
│       └── types.ts              # Result<T,E>
│
├── adapters/                     # Adapters (impure)
│   ├── controllers/
│   │   ├── tui/
│   │   │   └── task.tui.ts
│   │   ├── cli/
│   │   │   └── task.cli.ts
│   │   └── socket/
│   │       └── task.socket.ts
│   └── repos/
│       ├── file/
│       │   └── task.file-repo.ts
│       └── memory/
│           └── task.memory-repo.ts
│
└── cli.ts                        # Entry point
```

## Layer Models

```typescript
// ===== CONTROLLER DTO =====
interface CreateTaskDto {
  name: string;
  priority?: 'low' | 'medium' | 'high';
}

// ===== DOMAIN MODEL =====
class Task {
  constructor(
    public id: TaskId,
    public name: TaskName,
    public priority: Priority,
    public status: TaskStatus,
    public createdAt: Date,
  ) {}

  start(): Result<void, Error> {
    if (this.status !== TaskStatus.Pending) {
      return err(new Error('Cannot start non-pending task'));
    }
    this.status = TaskStatus.Running;
    return ok(undefined);
  }
}

// ===== DATA MODEL =====
interface TaskRecord {
  id: string;
  name: string;
  priority: number;
  status: string;
  created_at: number;
  updated_at: number;
}
```

## Mappers

```typescript
// lib/task/mappers/controller.mapper.ts
export class TaskControllerMapper {
  toDto(task: Task): TaskResponseDto {
    return {
      id: task.id.value,
      name: task.name.value,
      priority: task.priority.toString(),
      createdAt: task.createdAt.toISOString(),
    };
  }

  toDomain(dto: CreateTaskDto): CreateTaskInput {
    return {
      name: TaskName.create(dto.name),
      priority: dto.priority ? Priority.fromString(dto.priority) : Priority.DEFAULT,
    };
  }
}

// lib/task/mappers/repo.mapper.ts
export class TaskRepoMapper {
  toData(task: Task): TaskRecord {
    return {
      id: task.id.value,
      name: task.name.value,
      priority: task.priority.toNumber(),
      status: task.status.value,
      created_at: task.createdAt.getTime(),
      updated_at: Date.now(),
    };
  }

  toDomain(record: TaskRecord): Task {
    return new Task(
      TaskId.fromString(record.id),
      TaskName.create(record.name),
      Priority.fromNumber(record.priority),
      TaskStatus.fromString(record.status),
      new Date(record.created_at),
    );
  }
}
```

## Entry Point

```typescript
// cli.ts
async function main() {
  const fs = new FilesystemAdapter();
  const controllerMapper = new TaskControllerMapper();
  const repoMapper = new TaskRepoMapper();

  const taskRepo = new TaskFileRepo(fs, repoMapper, './data/tasks.json');
  const taskService = new TaskService(taskRepo);

  const tuiController = new TaskTuiController(taskService, controllerMapper);
  const cliController = new TaskCliController(taskService, controllerMapper);

  // Route based on mode
  if (process.argv.includes('--tui')) {
    await tuiController.run();
  } else {
    await cliController.run(parseArgs());
  }
}
```

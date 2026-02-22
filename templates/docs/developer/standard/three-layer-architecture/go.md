# Three-Layer Architecture in Go

## Directory Structure

```
lib/
├── task/                         # Domain
│   ├── models.go                 # Task, TaskStatus structs
│   ├── interfaces.go             # TaskRepository interface
│   ├── service.go                # TaskService
│   └── mappers/
│       ├── controller_mapper.go  # DTO ↔ Domain
│       └── repo_mapper.go        # Domain ↔ Data
├── shared/                       # Shared types
│   └── types.go
│
adapters/                         # Adapters
├── controllers/
│   ├── tui/
│   │   └── task_tui.go
│   └── cli/
│       └── task_cli.go
│
└── repos/                        # Repositories
    ├── file/
    │   └── task_file_repo.go
    └── memory/
        └── task_memory_repo.go

main.go                           # Entry point
```

## Layer Models

```go
// ===== CONTROLLER DTO =====
type CreateTaskDto struct {
    Name     string  `json:"name"`
    Priority *string `json:"priority,omitempty"`
}

type TaskResponseDto struct {
    ID        string `json:"id"`
    Name      string `json:"name"`
    Priority  string `json:"priority"`
    CreatedAt string `json:"createdAt"`
}

// ===== DOMAIN MODEL =====
type Task struct {
    ID        TaskId
    Name      TaskName
    Priority  Priority
    Status    TaskStatus
    CreatedAt time.Time
}

func (t *Task) Start() error {
    if t.Status != TaskStatusPending {
        return errors.New("cannot start non-pending task")
    }
    t.Status = TaskStatusRunning
    return nil
}

// ===== DATA MODEL =====
type TaskRecord struct {
    ID        string `json:"id"`
    Name      string `json:"name"`
    Priority  int    `json:"priority"`
    Status    string `json:"status"`
    CreatedAt int64  `json:"created_at"`
    UpdatedAt int64  `json:"updated_at"`
}
```

## Mappers

```go
// lib/task/mappers/controller_mapper.go
type TaskControllerMapper struct{}

func (m *TaskControllerMapper) ToDto(task Task) TaskResponseDto {
    return TaskResponseDto{
        ID:        task.ID.Value,
        Name:      task.Name.Value,
        Priority:  task.Priority.String(),
        CreatedAt: task.CreatedAt.Format(time.RFC3339),
    }
}

func (m *TaskControllerMapper) ToDomain(dto CreateTaskDto) CreateTaskInput {
    priority := PriorityDefault
    if dto.Priority != nil {
        priority = PriorityFromString(*dto.Priority)
    }
    return CreateTaskInput{
        Name:     TaskNameCreate(dto.Name),
        Priority: priority,
    }
}

// lib/task/mappers/repo_mapper.go
type TaskRepoMapper struct{}

func (m *TaskRepoMapper) ToData(task Task) TaskRecord {
    return TaskRecord{
        ID:        task.ID.Value,
        Name:      task.Name.Value,
        Priority:  task.Priority.ToNumber(),
        Status:    task.Status.String(),
        CreatedAt: task.CreatedAt.Unix(),
        UpdatedAt: time.Now().Unix(),
    }
}

func (m *TaskRepoMapper) ToDomain(record TaskRecord) (Task, error) {
    return Task{
        ID:        TaskIdFromString(record.ID),
        Name:      TaskNameCreate(record.Name),
        Priority:  PriorityFromNumber(record.Priority),
        Status:    TaskStatusFromString(record.Status),
        CreatedAt: time.Unix(record.CreatedAt, 0),
    }, nil
}
```

## Entry Point

```go
// main.go
func main() {
    // Create adapters
    fs := filesystem.New()
    logger := log.New(os.Stdout, "", 0)

    // Create mappers
    controllerMapper := mappers.NewTaskControllerMapper()
    repoMapper := mappers.NewTaskRepoMapper()

    // Create repositories
    taskRepo := repos.NewTaskFileRepo(fs, repoMapper, "./data/tasks.json")

    // Create services
    taskService := service.NewTaskService(taskRepo)

    // Create controllers
    tuiController := controllers.NewTaskTuiController(taskService, controllerMapper, logger)
    cliController := controllers.NewTaskCliController(taskService, controllerMapper)

    // Route based on flags
    if *tuiFlag {
        tuiController.Run()
    } else {
        cliController.Run(os.Args)
    }
}
```

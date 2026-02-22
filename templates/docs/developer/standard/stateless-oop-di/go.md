# Stateless OOP in Go

## Structures (Data)

```go
// Struct for pure data
type User struct {
    ID    string
    Name  string
    Email string
}

// Domain primitives with validation
type TaskId struct {
    value string
}

func TaskIdFromString(s string) (TaskId, error) {
    if s == "" {
        return TaskId{}, errors.New("empty task id")
    }
    return TaskId{value: s}, nil
}

func (t TaskId) String() string {
    return t.value
}
```

## Objects (Stateless Services)

```go
// Service with injected dependencies
type TaskService struct {
    repo   ITaskRepository
    logger Logger
}

// Constructor injection
func NewTaskService(repo ITaskRepository, logger Logger) *TaskService {
    return &TaskService{
        repo:   repo,
        logger: logger,
    }
}

// Stateless method - receiver doesn't modify struct
func (s *TaskService) Create(ctx context.Context, input CreateTaskInput) (Task, error) {
    s.logger.Log("Creating task: " + input.Name)

    task := Task{
        ID:        uuid.New().String(),
        Name:      input.Name,
        Status:    "pending",
        CreatedAt: time.Now(),
    }

    if err := s.repo.Save(ctx, task); err != nil {
        return Task{}, err
    }

    return task, nil
}
```

## Immutability Patterns

```go
// Return new struct instead of modifying
func UpdateName(u User, name string) User {
    return User{
        ID:    u.ID,
        Name:  name,
        Email: u.Email,
    }
}

// Functional patterns with slices
results := transformSlice(items, transform)
active := filterSlice(items, func(i Item) bool { return i.Active })

// Helper functions
func transformSlice[T, U any](s []T, f func(T) U) []U {
    result := make([]U, len(s))
    for i, v := range s {
        result[i] = f(v)
    }
    return result
}
```

## Entry Point Wiring

```go
// main.go
func main() {
    // Create adapters
    fs := NewFilesystemAdapter()
    logger := NewLogger()

    // Create services with dependencies
    configService := NewConfigService(fs)
    taskService := NewTaskService(fs, logger)

    // Wire into CLI app
    app := cli.NewApp()
    app.Commands = []*cli.Command{
        createInitCommand(configService),
        createRunCommand(taskService),
    }

    app.Run(os.Args)
}
```

## Folder Structure

```
lib/
├── task/                  # Domain
│   ├── models.go          # Task, TaskStatus structs
│   ├── interfaces.go      # TaskRepository interface
│   └── service.go         # TaskService
├── user/
│   └── ...
└── shared/                # Shared types
    └── types.go

adapters/                  # Infrastructure
├── filesystem/
└── logger/
```

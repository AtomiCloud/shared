# Three-Layer Architecture in C#/.NET

## Directory Structure

```
src/
├── Modules/                       # Feature modules
│   ├── Tasks/
│   │   ├── Models/                # Domain models
│   │   │   └── Task.cs
│   │   ├── Interfaces/            # Contracts
│   │   │   └── ITaskRepository.cs
│   │   ├── Services/              # Business logic
│   │   │   └── TaskService.cs
│   │   ├── Mappers/               # Mappers
│   │   │   ├── TaskControllerMapper.cs
│   │   │   └── TaskRepoMapper.cs
│   │   └── API/                   # Controllers
│   │       ├── Controllers/
│   │       │   └── TaskController.cs
│   │       └── DTOs/
│   │           ├── CreateTaskDto.cs
│   │           └── TaskResponseDto.cs
│
├── Domain/                        # Shared domain
│   └── Shared/
│       └── Types.cs
│
└── Infrastructure/                # Repositories
    ├── Persistence/
    │   ├── File/
    │   │   └── TaskFileRepository.cs
    │   └── SqlServer/
    │       └── TaskSqlRepository.cs
    └── DTOs/                       # Data models
        └── TaskRecord.cs
```

## Layer Models

```csharp
// ===== CONTROLLER DTO =====
public record CreateTaskDto(string Name, string? Priority);
public record TaskResponseDto(string Id, string Name, string Priority, string CreatedAt);

// ===== DOMAIN MODEL =====
public record Task(TaskId Id, TaskName Name, Priority Priority, TaskStatus Status, DateTime CreatedAt)
{
    public Result<Task, Error> Start()
    {
        if (Status != TaskStatus.Pending)
            return Result.Failure<Task, Error>(new Error("Cannot start non-pending task"));

        return this with { Status = TaskStatus.Running };
    }
}

// ===== DATA MODEL =====
public record TaskRecord(string Id, string Name, int Priority, string Status, long CreatedAt, long UpdatedAt);
```

## Mappers

```csharp
// Modules/Tasks/Mappers/TaskControllerMapper.cs
public class TaskControllerMapper
{
    public TaskResponseDto ToDto(Task task) =>
        new()
        {
            Id = task.Id.Value,
            Name = task.Name.Value,
            Priority = task.Priority.ToString(),
            CreatedAt = task.CreatedAt.ToString("O")
        };

    public CreateTaskInput ToDomain(CreateTaskDto dto) =>
        new()
        {
            Name = TaskName.Create(dto.Name),
            Priority = dto.Priority is not null
                ? Priority.FromString(dto.Priority)
                : Priority.Default
        };
}

// Modules/Tasks/Mappers/TaskRepoMapper.cs
public class TaskRepoMapper
{
    public TaskRecord ToData(Task task) =>
        new()
        {
            Id = task.Id.Value,
            Name = task.Name.Value,
            Priority = task.Priority.ToNumber(),
            Status = task.Status.Value,
            CreatedAt = task.CreatedAt.Ticks,
            UpdatedAt = DateTime.UtcNow.Ticks
        };

    public Task ToDomain(TaskRecord record) =>
        new()
        {
            Id = TaskId.FromString(record.Id),
            Name = TaskName.Create(record.Name),
            Priority = Priority.FromNumber(record.Priority),
            Status = TaskStatus.FromString(record.Status),
            CreatedAt = new DateTime(record.CreatedAt, DateTimeKind.Utc)
        };
}
```

## Entry Point (ASP.NET Core DI)

```csharp
// Program.cs
var builder = Host.CreateApplicationBuilder(args);

// Register options
builder.Services.Configure<DatabaseOptions>(
    builder.Configuration.GetSection("Database"));

// Register adapters
builder.Services.AddSingleton<IFilesystemAdapter, FilesystemAdapter>();

// Register mappers
builder.Services.AddSingleton<TaskControllerMapper>();
builder.Services.AddSingleton<TaskRepoMapper>();

// Register repositories
builder.Services.AddSingleton<ITaskRepository, TaskFileRepository>();

// Register services
builder.Services.AddScoped<TaskService>();

// Register controllers
builder.Services.AddControllers();

var host = builder.Build();
await host.RunAsync();
```

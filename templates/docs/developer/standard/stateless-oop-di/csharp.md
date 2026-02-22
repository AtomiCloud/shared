# Stateless OOP in C#/.NET

## Structures (Data)

```csharp
// Record for immutable data (C# 9+)
public record User(string Id, string Name, string Email);

// Domain primitives with wrapper types
public readonly record struct TaskId(string Value)
{
    public static TaskId FromString(string s) => new(s);
}

public readonly record struct TaskName(string Value)
{
    public static TaskName Create(string s) => new(s);
}
```

## Objects (Stateless Services)

Use **primary constructors** (C# 12+) for concise DI syntax:

```csharp
// ✅ MODERN - Primary constructor (C# 12)
public class TaskService(ITaskRepository repo, ILogger logger)
{
    public async Task<Task> CreateAsync(CreateTaskInput input)
    {
        logger.LogInfo($"Creating task: {input.Name}");

        var task = new Task
        {
            Id = TaskId.FromString(Guid.NewGuid().ToString()),
            Name = input.Name,
            Status = TaskStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };

        await repo.SaveAsync(task);
        return task;
    }
}

// ❌ OLD - Verbose constructor
public class TaskService
{
    private readonly ITaskRepository _repo;
    private readonly ILogger _logger;

    public TaskService(ITaskRepository repo, ILogger logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Task> CreateAsync(CreateTaskInput input)
    {
        _logger.LogInfo($"Creating task: {input.Name}");
        // ...
    }
}
```

## No Static or Global

```csharp
// ❌ BAD - Static class
public static class UserService
{
    public static async Task<User> GetUserAsync(string id)
    {
        // Hidden dependency - can't test, can't swap
        return await DbContext.Users.FindAsync(id);
    }
}

// ✅ GOOD - Instance with DI
public class UserService(IUserRepository repo)
{
    public async Task<User> GetUserAsync(string id)
    {
        return await repo.FindAsync(id);
    }
}
```

## Immutability Patterns

```csharp
// Records with 'with' expression for immutable updates
var updated = user with { Name = "Alice" };

// LINQ for functional transformations
var results = items.Select(item => Transform(item)).ToList();
var active = items.Where(item => item.Active).ToList();
var total = items.Sum(item => item.Value);

// Expression-bodied methods for single-line logic
public int CalculateTotal(Order order) =>
    order.Items.Sum(item => item.Price * item.Quantity);
```

## Entry Point Wiring (ASP.NET Core DI)

```csharp
// Program.cs
var builder = Host.CreateApplicationBuilder(args);

// Register adapters (singleton)
builder.Services.AddSingleton<IFileSystemAdapter, FileSystemAdapter>();
builder.Services.AddSingleton<ILogger, ConsoleLogger>();

// Register services (scoped)
builder.Services.AddScoped<ITaskRepository, TaskRepository>();
builder.Services.AddScoped<TaskService>();

var host = builder.Build();
await host.RunAsync();
```

## Folder Structure

```
src/
├── Modules/               # Feature modules
│   ├── Tasks/
│   │   ├── Models/        # User, Task records
│   │   ├── Interfaces/    # ITaskRepository
│   │   └── Services/      # TaskService
│   └── Users/
├── Domain/                # Shared domain
│   └── Shared/
└── Infrastructure/        # Adapters
    ├── Persistence/
    └── Logging/
```

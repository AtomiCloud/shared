# Three-Layer Architecture in Rust

## Directory Structure

```
src/
├── task/                         # Domain
│   ├── models.rs                 # Task, TaskStatus structs
│   ├── traits.rs                 # TaskRepository trait
│   ├── service.rs                # TaskService
│   └── mappers/
│       ├── controller_mapper.rs  # DTO ↔ Domain
│       └── repo_mapper.rs        # Domain ↔ Data
├── shared/                       # Shared types
│   └── types.rs
│
adapters/                         # Adapters
├── controllers/
│   ├── tui/
│   │   └── task_tui.rs
│   └── cli/
│       └── task_cli.rs
│
└── repos/                        # Repositories
    ├── file/
    │   └── task_file_repo.rs
    └── memory/
        └── task_memory_repo.rs

main.rs                           # Entry point
```

## Layer Models

```rust
// ===== CONTROLLER DTO =====
#[derive(Deserialize)]
pub struct CreateTaskDto {
    pub name: String,
    pub priority: Option<String>,
}

#[derive(Serialize)]
pub struct TaskResponseDto {
    pub id: String,
    pub name: String,
    pub priority: String,
    pub created_at: String,
}

// ===== DOMAIN MODEL =====
#[derive(Clone, Debug)]
pub struct Task {
    pub id: TaskId,
    pub name: TaskName,
    pub priority: Priority,
    pub status: TaskStatus,
    pub created_at: DateTime<Utc>,
}

impl Task {
    pub fn start(&mut self) -> Result<(), Error> {
        if self.status != TaskStatus::Pending {
            return Err(Error::InvalidTransition);
        }
        self.status = TaskStatus::Running;
        Ok(())
    }
}

// ===== DATA MODEL =====
#[derive(Deserialize, Serialize)]
pub struct TaskRecord {
    pub id: String,
    pub name: String,
    pub priority: i32,
    pub status: String,
    pub created_at: i64,
    pub updated_at: i64,
}
```

## Mappers

```rust
// src/task/mappers/controller_mapper.rs
pub struct TaskControllerMapper;

impl TaskControllerMapper {
    pub fn toDto(task: &Task) -> TaskResponseDto {
        TaskResponseDto {
            id: task.id.value().clone(),
            name: task.name.value().clone(),
            priority: task.priority.to_string(),
            created_at: task.created_at.to_rfc3339(),
        }
    }

    pub fn toDomain(dto: CreateTaskDto) -> CreateTaskInput {
        let priority = dto.priority
            .map(|p| Priority::from_string(p))
            .unwrap_or_default();
        CreateTaskInput {
            name: TaskName::new(dto.name),
            priority,
        }
    }
}

// src/task/mappers/repo_mapper.rs
pub struct TaskRepoMapper;

impl TaskRepoMapper {
    pub fn toData(task: &Task) -> TaskRecord {
        TaskRecord {
            id: task.id.value().clone(),
            name: task.name.value().clone(),
            priority: task.priority.to_number(),
            status: task.status.to_string(),
            created_at: task.created_at.timestamp(),
            updated_at: Utc::now().timestamp(),
        }
    }

    pub fn toDomain(record: TaskRecord) -> Result<Task, Error> {
        Ok(Task {
            id: TaskId::new(record.id)?,
            name: TaskName::new(record.name)?,
            priority: Priority::from_number(record.priority)?,
            status: TaskStatus::new(record.status)?,
            created_at: DateTime::from_timestamp(record.created_at, 0)
                .unwrap()
                .with_timezone(&Utc),
        })
    }
}
```

## Entry Point

```rust
// main.rs
#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    // Create adapters
    let fs = adapters::FilesystemAdapter::new();
    let logger = adapters::LoggerAdapter::new();

    // Create mappers
    let controller_mapper = mappers::TaskControllerMapper;
    let repo_mapper = mappers::TaskRepoMapper;

    // Create repositories
    let task_repo = repos::TaskFileRepo::new(fs.clone(), repo_mapper, "./data/tasks.json")?;

    // Create services
    let task_service = service::TaskService::new(task_repo);

    // Create controllers
    let tui_controller = controllers::TaskTuiController::new(
        task_service.clone(),
        controller_mapper,
        logger,
    );

    // Run based on flags
    if std::env::args().any(|a| a == "--tui") {
        tui_controller.run().await?;
    } else {
        // CLI controller...
    }

    Ok(())
}
```

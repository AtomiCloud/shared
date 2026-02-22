# Stateless OOP in Rust

## Structures (Data)

```rust
// Struct for pure data
#[derive(Clone, Debug)]
pub struct User {
    pub id: String,
    pub name: String,
    pub email: String,
}

// Domain primitives with validation
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct TaskId(String);

impl TaskId {
    pub fn new(s: String) -> Result<Self, Error> {
        if s.is_empty() {
            return Err(Error::InvalidTaskId);
        }
        Ok(TaskId(s))
    }

    pub fn value(&self) -> &str {
        &self.0
    }
}
```

## Objects (Stateless Services)

```rust
// Service with injected dependencies (via trait)
pub struct TaskService<R: TaskRepository, L: Logger> {
    repo: R,
    logger: L,
}

// Constructor
impl<R: TaskRepository, L: Logger> TaskService<R, L> {
    pub fn new(repo: R, logger: L) -> Self {
        Self { repo, logger }
    }

    // Stateless method - self is immutable reference
    pub fn create(&self, input: CreateTaskInput) -> Result<Task, Error> {
        self.logger.log(&format!("Creating task: {}", input.name));

        let task = Task {
            id: TaskId::new(uuid::Uuid::new_v4().to_string())?,
            name: input.name,
            status: TaskStatus::Pending,
            created_at: Utc::now(),
        };

        self.repo.save(task.clone())?;
        Ok(task)
    }
}
```

## Immutability (Enforced by Type System)

```rust
// &self = immutable receiver, can't modify struct
impl User {
    pub fn update_name(&self, name: String) -> User {
        // Return NEW instance instead of modifying
        User {
            id: self.id.clone(),
            name,
            email: self.email.clone(),
        }
    }
}

// Iterators for functional patterns
let results: Vec<_> = items.iter().map(transform).collect();
let active: Vec<_> = items.iter().filter(|i| i.active).collect();
let total: i32 = items.iter().map(|i| i.value).sum();
```

## Entry Point Wiring

```rust
// main.rs
#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    // Create adapters
    let fs = FilesystemAdapter::new();
    let logger = LoggerAdapter::new();

    // Create services with dependencies
    let config_service = ConfigService::new(fs.clone());
    let task_service = TaskService::new(fs.clone(), logger.clone());

    // Wire into CLI
    let mut app = Command::new("myapp")
        .subcommand(create_init_command(config_service))
        .subcommand(create_run_command(task_service));

    app.clone().try_get_matches_from_mut(std::env::args())?;

    Ok(())
}
```

## Folder Structure

```
src/
├── task/                  # Domain
│   ├── models.rs         # Task, TaskStatus structs
│   ├── traits.rs         # TaskRepository trait
│   └── service.rs        # TaskService
├── user/
│   └── ...
└── shared/               # Shared types
    └── types.rs
    └── error.rs

adapters/                 # Infrastructure
├── filesystem.rs
└── logger.rs
```

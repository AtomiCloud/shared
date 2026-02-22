# Testing in Rust

## Framework: Built-in

No external dependencies needed. Rust has built-in testing support.

## AAA Template

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_something() {
        // Arrange
        let subject = Service::new(mock_dep);
        let input = Input { value: 42 };
        let expected = Output { result: 84 };

        // Act
        let actual = subject.method(input);

        // Assert
        assert_eq!(expected, actual);
    }
}
```

## Assertions (Built-in)

```rust
// Equality
assert_eq!(expected, actual);
assert_eq!(expected, actual, "custom message");

// Not equal
assert_ne!(unexpected, actual);

// Boolean
assert!(result);
assert!(!result);

// Pattern matching
assert!(matches!(actual, Some(_)));

// Panic on fail
assert_never!(actual);

// Custom with message
assert_eq!(expected, actual, "{:?} != {:?}", expected, actual);
```

## Spies

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::{Arc, Mutex};

    #[test]
    fn test_logging() {
        // Arrange - spy that collects calls
        let logs = Arc::new(Mutex::new(Vec::new()));
        let spy_logger = SpyLogger::new(logs.clone());

        let subject = Service::new(spy_logger);

        // Act
        subject.do_something();

        // Assert - verify collected calls
        let logs = logs.lock().unwrap();
        assert_eq!(vec!["expected message"], *logs);
    }

    struct SpyLogger {
        logs: Arc<Mutex<Vec<String>>>,
    }

    impl SpyLogger {
        fn new(logs: Arc<Mutex<Vec<String>>>) -> Self {
            Self { logs }
        }
    }

    impl Logger for SpyLogger {
        fn log(&self, message: &str) {
            self.logs.lock().unwrap().push(message.to_string());
        }
    }
}
```

## Parameterized Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;

    // Each case is a separate test function
    #[test]
    fn test_format_status_pending() {
        test_format_status("pending", "Pending");
    }

    #[test]
    fn test_format_status_running() {
        test_format_status("running", "Running");
    }

    #[test]
    fn test_format_status_completed() {
        test_format_status("completed", "Completed");
    }

    // Helper function
    fn test_format_status(input: &str, expected: &str) {
        let subject = StatusFormatter::new();
        let actual = subject.format(input);
        assert_eq!(expected, actual);
    }
}
```

## Run Tests

```bash
cargo test
cargo test --test_service_something
cargo test -- --nocapture  # show println output
```
